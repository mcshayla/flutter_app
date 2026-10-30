// /vendor.html: the vendor side of the website. Log in, claim or create a
// listing, see the dashboard, and edit the listing with photos. Uses the
// same tables, storage bucket and rules as the app's vendor screens.
// Vendor payment is off in the app (vendor_config.dart), so there is no
// subscription step here either.

import { getClient, currentUser, openAuthDialog, signOut, paintAccountLinks, handleAccountClick } from './auth.js';
import {
  renderDashboard, renderStart, renderClaimResults, claimListing, renderListingForm, readListingForm, vendorPayload, filterGroups, storageFolder,
} from './vendor-logic.js';
import { openDialog, toast, field, showError } from './dialog.js';
import { esc } from './plan-view.js';
import { wirePin } from './vendor-pin-map.js';

const main = document.getElementById('content');
const db = () => getClient();
// claiming: true while the one-time code briefly swaps the login, so the
// auth listener doesn't redraw the page for the business email's session.
const state = { user: null, vendor: null, catalog: null, index: null, removed: new Set(), newFiles: [], claiming: false };

async function run(query) {
  const { data, error } = await query;
  if (error) throw new Error(error.message);
  return data;
}

async function loadCatalog() {
  if (state.catalog) return state.catalog;
  const [categories, filters, options] = await Promise.all([
    run(db().from('categories').select('name').order('display_order', { ascending: true })),
    run(db().from('category_filters').select('*')),
    run(db().from('filter_options').select('*')),
  ]);
  state.catalog = { categories: categories.map(c => c.name.trim()), filters, options };
  return state.catalog;
}

async function pageUrlFor(id) {
  try {
    state.index ??= await (await fetch('/vendors/index.json')).json();
    return state.index.vendors[id]?.url ?? null;
  } catch { return null; }
}

// ---------------------------------------------------------------- screens

async function show() {
  paintAccountLinks(state.user);
  if (!state.user) return showLoggedOut();
  const profile = await run(db().from('vendor_profiles').select('vendor_id').eq('user_id', state.user.id).maybeSingle());
  if (!profile) { state.vendor = null; main.innerHTML = renderStart(); return; }
  state.vendor = await run(db().from('vendors').select('*').eq('vendor_id', profile.vendor_id).single());
  return showDashboard();
}

function showLoggedOut() {
  main.innerHTML = `<section class="intro intro-tight"><div class="intro-inner">
      <span class="eyebrow">For wedding vendors</span>
      <h1>Your <em>vendor</em> dashboard</h1>
      <p>Manage your listing, add photos, and see how many couples view, love and say YES to you.</p>
      <div class="account-cta">
        <button type="button" class="btn btn-plum" data-action="log-in">Log in</button>
        <button type="button" class="btn btn-line" data-action="sign-up">Create a vendor account</button>
      </div>
      <p class="muted">New here? <a href="/vendorRegistration">See how listing on easiYESt works</a>.</p>
    </div></section>`;
}

async function showDashboard() {
  const v = state.vendor;
  const [clicks, hearts, yes] = await Promise.all([
    run(db().from('vendor_clicks').select('clicks_on_card, clicks_on_links').eq('vendor_id', v.vendor_id).maybeSingle()).catch(() => null),
    run(db().from('users_loved').select('loved_vendor_id').eq('loved_vendor_id', v.vendor_id).eq('hearted', true)).catch(() => []),
    run(db().rpc('count_diamonds', { vendor: v.vendor_id })).catch(() => 0),
  ]);
  const { filters } = await loadCatalog();
  main.innerHTML = renderDashboard({
    vendor: v,
    stats: { views: clicks?.clicks_on_card, websiteClicks: clicks?.clicks_on_links, hearts: hearts?.length, yes, booked: v.bookings_count },
    pageUrl: await pageUrlFor(v.vendor_id),
    filterCount: filters.filter(f => String(f.category_name).trim() === String(v.vendor_category).trim() && f.filter_type !== 'range').length,
  }) + `<p class="vendor-foot"><button type="button" class="text-btn" data-action="log-out">Log out</button></p>`;
}

