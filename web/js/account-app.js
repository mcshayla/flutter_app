// The couple's account pages: /loved.html, /yes.html and /account.html
// (<body data-page="loved|yes|account">). Like the Plan page, Loved and YES
// work logged out (saved in this browser) and move into the account on login.

import { getClient, currentUser, openAuthDialog, signOut, paintAccountLinks, handleAccountClick } from './auth.js';
import { createLocalPicks, createRemotePicks, movePicksToAccount } from './picks.js';
import { createLocalStore, createRemoteStore, moveLocalToAccount } from './plan-store.js';
import { renderLoved, renderYes, coupleTitle } from './account-view.js';
import { parseDate, longDate } from './plan-logic.js';
import { esc } from './plan-view.js';
import { addVendorToBudget } from './budget.js';
import { openDialog, confirmDialog, toast, field } from './dialog.js';

const PAGE = document.body.dataset.page;
const storage = (() => { try { return window.localStorage; } catch { return { getItem: () => null, setItem() { throw new Error('blocked'); }, removeItem() {} }; } })();
const localPicks = createLocalPicks(storage);
const localPlan = createLocalStore(storage);
const main = document.getElementById('content');

const state = {
  user: null,
  picks: localPicks,
  plan: localPlan,
  chosen: { loved: new Set(), yes: {}, booked: new Set() },
  profile: {},
  index: { categories: [], vendors: {} },
  compare: null,
  username: null,
  tasks: { done: 0, total: 0 },
};

async function loadIndex() {
  try {
    const res = await fetch('/vendors/index.json');
    if (res.ok) state.index = await res.json();
  } catch { /* the pages still work; vendor cards just won't show */ }
}

async function useAccount(user) {
  state.user = user;
  state.picks = user ? createRemotePicks(getClient(), user.id) : localPicks;
  state.plan = user ? createRemoteStore(getClient(), user.id) : localPlan;
  if (user) {
    if (localPicks.hasData()) await movePicksToAccount(localPicks, state.picks);
    if (localPlan.hasData()) await moveLocalToAccount(localPlan, state.plan);
    const { data } = await getClient().from('users').select('username').eq('user_id', user.id).maybeSingle();
    state.username = data?.username ?? null;
  }
  state.chosen = await state.picks.load();
  const plan = await state.plan.load();
  state.profile = plan.profile;
  state.tasks = { done: plan.checklist.filter(t => t.is_completed).length, total: plan.checklist.length };
  render();
}

// ---------------------------------------------------------------- render

function render() {
  paintAccountLinks(state.user);
  if (PAGE === 'loved') main.innerHTML = renderLoved(state.chosen, state.index, state.compare) + saveNote();
  if (PAGE === 'yes') main.innerHTML = renderYes(state.chosen, state.index, state.profile, new Date()) + saveNote();
  if (PAGE === 'account') main.innerHTML = renderAccountPage();
}

const saveNote = () => (state.user ? '' : `<div class="save-note"><p>Saved in this browser only. <button type="button" class="text-btn" data-action="sign-up">Create a free account</button> to keep your picks and see them on your phone.</p></div>`);

