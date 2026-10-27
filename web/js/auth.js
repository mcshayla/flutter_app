// Log in / create account for the website, using the same Supabase accounts
// as the Flutter app. The supabase-js script tag puts `supabase` on window.

import { SUPABASE_URL, SUPABASE_ANON } from './supabase-config.js';
import { openDialog, showError, field } from './dialog.js';

let client;
export function getClient() {
  client ??= window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON);
  return client;
}

export async function currentUser() {
  const { data } = await getClient().auth.getSession();
  return data.session?.user ?? null;
}

const COPY = {
  'sign-up': { title: 'Create your free account', submit: 'Create account', other: 'log-in', otherLabel: 'I already have an account' },
  'log-in': { title: 'Welcome back', submit: 'Log in', other: 'sign-up', otherLabel: 'Create an account instead' },
};

/**
 * Opens the login dialog. Resolves with the signed-in user, or null if the
 * visitor closes it. `reason` is a line explaining why we're asking.
 */
export async function openAuthDialog(mode = 'sign-up', reason = '') {
  const c = COPY[mode];
  const result = await openDialog({
    eyebrow: 'easiYESt account',
    title: c.title,
    submit: c.submit,
    body: `${reason ? `<p class="sheet-lede">${reason}</p>` : ''}
      ${mode === 'sign-up' ? field('username', 'Your name', { attrs: 'autocomplete="name"' }) : ''}
      ${field('email', 'Email', { type: 'email', required: true, attrs: 'autocomplete="email" autofocus' })}
      ${field('password', 'Password', { type: 'password', required: true, attrs: `minlength="6" autocomplete="${mode === 'sign-up' ? 'new-password' : 'current-password'}"` })}
      <p class="sheet-links">
        <button type="button" class="text-btn" data-act="${c.other}">${c.otherLabel}</button>
        ${mode === 'log-in' ? '<button type="button" class="text-btn" data-act="forgot">Forgot password?</button>' : ''}
      </p>`,
    onOpen(form, ui) {
      // Keep the dialog open while we talk to Supabase so errors show inline.
      form.addEventListener('submit', async e => {
        e.stopImmediatePropagation();
        e.preventDefault();
        if (!form.reportValidity()) return;
        const btn = form.querySelector('[type=submit]');
        btn.disabled = true;
        ui.error('');
        const fd = new FormData(form);
        const email = fd.get('email').trim(), password = fd.get('password');
        try {
          const auth = getClient().auth;
          const res = mode === 'sign-up'
            ? await auth.signUp({ email, password, options: { data: { username: fd.get('username')?.trim() || null }, emailRedirectTo: location.href } })
            : await auth.signInWithPassword({ email, password });
          if (res.error) throw res.error;
          if (!res.data.session) {
            ui.error('Check your email to confirm your account, then log in here. Your plan stays saved in this browser until then.');
            btn.disabled = false;
            return;
          }
          ui.finish({ action: 'done', user: res.data.user });
        } catch (err) {
          ui.error(friendly(err, mode));
          btn.disabled = false;
        }
      }, { capture: true });
    },
  });
  if (!result) return null;
  if (result.action === 'done') return result.user;
  if (result.action === 'forgot') return forgotPassword(result.data.get('email'));
  return openAuthDialog(result.action, reason);
}

function friendly(err, mode) {
  const m = String(err?.message ?? '');
  if (/invalid login/i.test(m)) return 'That email and password don\'t match. Try again, or reset your password.';
  if (/already registered|already exists/i.test(m)) return 'There is already an account with that email. Log in instead.';
  if (/password/i.test(m) && mode === 'sign-up') return 'Choose a password with at least 6 characters.';
  return m || 'Something went wrong. Please try again.';
}

async function forgotPassword(prefill) {
  const r = await openDialog({
    eyebrow: 'easiYESt account',
    title: 'Reset your password',
    submit: 'Send reset link',
    body: `<p class="sheet-lede">We'll email you a link to choose a new password.</p>${field('email', 'Email', { type: 'email', required: true, value: prefill ?? '', attrs: 'autocomplete="email" autofocus' })}`,
  });
  if (!r) return null;
  await getClient().auth.resetPasswordForEmail(r.data.get('email').trim(), { redirectTo: `${location.origin}/resetPassword.html` });
  await openDialog({ title: 'Check your email', body: '<p>If there is an account for that address, a reset link is on its way.</p>', submit: 'OK' });
  return null;
}

export const signOut = () => getClient().auth.signOut();