async function showForm(isNew) {
  const { categories, filters, options } = await loadCatalog();
  const v = isNew ? {} : state.vendor;
  state.removed = new Set();
  state.newFiles = [];
  const groups = filterGroups(v.vendor_category ?? '', filters, options);
  main.innerHTML = `<section class="intro intro-tight"><div class="intro-inner">
      <span class="eyebrow">${isNew ? 'New listing' : 'Edit listing'}</span>
      <h1>${isNew ? 'Create your <em>listing</em>' : esc(v.vendor_name)}</h1>
    </div></section><div class="vform-wrap">${renderListingForm({ vendor: v, categories, groups, isNew })}</div>`;
  const form = main.querySelector('form');
  // The filters depend on the vendor type, so redraw them when it changes.
  form.querySelector('[name=vendor_category]')?.addEventListener('change', e => {
    const kept = readListingForm(new FormData(form));
    const html = renderListingForm({ vendor: { ...vendorPayload(kept), vendor_category: e.target.value }, categories, groups: filterGroups(e.target.value, filters, options), isNew });
    const tmp = document.createElement('div');
    tmp.innerHTML = html;
    const oldFilters = [...form.querySelectorAll('.form-section')].find(s => s.querySelector('h2')?.textContent === 'Search filters');
    const newFilters = [...tmp.querySelectorAll('.form-section')].find(s => s.querySelector('h2')?.textContent === 'Search filters');
    if (oldFilters) oldFilters.remove();
    if (newFilters) form.querySelectorAll('.form-section')[2].after(newFilters);
  });
  form.querySelector('[name=photos]').addEventListener('change', e => {
    state.newFiles.push(...e.target.files);
    e.target.value = '';
    paintNewPhotos();
  });
  form.addEventListener('submit', e => { e.preventDefault(); saveListing(form, isNew); });
  wirePin(form, v);
  window.scrollTo(0, 0);
}

function paintNewPhotos() {
  const ul = document.getElementById('new-photos');
  ul.innerHTML = state.newFiles.map((f, i) => `<li><img src="${URL.createObjectURL(f)}" alt="New photo ${i + 1}"><button type="button" class="photo-remove" data-remove-new="${i}" aria-label="Remove new photo ${i + 1}">&times;</button></li>`).join('');
}

// ---------------------------------------------------------------- saving

/** JPEG, at most 1200px on the long side, 75% quality: the app's compressForUpload. */
async function compress(file) {
  const bitmap = await createImageBitmap(file);
  const scale = Math.min(1, 1200 / Math.max(bitmap.width, bitmap.height));
  const canvas = document.createElement('canvas');
  canvas.width = Math.round(bitmap.width * scale);
  canvas.height = Math.round(bitmap.height * scale);
  canvas.getContext('2d').drawImage(bitmap, 0, 0, canvas.width, canvas.height);
  return new Promise(resolve => canvas.toBlob(resolve, 'image/jpeg', 0.75));
}

async function uploadPhotos(vendorName) {
  const urls = [];
  let failed = 0;
  for (let i = 0; i < state.newFiles.length; i++) {
    const path = `${storageFolder(vendorName)}/${Date.now()}_${i}.jpg`;
    try {
      const blob = await compress(state.newFiles[i]);
      const { error } = await db().storage.from('vendor-photos').upload(path, blob, { contentType: 'image/jpeg' });
      if (error) throw error;
      urls.push(db().storage.from('vendor-photos').getPublicUrl(path).data.publicUrl);
    } catch (err) {
      console.error(err);
      failed++;
    }
  }
  return { urls, failed };
}

async function removeStoredPhotos(urls) {
  const paths = urls.map(u => decodeURIComponent(new URL(u).pathname.split('/vendor-photos/')[1] ?? '')).filter(Boolean);
  if (paths.length) await db().storage.from('vendor-photos').remove(paths).catch(() => {});
}

