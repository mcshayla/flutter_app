// The website's Plan page: wires plan-view.js to the page, the dialogs and
// the right store. Works logged out (saved in this browser) and logged in
// (saved to the couple's account, shared with the phone app).

import { getClient, currentUser, openAuthDialog, signOut } from './auth.js';
import { createLocalStore, createRemoteStore, moveLocalToAccount } from './plan-store.js';
import { createLocalPicks, createRemotePicks, movePicksToAccount } from './picks.js';
import { renderCountdown, renderChecklist, renderGuests, renderBudget, renderSaveBanner, esc } from './plan-view.js';
import { buildChecklist, parseDate, parseMoney, mealInfo, guestsToCsv, RSVP_STATUSES, rsvpLabel } from './plan-logic.js';
import { openDialog, confirmDialog, toast, field } from './dialog.js';

const TABS = ['checklist', 'guests', 'budget'];
// Same list as the app's budget form (lib/pages/budget_item_form.dart).
const EXPENSE_CATEGORIES = ['Venue', 'Catering', 'Photography', 'Videography', 'Flowers', 'Music', 'Attire', 'Invitations', 'Decor', 'Transportation', 'Favors', 'Cake', 'Hair & Makeup', 'Officiant', 'Other'];
const RSVP_FIELDS = { email: 'Email address', phone: 'Phone number', address: 'Mailing address', dietary: 'Dietary restrictions', meal: 'Meal preference', notes: 'Notes / message', plus_one: 'Additional guest count' };

const $ = sel => document.querySelector(sel);
const local = createLocalStore(safeStorage());
const localPicks = createLocalPicks(safeStorage());

const state = {
  user: null,
  store: local,
  plan: null,
  tab: TABS.includes(new URLSearchParams(location.search).get('tab')) ? new URLSearchParams(location.search).get('tab') : 'checklist',
  view: 'timeline',
  collapsed: new Set(['Done']),
  guestFilter: { query: '', status: '', group: '' },
  categories: null,
  templates: null,
};

function safeStorage() {
  try { return window.localStorage; } catch { return { getItem: () => null, setItem() { throw new Error('blocked'); }, removeItem() {} }; }
}

// ---------------------------------------------------------------- start

async function start() {
  bindChrome();
  try {
    await useAccount(await currentUser(), { quiet: true });
  } catch (err) {
    console.error(err);
    await useAccount(null, { quiet: true });
    toast('We couldn\'t reach your account just now, so this shows the plan saved in this browser.');
  }
  getClient().auth.onAuthStateChange((event, session) => {
    const next = session?.user ?? null;
    if ((next?.id ?? null) !== (state.user?.id ?? null)) {
      // Supabase asks us not to await other Supabase calls inside this callback.
      setTimeout(() => useAccount(next).catch(err => toast(err.message)), 0);
    }
  });
}

async function useAccount(user, { quiet = false } = {}) {
  state.user = user;
  state.store = user ? createRemoteStore(getClient(), user.id) : local;
  if (user && localPicks.hasData()) await movePicksToAccount(localPicks, createRemotePicks(getClient(), user.id));
  if (user && local.hasData()) {
    const moved = await moveLocalToAccount(local, state.store);
    const parts = [moved.tasks && `${moved.tasks} tasks`, moved.guests && `${moved.guests} guests`, moved.budgetItems && `${moved.budgetItems} expenses`].filter(Boolean);
    if (parts.length) toast(`Saved to your account: ${parts.join(', ')}.`);
  } else if (!quiet) {
    toast(user ? 'You\'re logged in. Your plan is saved to your account.' : 'You\'re logged out.');
  }
  await reload();
}

async function reload() {
  state.plan = await state.store.load();
  render();
}

/** Run a change, then refresh from the store. Errors show as a toast. */
async function save(fn, done) {
  try {
    await fn();
    await reload();
    if (done) toast(done);
  } catch (err) {
    console.error(err);
    toast(`That didn't save. ${err.message ?? ''}`.trim());
    await reload().catch(() => {});
  }
}