function renderAccountPage() {
  const u = state.user;
  const p = state.profile;
  const date = parseDate(p.wedding_date);
  const loved = state.chosen.loved.size;
  const yes = Object.keys(state.chosen.yes).length;
  const links = `<ul class="account-links">
    <li><a href="/loved.html"><b>${loved}</b><span>Loved vendors</span></a></li>
    <li><a href="/yes.html"><b>${yes}</b><span>Your YES list</span></a></li>
    <li><a href="/plan.html"><b>${state.tasks.total ? `${state.tasks.done}/${state.tasks.total}` : '–'}</b><span>Checklist tasks done</span></a></li>
  </ul>`;
  const wedding = `<section class="account-card">
      <span class="eyebrow">Your wedding</span>
      <h2>${esc(coupleTitle(p) ?? 'Wedding details')}</h2>
      <p class="muted">${date ? esc(longDate(date)) : 'No date yet'}${p.wedding_location ? ` · ${esc(p.wedding_location)}` : ''}</p>
      <button type="button" class="btn btn-line btn-sm" data-action="edit-wedding">${date || coupleTitle(p) ? 'Edit details' : 'Add details'}</button>
    </section>`;

  if (!u) {
    return `<section class="intro intro-tight"><div class="intro-inner">
        <span class="eyebrow">easiYESt account</span>
        <h1>Your <em>account</em></h1>
        <p>Log in to see your plan, loved vendors and YES list on any device, including the easiYESt phone app.</p>
        <div class="account-cta">
          <button type="button" class="btn btn-plum" data-action="log-in">Log in</button>
          <button type="button" class="btn btn-line" data-action="sign-up">Create a free account</button>
        </div>
      </div></section>
      <div class="account-wrap">${links}${wedding}
        <p class="vendor-login">Are you a wedding vendor? <a href="/vendor.html">Log in to your vendor dashboard</a></p>
      </div>`;
  }

  return `<section class="intro intro-tight"><div class="intro-inner">
      <span class="eyebrow">easiYESt account</span>
      <h1>${state.username && !/^[0-9a-f-]{30,}$/i.test(state.username) ? `Hi, <em>${esc(state.username)}</em>` : 'Your <em>account</em>'}</h1>
      <p class="note">${esc(u.email ?? '')}</p>
    </div></section>
    <div class="account-wrap">${links}${wedding}
      <section class="account-card">
        <span class="eyebrow">Login</span>
        <p class="muted">Signed in as ${esc(u.email ?? '')}.</p>
        <div class="card-actions">
          <button type="button" class="btn btn-line btn-sm" data-action="reset-password">Change password</button>
          <button type="button" class="btn btn-line btn-sm" data-action="log-out">Log out</button>
        </div>
      </section>
      <p class="vendor-login">Are you a wedding vendor? <a href="/vendor.html">Go to your vendor dashboard</a></p>
      <section class="account-danger">
        <button type="button" class="text-btn is-danger" data-action="delete-account">Delete my account</button>
      </section>
    </div>`;
}

// ---------------------------------------------------------------- actions

async function togglePick(b) {
  const id = b.dataset.vendorId, cat = b.dataset.category;
  const on = b.getAttribute('aria-pressed') !== 'true';
  try {
    if (b.dataset.pick === 'love') await state.picks.setLove(id, on);
    else await state.picks.setYes(id, cat, on);
  } catch (err) {
    toast(`That didn't save. ${err.message}`);
  }
  state.chosen = await state.picks.load();
  render();
}

async function toggleBooked(b) {
  const id = b.dataset.vendorId;
  const on = b.getAttribute('aria-pressed') !== 'true';
  try {
    await state.picks.setBooked(id, on);
  } catch (err) {
    toast(`That didn't save. ${err.message}`);
    return;
  }
  state.chosen = await state.picks.load();
  render();
  if (on) {
    const v = state.index.vendors[id];
    // Same follow-up as the app: offer to put the booked vendor in the budget.
    if (v && await confirmDialog({ title: 'Add to your budget?', body: `Add ${v.name} to your budget so you can track what you'll spend.`, confirm: 'Add to budget' })) {
      const btn = main.querySelector(`[data-add-budget][data-vendor-id="${CSS.escape(id)}"]`);
      if (btn) await addVendorToBudget(state.plan, btn);
    }
  }
}

async function editWedding() {
  const p = state.profile;
  const r = await openDialog({
    eyebrow: 'Your wedding',
    title: 'Wedding details',
    body: `${field('wedding_date', 'Wedding date', { type: 'date', value: p.wedding_date ?? '', attrs: 'autofocus' })}
      <div class="field-row">${field('partner_name_1', 'Partner one', { value: p.partner_name_1 ?? '' })}${field('partner_name_2', 'Partner two', { value: p.partner_name_2 ?? '' })}</div>
      ${field('wedding_location', 'Location', { value: p.wedding_location ?? '', attrs: 'placeholder="City or venue"' })}`,
  });
  if (!r) return;
  const patch = {};
  for (const k of ['wedding_date', 'partner_name_1', 'partner_name_2', 'wedding_location']) patch[k] = r.data.get(k).trim() || null;
  try {
    await state.plan.saveProfile(patch);
    state.profile = (await state.plan.load()).profile;
    render();
    toast('Wedding details saved.');
  } catch (err) {
    toast(`That didn't save. ${err.message}`);
  }
}