async function saveListing(form, isNew) {
  if (!form.reportValidity()) return;
  const btn = form.querySelector('[type=submit]');
  btn.disabled = true;
  showError(form, '');
  try {
    const payload = vendorPayload(readListingForm(new FormData(form)));
    if (!payload.vendor_name) throw new Error('Add your business name.');
    let vendorId;
    if (isNew) {
      if (!payload.vendor_category) throw new Error('Choose what you offer.');
      const row = await run(db().from('vendors').insert({ ...payload, vendor_user_id: state.user.id, is_claimed: true, claimed_at: new Date().toISOString() }).select().single());
      vendorId = row.vendor_id;
      await run(db().from('vendor_profiles').insert({ user_id: state.user.id, vendor_id: vendorId, business_name: payload.vendor_name }));
    } else {
      vendorId = state.vendor.vendor_id;
      delete payload.vendor_category;
    }
    // Photos upload after the row exists, because storage checks the folder against the vendor's name.
    const kept = (isNew ? [] : state.vendor.image_url ?? []).filter((_, i) => !state.removed.has(i));
    const removed = (isNew ? [] : state.vendor.image_url ?? []).filter((_, i) => state.removed.has(i));
    if (!isNew) await run(db().from('vendors').update(payload).eq('vendor_id', vendorId));
    const { urls, failed } = await uploadPhotos(payload.vendor_name);
    await run(db().from('vendors').update({ image_url: [...kept, ...urls] }).eq('vendor_id', vendorId));
    await removeStoredPhotos(removed);
    state.vendor = await run(db().from('vendors').select('*').eq('vendor_id', vendorId).single());
    await showDashboard();
    window.scrollTo(0, 0);
    toast(failed ? `Saved, but ${failed} photo${failed === 1 ? '' : 's'} didn't upload. Try adding ${failed === 1 ? 'it' : 'them'} again.` : (isNew ? 'Your listing is created. We\'ll review it before it goes live.' : 'Your listing is saved.'));
  } catch (err) {
    showError(form, err.message || 'Something went wrong. Please try again.');
    btn.disabled = false;
  }
}

// ---------------------------------------------------------------- claiming

async function startClaim() {
  const r = await openDialog({
    eyebrow: 'Claim your listing',
    title: 'Find your business',
    submit: null,
    wide: true,
    body: `<div class="claim-search">${field('q', 'Business name', { attrs: 'autofocus autocomplete="off" placeholder="Start typing your business name"' })}</div><div id="claim-results"></div>`,
    onOpen(form) {
      let timer;
      form.querySelector('[name=q]').addEventListener('input', e => {
        clearTimeout(timer);
        timer = setTimeout(async () => {
          const q = e.target.value.trim();
          const box = form.querySelector('#claim-results');
          if (q.length < 2) { box.innerHTML = ''; return; }
          const results = await run(db().from('vendors').select('vendor_id, vendor_name, vendor_category, vendor_location, contact_email')
            .ilike('vendor_name', `%${q.replace(/[%_]/g, '')}%`).or('is_claimed.eq.false,is_claimed.is.null').limit(10)).catch(() => []);
          state.claimResults = results;
          box.innerHTML = renderClaimResults(results);
        }, 250);
      });
    },
  });
}

// The results' "This is mine" buttons live inside the dialog; handle them here.
document.addEventListener('click', async e => {
  const b = e.target.closest('[data-action="claim-this"]');
  if (!b) return;
  e.preventDefault();
  const vendor = state.claimResults?.find(v => v.vendor_id === b.dataset.id);
  b.closest('dialog')?.close();
  b.closest('dialog')?.remove();
  if (vendor) await verifyAndClaim(vendor);
}, true);

/**
 * Send a one-time code to the listing's contact email. Once it's entered, the
 * server checks that email itself (claimListing), so a claim can't be faked
 * from the browser.
 */