// ---------------------------------------------------------------- render

function render() {
  const p = state.plan;
  $('#countdown').innerHTML = renderCountdown(p.profile, new Date());
  $('#save-banner').innerHTML = renderSaveBanner(state.user);
  for (const t of TABS) {
    const tabEl = document.getElementById(`tab-${t}`);
    tabEl.setAttribute('aria-selected', String(state.tab === t));
    tabEl.tabIndex = state.tab === t ? 0 : -1;
  }
  const panel = $('#panel');
  panel.setAttribute('aria-labelledby', `tab-${state.tab}`);
  if (state.tab === 'checklist') panel.innerHTML = renderChecklist({ items: p.checklist, view: state.view, collapsed: state.collapsed, now: new Date() });
  if (state.tab === 'guests') panel.innerHTML = renderGuests({ guests: p.guests, ...state.guestFilter });
  if (state.tab === 'budget') panel.innerHTML = renderBudget({ total: p.totalBudget, items: p.budgetItems, yesByCategory: p.yesByCategory });
  renderAccount();
}

function renderAccount() {
  const label = state.user ? 'Log out' : 'Log in';
  document.querySelectorAll('[data-account]').forEach(el => { el.textContent = label; });
}

function setTab(tab, focus = false) {
  state.tab = tab;
  const url = new URL(location.href);
  url.searchParams.set('tab', tab);
  history.replaceState(null, '', url);
  render();
  if (focus) document.getElementById(`tab-${tab}`).focus();
}

// ---------------------------------------------------------------- events

function bindChrome() {
  const tabs = $('#tabs');
  tabs.addEventListener('click', e => {
    const b = e.target.closest('[role=tab]');
    if (b) setTab(b.dataset.tab);
  });
  tabs.addEventListener('keydown', e => {
    const i = TABS.indexOf(state.tab);
    if (e.key === 'ArrowRight') setTab(TABS[(i + 1) % TABS.length], true);
    if (e.key === 'ArrowLeft') setTab(TABS[(i + TABS.length - 1) % TABS.length], true);
  });

  document.addEventListener('click', e => {
    const el = e.target.closest('[data-action]');
    if (el && ACTIONS[el.dataset.action]) {
      e.preventDefault();
      ACTIONS[el.dataset.action](el);
    }
    if (e.target.closest('[data-account]')) {
      e.preventDefault();
      if (state.user) signOut(); else openAuthDialog('log-in');
    }
  });

  $('#panel').addEventListener('input', e => {
    const key = e.target.dataset.filter;
    if (!key) return;
    state.guestFilter[key] = e.target.value;
    const caret = e.target.selectionStart;
    render();
    const again = document.querySelector(`[data-filter="${key}"]`);
    again.focus();
    if (key === 'query') again.setSelectionRange(caret, caret);
  });

  const mb = $('#menu-btn'), mm = $('#mobile-menu');
  mb.addEventListener('click', () => {
    const open = mb.getAttribute('aria-expanded') !== 'true';
    mb.setAttribute('aria-expanded', String(open));
    mb.setAttribute('aria-label', open ? 'Close menu' : 'Open menu');
    mm.hidden = !open;
  });
}

const findIn = (list, id) => list.find(r => String(r.id) === String(id));

