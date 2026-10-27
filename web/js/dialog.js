// One stationery-style <dialog> for every form on the website's app pages.
// openDialog resolves with { action, data, form } when a button is pressed,
// or null when the dialog is closed with Escape or the close button.

import { esc } from './plan-view.js';

export function openDialog({ eyebrow = '', title, body, submit = 'Save', actions = [], wide = false, onOpen }) {
  const dlg = document.createElement('dialog');
  dlg.className = `sheet${wide ? ' sheet-wide' : ''}`;
  dlg.setAttribute('aria-labelledby', 'sheet-title');
  dlg.innerHTML = `<form class="sheet-form" novalidate>
    <button type="button" class="sheet-close" data-close aria-label="Close">&times;</button>
    ${eyebrow ? `<span class="eyebrow">${esc(eyebrow)}</span>` : ''}
    <h2 id="sheet-title">${esc(title)}</h2>
    <div class="sheet-body">${body}</div>
    <p class="sheet-error" role="alert" hidden></p>
    <div class="sheet-actions">
      ${actions.map(a => `<button type="button" class="btn btn-${a.variant ?? 'line'} btn-sm" data-act="${esc(a.action)}">${esc(a.label)}</button>`).join('')}
      ${submit ? `<button type="submit" class="btn btn-plum btn-sm">${esc(submit)}</button>` : ''}
    </div>
  </form>`;
  document.body.appendChild(dlg);
  const form = dlg.querySelector('form');

  return new Promise(resolve => {
    let settled = false;
    const finish = value => {
      if (settled) return;
      settled = true;
      dlg.close();
      dlg.remove();
      resolve(value);
    };
    dlg.addEventListener('cancel', e => { e.preventDefault(); finish(null); });
    dlg.addEventListener('click', e => {
      if (e.target === dlg || e.target.closest('[data-close]')) finish(null);
      const act = e.target.closest('[data-act]');
      if (act) finish({ action: act.dataset.act, data: new FormData(form), form });
    });
    form.addEventListener('submit', e => {
      e.preventDefault();
      if (!form.reportValidity()) return;
      finish({ action: 'submit', data: new FormData(form), form });
    });
    dlg.showModal();
    onOpen?.(form, { error: msg => showError(form, msg), finish });
    form.querySelector('[autofocus]')?.focus();
  });
}

export function showError(form, message) {
  const el = form.querySelector('.sheet-error');
  el.textContent = message;
  el.hidden = !message;
}

export function confirmDialog({ title, body, confirm = 'Continue', danger = false }) {
  return openDialog({
    title,
    body: `<p>${esc(body)}</p>`,
    submit: null,
    actions: [{ action: 'cancel', label: 'Cancel' }, { action: 'ok', label: confirm, variant: danger ? 'danger' : 'plum' }],
  }).then(r => r?.action === 'ok');
}

let toastTimer;
export function toast(message) {
  let el = document.getElementById('toast');
  if (!el) {
    el = document.createElement('div');
    el.id = 'toast';
    el.className = 'toast';
    el.setAttribute('role', 'status');
    document.body.appendChild(el);
  }
  el.textContent = message;
  el.classList.add('is-on');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => el.classList.remove('is-on'), 4200);
}

/** A labeled form field. type 'select' takes options [[value, label]]. */
export function field(name, label, { type = 'text', value = '', options = [], required = false, attrs = '' } = {}) {
  const req = required ? ' required' : '';
  let input;
  if (type === 'textarea') input = `<textarea id="f-${name}" name="${name}"${req} ${attrs}>${esc(value)}</textarea>`;
  else if (type === 'select') input = `<select id="f-${name}" name="${name}"${req} ${attrs}>${options.map(([v, l]) => `<option value="${esc(v)}"${String(v) === String(value) ? ' selected' : ''}>${esc(l)}</option>`).join('')}</select>`;
  else input = `<input id="f-${name}" name="${name}" type="${type}" value="${esc(value)}"${req} ${attrs}>`;
  return `<div class="field"><label for="f-${name}">${esc(label)}</label>${input}</div>`;
}