async function resetPassword() {
  const { error } = await getClient().auth.resetPasswordForEmail(state.user.email, { redirectTo: `${location.origin}/resetPassword.html` });
  toast(error ? error.message : `We sent a link to ${state.user.email} to choose a new password.`);
}

async function deleteAccount() {
  const r = await openDialog({
    eyebrow: 'Delete account',
    title: 'Delete your account?',
    submit: null,
    actions: [{ action: 'cancel', label: 'Keep my account' }, { action: 'delete', label: 'Delete forever', variant: 'danger' }],
    body: `<p>This removes your account, checklist, guest list, budget, loved vendors and YES list from the website and the phone app. It can't be undone.</p>
      ${field('confirm', 'Type DELETE to confirm', { attrs: 'autocomplete="off" autofocus' })}`,
  });
  if (r?.action !== 'delete') return;
  if (r.data.get('confirm').trim().toUpperCase() !== 'DELETE') { toast('Type DELETE to confirm. Your account was not deleted.'); return; }
  // Same server function the app uses (supabase/functions/delete-user).
  const { error } = await getClient().functions.invoke('delete-user');
  if (error) { toast(`We couldn't delete your account. ${error.message}`); return; }
  await signOut();
  localPicks.clear();
  localPlan.clear();
  toast('Your account has been deleted.');
}

const ACTIONS = {
  'sign-up': () => openAuthDialog('sign-up', 'Your loved vendors, YES list and plan move into your account, so they\'re safe and on your phone too.'),
  'log-in': () => openAuthDialog('log-in'),
  'log-out': () => signOut(),
  'edit-wedding': editWedding,
  'reset-password': resetPassword,
  'delete-account': deleteAccount,
  compare: b => { state.compare = { category: b.dataset.category, picked: [] }; render(); },
  'compare-done': () => { state.compare = null; render(); },
  booked: toggleBooked,
};

document.addEventListener('click', e => {
  if (handleAccountClick(e)) return;
  const pick = e.target.closest('[data-pick]');
  if (pick) { e.preventDefault(); togglePick(pick); return; }
  const budget = e.target.closest('[data-add-budget]');
  if (budget) { e.preventDefault(); addVendorToBudget(state.plan, budget); return; }
  const act = e.target.closest('[data-action]');
  if (act && ACTIONS[act.dataset.action]) { e.preventDefault(); ACTIONS[act.dataset.action](act); }
});

main.addEventListener('change', e => {
  const id = e.target.dataset.comparePick;
  if (!id || !state.compare) return;
  const picked = state.compare.picked.filter(x => x !== id);
  if (e.target.checked) picked.push(id);
  state.compare.picked = picked.slice(0, 3);
  render();
  main.querySelector(`[data-compare-pick="${CSS.escape(id)}"]`)?.focus();
});

const mb = document.getElementById('menu-btn'), mm = document.getElementById('mobile-menu');
mb?.addEventListener('click', () => {
  const open = mb.getAttribute('aria-expanded') !== 'true';
  mb.setAttribute('aria-expanded', String(open));
  mb.setAttribute('aria-label', open ? 'Close menu' : 'Open menu');
  mm.hidden = !open;
});

(async () => {
  await loadIndex();
  try {
    await useAccount(await currentUser());
  } catch (err) {
    console.error(err);
    await useAccount(null);
    toast('We couldn\'t reach your account just now, so this shows what\'s saved in this browser.');
  }
  getClient().auth.onAuthStateChange((event, session) => {
    const next = session?.user ?? null;
    if ((next?.id ?? null) !== (state.user?.id ?? null)) setTimeout(() => useAccount(next).catch(err => toast(err.message)), 0);
  });
})();