const ACTIONS = {
  'edit-date': editWedding,
  'sign-up': () => openAuthDialog('sign-up', 'Your checklist, guests and budget move into your account, so they\'re safe and on your phone too.'),
  view: el => { state.view = el.dataset.view; render(); },
  'toggle-group': el => {
    const g = el.dataset.group;
    state.collapsed.has(g) ? state.collapsed.delete(g) : state.collapsed.add(g);
    render();
  },
  'toggle-task': el => {
    const task = findIn(state.plan.checklist, el.dataset.id);
    const done = !task.is_completed;
    task.is_completed = done; // show it right away; the save follows
    render();
    state.store.updateTask(task.id, { is_completed: done }).catch(err => {
      toast(`That didn't save. ${err.message}`);
      reload();
    });
  },
  'open-task': el => editTask(findIn(state.plan.checklist, el.dataset.id)),
  'add-task': () => editTask(null),
  generate: generateChecklist,
  'add-guest': () => editGuest(null),
  'open-guest': el => editGuest(findIn(state.plan.guests, el.dataset.id)),
  meals: showMeals,
  export: exportGuests,
  'rsvp-links': rsvpLinks,
  'set-budget': setBudget,
  'add-expense': () => editExpense(null),
  'open-expense': el => editExpense(findIn(state.plan.budgetItems, el.dataset.id)),
};

// ---------------------------------------------------------------- wedding

async function editWedding() {
  const p = state.plan.profile;
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
  await save(() => state.store.saveProfile(patch), 'Wedding details saved.');
}

// ---------------------------------------------------------------- checklist

async function loadCatalog() {
  const db = getClient();
  if (!state.categories) {
    const { data, error } = await db.from('categories').select('name').order('display_order', { ascending: true });
    if (error) throw error;
    state.categories = data.map(c => c.name.trim());
  }
  if (!state.templates) {
    const { data, error } = await db.from('checklist_templates').select('*').order('display_order', { ascending: true });
    if (error) throw error;
    state.templates = data;
  }
}

async function generateChecklist() {
  try { await loadCatalog(); } catch (err) { toast(`Couldn't load the checklist tasks. ${err.message}`); return; }
  const existing = state.plan.checklist.length;
  const date = state.plan.profile.wedding_date ?? '';
  const r = await openDialog({
    eyebrow: 'Your checklist',
    title: existing ? 'Regenerate your checklist' : 'Build your checklist',
    submit: existing ? 'Replace my checklist' : 'Build my checklist',
    wide: true,
    body: `${existing ? `<p class="sheet-warn">This replaces your ${existing} current tasks. Tasks you added yourself and your notes will be removed.</p>` : ''}
      ${field('wedding_date', 'Wedding date', { type: 'date', value: date, required: true })}
      <fieldset class="checks"><legend>Vendors you need</legend>
        <p class="checks-tools"><button type="button" class="text-btn" data-check="all">Select all</button> · <button type="button" class="text-btn" data-check="none">Clear</button></p>
        ${state.categories.map((c, i) => `<label><input type="checkbox" name="category" value="${esc(c)}" checked id="cat-${i}"> ${esc(c)}</label>`).join('')}
      </fieldset>`,
    onOpen(form) {
      form.addEventListener('click', e => {
        const b = e.target.closest('[data-check]');
        if (b) form.querySelectorAll('[name=category]').forEach(cb => { cb.checked = b.dataset.check === 'all'; });
      });
    },
  });
  if (!r) return;
  const wedding = parseDate(r.data.get('wedding_date'));
  const chosen = r.data.getAll('category');
  if (!chosen.length) { toast('Pick at least one vendor type.'); return; }
  const rows = buildChecklist(state.templates, wedding, chosen, new Date());
  await save(async () => {
    if (state.plan.profile.wedding_date !== r.data.get('wedding_date')) await state.store.saveProfile({ wedding_date: r.data.get('wedding_date') });
    if (existing) await state.store.deleteAllTasks();
    await state.store.addTasks(rows);
  }, `Your checklist has ${rows.length} tasks.`);
}

