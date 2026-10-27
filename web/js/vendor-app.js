// Interactive bits of the generated vendor pages (/vendors/...): the menu,
// the account link, Love and YES buttons, and "Add to budget" on a YES.
// The pages are complete without this script; it only adds the buttons' state.

import { getClient, currentUser, paintAccountLinks, handleAccountClick } from './auth.js';
import { createLocalPicks, createRemotePicks, movePicksToAccount } from './picks.js';
import { createLocalStore, createRemoteStore, moveLocalToAccount } from './plan-store.js';
import { addVendorToBudget } from './budget.js';
import { toast } from './dialog.js';

const storage = (() => { try { return window.localStorage; } catch { return { getItem: () => null, setItem() { throw new Error('blocked'); }, removeItem() {} }; } })();
const localPicks = createLocalPicks(storage);
const localPlan = createLocalStore(storage);
const state = { user: null, picks: localPicks, chosen: { loved: new Set(), yes: {} } };

async function useAccount(user) {
  state.user = user;
  state.picks = user ? createRemotePicks(getClient(), user.id) : localPicks;
  if (user) {
    // Anything saved in this browser before logging in moves to the account.
    if (localPicks.hasData()) await movePicksToAccount(localPicks, state.picks);
    if (localPlan.hasData()) await moveLocalToAccount(localPlan, createRemoteStore(getClient(), user.id));
  }
  state.chosen = await state.picks.load();
  paint();
}

function paint() {
  const { loved, yes } = state.chosen;
  document.querySelectorAll('[data-pick]').forEach(b => {
    const id = b.dataset.vendorId;
    const on = b.dataset.pick === 'love' ? loved.has(id) : yes[b.dataset.category] === id;
    b.setAttribute('aria-pressed', String(on));
    const label = b.querySelector('span');
    if (label) label.textContent = b.dataset.pick === 'love' ? (on ? 'Loved' : 'Love') : (on ? 'Your YES' : 'YES');
  });
  const article = document.querySelector('article.vendor');
  const note = document.querySelector('.yes-note');
  if (article && note) {
    const btn = note.querySelector('[data-add-budget]');
    note.hidden = yes[btn.dataset.category] !== article.dataset.vendorId;
  }
  paintAccountLinks(state.user);
}

async function togglePick(b) {
  const id = b.dataset.vendorId, cat = b.dataset.category;
  const { loved, yes } = state.chosen;
  const wasOn = b.getAttribute('aria-pressed') === 'true';
  const on = !wasOn;
  if (b.dataset.pick === 'love') on ? loved.add(id) : loved.delete(id);
  else if (on) yes[cat] = id;
  else delete yes[cat];
  paint();
  if (on && b.dataset.pick === 'yes' && !matchMedia('(prefers-reduced-motion: reduce)').matches) {
    b.classList.remove('is-shimmer');
    void b.offsetWidth;
    b.classList.add('is-shimmer');
  }
  try {
    if (b.dataset.pick === 'love') await state.picks.setLove(id, on);
    else await state.picks.setYes(id, cat, on);
    const where = state.user ? '' : ' Saved in this browser. Create an account to keep it.';
    if (on) toast(b.dataset.pick === 'love' ? `Added to your loved vendors.${where}` : `Your YES for ${cat}.${where}`);
  } catch (err) {
    toast(`That didn't save. ${err.message}`);
    state.chosen = await state.picks.load();
    paint();
  }
}

function addToBudget(b) {
  return addVendorToBudget(state.user ? createRemoteStore(getClient(), state.user.id) : localPlan, b);
}

document.addEventListener('click', e => {
  const pick = e.target.closest('[data-pick]');
  if (pick) { e.preventDefault(); togglePick(pick); return; }
  const budget = e.target.closest('[data-add-budget]');
  if (budget) { e.preventDefault(); addToBudget(budget); return; }
  handleAccountClick(e);
});

const mb = document.getElementById('menu-btn'), mm = document.getElementById('mobile-menu');
mb?.addEventListener('click', () => {
  const open = mb.getAttribute('aria-expanded') !== 'true';
  mb.setAttribute('aria-expanded', String(open));
  mb.setAttribute('aria-label', open ? 'Close menu' : 'Open menu');
  mm.hidden = !open;
});

(async () => {
  try {
    await useAccount(await currentUser());
  } catch (err) {
    console.error(err);
    await useAccount(null);
  }
  getClient().auth.onAuthStateChange((event, session) => {
    const next = session?.user ?? null;
    if ((next?.id ?? null) !== (state.user?.id ?? null)) setTimeout(() => useAccount(next).catch(err => toast(err.message)), 0);
  });
})();