async function verifyAndClaim(vendor) {
  const auth = db().auth;
  const r = await openDialog({
    eyebrow: 'Claim your listing',
    title: vendor.vendor_name,
    submit: 'Send my code',
    body: `<p class="sheet-lede">Enter the email on file for this business. We'll send it a code to confirm it's yours.</p>${field('email', 'Business email', { type: 'email', required: true, attrs: 'autofocus' })}`,
    onOpen(form, ui) {
      form.addEventListener('submit', async e => {
        e.stopImmediatePropagation();
        e.preventDefault();
        const entered = new FormData(form).get('email').trim().toLowerCase();
        if (entered !== String(vendor.contact_email).trim().toLowerCase()) { ui.error('That email doesn\'t match our records for this business.'); return; }
        const { error } = await auth.signInWithOtp({ email: entered, options: { shouldCreateUser: true } });
        if (error) { ui.error(error.message); return; }
        ui.finish({ action: 'sent', email: entered });
      }, { capture: true });
    },
  });
  if (r?.action !== 'sent') return;
  const original = (await auth.getSession()).data.session;
  state.claiming = true;
  const c = await openDialog({
    eyebrow: 'Claim your listing',
    title: 'Check your email',
    submit: 'Confirm',
    body: `<p class="sheet-lede">We sent a code to ${esc(r.email)}.</p>${field('code', 'Verification code', { required: true, attrs: 'autofocus inputmode="numeric" autocomplete="one-time-code"' })}`,
    onOpen(form, ui) {
      form.addEventListener('submit', async e => {
        e.stopImmediatePropagation();
        e.preventDefault();
        const { error } = await auth.verifyOtp({ email: r.email, token: new FormData(form).get('code').trim(), type: 'email' });
        if (error) { ui.error('That code didn\'t work. Check the newest email and try again.'); return; }
        try {
          await claimListing(db(), vendor.vendor_id, original);
          ui.finish({ action: 'ok' });
        } catch (err) {
          ui.error(`We couldn't claim it. ${err.message}`);
        }
      }, { capture: true });
    },
  });
  state.claiming = false;
  if (c?.action !== 'ok') {
    // Gave up after the code was sent: make sure the vendor's own login is back.
    if (original && (await auth.getSession()).data.session?.user.id !== original.user.id) await auth.setSession({ access_token: original.access_token, refresh_token: original.refresh_token });
    return;
  }
  toast(`${vendor.vendor_name} is yours. Welcome to easiYESt!`);
  await show();
}

// ---------------------------------------------------------------- events

const ACTIONS = {
  'log-in': () => openAuthDialog('log-in', 'Log in with your vendor account.'),
  'sign-up': () => openAuthDialog('sign-up', 'Create your vendor account first. Next you\'ll claim your listing or create a new one.'),
  'log-out': () => signOut(),
  claim: startClaim,
  create: () => showForm(true),
  edit: () => showForm(false),
  'cancel-edit': () => (state.vendor ? showDashboard() : show()),
};

document.addEventListener('click', e => {
  if (handleAccountClick(e)) return;
  const rm = e.target.closest('[data-remove-photo]');
  if (rm) {
    state.removed.add(Number(rm.dataset.removePhoto));
    rm.closest('li').remove();
    return;
  }
  const rmNew = e.target.closest('[data-remove-new]');
  if (rmNew) {
    state.newFiles.splice(Number(rmNew.dataset.removeNew), 1);
    paintNewPhotos();
    return;
  }
  const act = e.target.closest('[data-action]');
  if (act && ACTIONS[act.dataset.action]) { e.preventDefault(); ACTIONS[act.dataset.action](act); }
});

const mb = document.getElementById('menu-btn'), mm = document.getElementById('mobile-menu');
mb?.addEventListener('click', () => {
  const open = mb.getAttribute('aria-expanded') !== 'true';
  mb.setAttribute('aria-expanded', String(open));
  mb.setAttribute('aria-label', open ? 'Close menu' : 'Open menu');
  mm.hidden = !open;
});

(async () => {
  state.user = await currentUser().catch(() => null);
  await show().catch(err => { main.innerHTML = `<p class="loading-note">We couldn't load your dashboard. ${esc(err.message)}</p>`; });
  db().auth.onAuthStateChange((event, session) => {
    const next = session?.user ?? null;
    if (!state.claiming && (next?.id ?? null) !== (state.user?.id ?? null)) {
      state.user = next;
      setTimeout(() => show().catch(err => toast(err.message)), 0);
    }
  });
})();