async function editTask(task) {
  try { await loadCatalog(); } catch { state.categories ??= []; }
  const cats = [...new Set([...state.categories, 'Other', task?.category].filter(Boolean))];
  const r = await openDialog({
    eyebrow: task ? (task.category || 'Task') : 'New task',
    title: task ? task.title : 'Add a task',
    actions: task ? [{ action: 'delete', label: 'Delete', variant: 'danger' }] : [],
    submit: task ? 'Save' : 'Add task',
    body: `${task?.description ? `<p class="sheet-lede">${esc(task.description)}</p>` : ''}
      ${field('title', 'Task', { value: task?.title ?? '', required: true, attrs: task ? '' : 'autofocus' })}
      <div class="field-row">${field('category', 'Category', { type: 'select', value: task?.category ?? 'Other', options: cats.map(c => [c, c]) })}
      ${field('due_date', 'Due date', { type: 'date', value: task?.due_date ?? '' })}</div>
      ${field('notes', 'Notes', { type: 'textarea', value: task?.notes ?? '', attrs: 'placeholder="Quotes, contacts, ideas…"' })}`,
  });
  if (!r) return;
  if (r.action === 'delete') {
    if (await confirmDialog({ title: 'Delete this task?', body: task.title, confirm: 'Delete', danger: true })) await save(() => state.store.deleteTask(task.id), 'Task deleted.');
    return;
  }
  const row = { title: r.data.get('title').trim(), category: r.data.get('category'), due_date: r.data.get('due_date') || null, notes: r.data.get('notes').trim() };
  if (task) await save(() => state.store.updateTask(task.id, row));
  else {
    const order = state.plan.checklist.reduce((m, t) => Math.max(m, (t.display_order ?? 0) + 1), 0);
    await save(() => state.store.addTasks([{ ...row, description: '', is_completed: false, display_order: order }]), 'Task added.');
  }
}

// ---------------------------------------------------------------- guests

async function editGuest(g) {
  const r = await openDialog({
    eyebrow: g ? 'Guest' : 'New guest',
    title: g ? (`${g.first_name ?? ''} ${g.last_name ?? ''}`.trim() || 'Guest') : 'Add a guest',
    wide: true,
    actions: g ? [{ action: 'delete', label: 'Delete', variant: 'danger' }] : [],
    submit: g ? 'Save' : 'Add guest',
    body: `<div class="field-row">${field('first_name', 'First name', { value: g?.first_name ?? '', required: true, attrs: 'autofocus autocomplete="off"' })}${field('last_name', 'Last name', { value: g?.last_name ?? '', attrs: 'autocomplete="off"' })}</div>
      <div class="field-row">${field('email', 'Email', { type: 'email', value: g?.email ?? '', attrs: 'autocomplete="off"' })}${field('phone', 'Phone', { type: 'tel', value: g?.phone ?? '', attrs: 'autocomplete="off"' })}</div>
      ${field('address', 'Mailing address', { value: g?.address ?? '', attrs: 'autocomplete="off"' })}
      <div class="field-row">${field('group_name', 'Group', { value: g?.group_name ?? '', attrs: 'placeholder="Bride\'s family, College friends…" list="group-list"' })}
      ${field('rsvp_status', 'RSVP', { type: 'select', value: g?.rsvp_status ?? 'not_sent', options: RSVP_STATUSES.map(s => [s, rsvpLabel(s)]) })}</div>
      <datalist id="group-list">${[...new Set(state.plan.guests.map(x => x.group_name).filter(Boolean))].map(x => `<option value="${esc(x)}">`).join('')}</datalist>
      <div class="field-row">${field('meal_preference', 'Meal', { value: g?.meal_preference ?? '' })}${field('dietary_restrictions', 'Dietary needs', { value: g?.dietary_restrictions ?? '' })}</div>
      <div class="field-row">${field('plus_one_count', 'Additional guests', { type: 'number', value: g?.plus_one_count ?? 0, attrs: 'min="0" max="20"' })}${field('plus_one_name', 'Their names', { value: g?.plus_one_name ?? '' })}</div>
      ${field('notes', 'Notes', { type: 'textarea', value: g?.notes ?? '' })}`,
  });
  if (!r) return;
  if (r.action === 'delete') {
    if (await confirmDialog({ title: 'Remove this guest?', body: `${g.first_name ?? ''} ${g.last_name ?? ''}`.trim(), confirm: 'Remove', danger: true })) await save(() => state.store.deleteGuest(g.id), 'Guest removed.');
    return;
  }
  const row = {};
  for (const k of ['first_name', 'last_name', 'email', 'phone', 'address', 'group_name', 'rsvp_status', 'meal_preference', 'dietary_restrictions', 'plus_one_name', 'notes']) row[k] = r.data.get(k).trim();
  row.plus_one_count = Math.max(0, parseInt(r.data.get('plus_one_count'), 10) || 0);
  row.plus_one_allowed = row.plus_one_count > 0;
  await save(() => (g ? state.store.updateGuest(g.id, row) : state.store.addGuest(row)), g ? null : 'Guest added.');
}

function showMeals() {
  const info = mealInfo(state.plan.guests);
  openDialog({
    eyebrow: 'Guest list',
    title: 'Meals & dietary needs',
    submit: 'Done',
    body: `<p class="sheet-lede">${info.length} of ${state.plan.guests.length} guests have meal or dietary notes.</p>
      ${info.length ? `<ul class="meal-list">${info.map(i => `<li><b>${esc(i.name || 'Unnamed guest')}</b>${i.meal ? `<span>Meal: ${esc(i.meal)}</span>` : ''}${i.diet ? `<span>Dietary: ${esc(i.diet)}</span>` : ''}</li>`).join('')}</ul>` : ''}`,
  });
}

function exportGuests() {
  if (!state.plan.guests.length) { toast('Add a guest first, then export.'); return; }
  // The BOM makes Excel read names with accents correctly.
  const blob = new Blob(['﻿', guestsToCsv(state.plan.guests)], { type: 'text/csv;charset=utf-8' });
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = 'easiyest-guest-list.csv';
  a.click();
  setTimeout(() => URL.revokeObjectURL(a.href), 1000);
  toast('Guest list downloaded. It opens in Excel or Google Sheets.');
}

async function rsvpLinks() {
  if (!state.user) {
    await openAuthDialog('sign-up', 'RSVP links add guests straight to your list, so they need an account to save into. It\'s free.');
    return;
  }
  const db = getClient();
  const { data: links, error } = await db.from('guest_link_configs').select('*').eq('user_id', state.user.id).order('created_at', { ascending: false });
  if (error) { toast(error.message); return; }
  const url = t => `https://www.easiyest.com/rsvp.html?token=${encodeURIComponent(t)}`;
  const r = await openDialog({
    eyebrow: 'Guest list',
    title: 'RSVP links',
    wide: true,
    submit: 'Create link',
    body: `<p class="sheet-lede">Share a link and guests add their own details to your list.</p>
      ${links.length ? `<ul class="link-list">${links.map(l => `<li><div><b>${esc(l.label || 'RSVP link')}</b>${l.group_name ? `<small>Group: ${esc(l.group_name)}</small>` : ''}<code>${esc(url(l.token))}</code></div>
        <div class="link-actions"><button type="button" class="btn btn-line btn-sm" data-copy="${esc(url(l.token))}">Copy</button><button type="button" class="text-btn is-danger" data-act="delete:${esc(l.id)}">Delete</button></div></li>`).join('')}</ul>` : ''}
      <h3 class="sheet-sub">${links.length ? 'New link' : 'Create your first link'}</h3>
      <div class="field-row">${field('label', 'Label', { attrs: 'placeholder="Bride\'s side"' })}${field('group_name', 'Put guests in group', { attrs: 'placeholder="Optional"' })}</div>
      <fieldset class="checks"><legend>Ask guests for</legend>
        ${Object.entries(RSVP_FIELDS).map(([k, l]) => `<label><input type="checkbox" name="fields" value="${k}"${k === 'address' ? ' checked' : ''}> ${esc(l)}</label>`).join('')}
      </fieldset>`,
    onOpen(form) {
      form.addEventListener('click', async e => {
        const b = e.target.closest('[data-copy]');
        if (!b) return;
        try { await navigator.clipboard.writeText(b.dataset.copy); b.textContent = 'Copied'; } catch { prompt('Copy this link:', b.dataset.copy); }
      });
    },
  });
  if (!r) return;
  if (r.action.startsWith('delete:')) {
    if (await confirmDialog({ title: 'Delete this RSVP link?', body: 'Anyone who has it won\'t be able to use it anymore.', confirm: 'Delete', danger: true })) {
      const { error: e } = await db.from('guest_link_configs').delete().eq('id', r.action.slice(7)).eq('user_id', state.user.id);
      if (e) toast(e.message);
    }
    return rsvpLinks();
  }
  const chosen = new Set(r.data.getAll('fields'));
  const { error: e } = await db.from('guest_link_configs').insert({
    user_id: state.user.id,
    label: r.data.get('label').trim(),
    group_name: r.data.get('group_name').trim(),
    fields_enabled: Object.fromEntries(Object.keys(RSVP_FIELDS).map(k => [k, chosen.has(k)])),
    partner1_name: state.plan.profile.partner_name_1 ?? '',
    partner2_name: state.plan.profile.partner_name_2 ?? '',
  });
  if (e) toast(e.message);
  return rsvpLinks();
}

// ---------------------------------------------------------------- budget

async function setBudget() {
  const r = await openDialog({
    eyebrow: 'Budget',
    title: 'Your total budget',
    body: field('total', 'Total budget', { value: state.plan.totalBudget || '', required: true, attrs: 'inputmode="decimal" placeholder="$30,000" autofocus' }),
  });
  if (!r) return;
  const amount = parseMoney(r.data.get('total'));
  if (amount == null || amount < 0) { toast('Enter the budget as a number, like 30000.'); return; }
  await save(() => state.store.setTotalBudget(amount), 'Budget saved.');
}

async function editExpense(item) {
  const money = v => (v == null || v === '' ? '' : String(v));
  const r = await openDialog({
    eyebrow: item ? (item.category || 'Expense') : 'New expense',
    title: item ? item.item_name : 'Add an expense',
    actions: item ? [{ action: 'delete', label: 'Delete', variant: 'danger' }] : [],
    submit: item ? 'Save' : 'Add expense',
    body: `${field('item_name', 'What is it?', { value: item?.item_name ?? '', required: true, attrs: item ? '' : 'autofocus placeholder="Photographer deposit"' })}
      ${field('category', 'Category', { type: 'select', value: EXPENSE_CATEGORIES.includes(item?.category) ? item.category : (item ? 'Other' : 'Venue'), options: EXPENSE_CATEGORIES.map(c => [c, c]) })}
      <div class="field-row">${field('estimated_cost', 'Planned', { value: money(item?.estimated_cost), attrs: 'inputmode="decimal" placeholder="$0"' })}${field('actual_cost', 'Spent so far', { value: money(item?.actual_cost), attrs: 'inputmode="decimal" placeholder="$0"' })}</div>
      <label class="check-line"><input type="checkbox" name="is_paid"${item?.is_paid ? ' checked' : ''}> Paid in full</label>
      ${field('notes', 'Notes', { type: 'textarea', value: item?.notes ?? '' })}`,
  });
  if (!r) return;
  if (r.action === 'delete') {
    if (await confirmDialog({ title: 'Delete this expense?', body: item.item_name, confirm: 'Delete', danger: true })) await save(() => state.store.deleteBudgetItem(item.id), 'Expense deleted.');
    return;
  }
  const row = {
    item_name: r.data.get('item_name').trim(),
    category: r.data.get('category'),
    estimated_cost: parseMoney(r.data.get('estimated_cost')) ?? 0,
    actual_cost: parseMoney(r.data.get('actual_cost')),
    is_paid: r.data.get('is_paid') === 'on',
    notes: r.data.get('notes').trim(),
  };
  await save(() => (item ? state.store.updateBudgetItem(item.id, row) : state.store.addBudgetItem(row)), item ? null : 'Expense added.');
}

start();
