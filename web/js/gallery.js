// Arrow buttons for the photo strip on vendor pages. Swiping still works;
// the arrows are for computers, where a sideways scroll is easy to miss.

/** Where the strip should scroll to for one step in `dir` (1 or -1). */
export function scrollTarget({ scrollLeft, clientWidth, scrollWidth, itemWidth }, dir) {
  const max = scrollWidth - clientWidth;
  const index = dir > 0 ? Math.floor(scrollLeft / itemWidth + 0.01) + 1 : Math.ceil(scrollLeft / itemWidth - 0.01) - 1;
  return Math.min(max, Math.max(0, index * itemWidth));
}

/** Whether the strip is at its start or end, allowing for fractional pixels. */
export function atEnds({ scrollLeft, clientWidth, scrollWidth }) {
  return { start: scrollLeft <= 1, end: scrollLeft >= scrollWidth - clientWidth - 1 };
}

function wire(gallery) {
  const track = gallery.querySelector('.gallery-track');
  const prev = gallery.querySelector('[data-gallery-prev]');
  const next = gallery.querySelector('[data-gallery-next]');
  if (!track || !prev || !next) return;
  const measure = () => ({
    scrollLeft: track.scrollLeft, clientWidth: track.clientWidth, scrollWidth: track.scrollWidth,
    itemWidth: track.firstElementChild?.getBoundingClientRect().width || track.clientWidth,
  });
  const update = () => {
    const ends = atEnds(measure());
    prev.disabled = ends.start;
    next.disabled = ends.end;
  };
  const go = dir => track.scrollTo({ left: scrollTarget(measure(), dir), behavior: 'smooth' });
  prev.addEventListener('click', () => go(-1));
  next.addEventListener('click', () => go(1));
  track.addEventListener('scroll', update, { passive: true });
  addEventListener('resize', update);
  update();
}

/** Where a clicked photo sits in the full list, so the viewer opens on it. */
export function startIndex(srcs, src) {
  const i = srcs.indexOf(src);
  return i < 0 ? 0 : i;
}

const ARROW = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" aria-hidden="true"><path d="M15 5l-7 7 7 7"/></svg>';

// Click any vendor photo to see every photo full screen. Swipe on a phone,
// arrows or the keyboard on a computer; Esc or the X closes it.
function lightbox(srcs, alt) {
  const dlg = document.createElement('dialog');
  dlg.className = 'lightbox';
  dlg.setAttribute('aria-label', 'Photos');
  dlg.innerHTML = `<div class="lightbox-track">${srcs.map((s, i) => `<div class="lightbox-slide"><img src="${s.replace(/"/g, '&quot;')}" alt="${alt(i)}" loading="lazy" decoding="async"></div>`).join('')}</div>
    <span class="lightbox-count" aria-live="polite"></span>
    <button type="button" class="lightbox-close" aria-label="Close photos">&times;</button>
    ${srcs.length > 1 ? `<button type="button" class="gallery-btn gallery-prev" aria-label="Previous photo">${ARROW}</button>
    <button type="button" class="gallery-btn gallery-next" aria-label="Next photo">${ARROW}</button>` : ''}`;
  document.body.append(dlg);
  const track = dlg.querySelector('.lightbox-track');
  const count = dlg.querySelector('.lightbox-count');
  const prev = dlg.querySelector('.gallery-prev');
  const next = dlg.querySelector('.gallery-next');
  const current = () => Math.round(track.scrollLeft / (track.clientWidth || 1));
  const update = () => {
    const i = current();
    count.textContent = srcs.length > 1 ? `${i + 1} / ${srcs.length}` : '';
    if (prev) prev.disabled = i <= 0;
    if (next) next.disabled = i >= srcs.length - 1;
  };
  // Where the viewer is headed, so quick repeated presses each count even
  // while the previous slide is still animating.
  let at = 0;
  const show = (i, smooth = true) => {
    at = Math.min(srcs.length - 1, Math.max(0, i));
    track.scrollTo({ left: at * track.clientWidth, behavior: smooth ? 'smooth' : 'instant' });
  };
  prev?.addEventListener('click', () => show(at - 1));
  next?.addEventListener('click', () => show(at + 1));
  dlg.querySelector('.lightbox-close').addEventListener('click', () => dlg.close());
  // A click on the dark space around a photo closes it too.
  dlg.addEventListener('click', e => { if (e.target.classList.contains('lightbox-slide')) dlg.close(); });
  dlg.addEventListener('keydown', e => {
    if (e.key === 'ArrowRight') { e.preventDefault(); show(at + 1); }
    if (e.key === 'ArrowLeft') { e.preventDefault(); show(at - 1); }
  });
  dlg.addEventListener('close', () => { document.documentElement.style.overflow = ''; });
  track.addEventListener('scroll', update, { passive: true });
  // After a swipe, pick up from wherever the finger left it.
  track.addEventListener('scrollend', () => { at = current(); });
  addEventListener('resize', () => { if (dlg.open) show(at, false); });
  return i => {
    document.documentElement.style.overflow = 'hidden';
    dlg.showModal();
    show(i, false);
    update();
  };
}

function wireLightbox() {
  const strip = [...document.querySelectorAll('.gallery-track img')];
  if (!strip.length) return;
  const srcs = strip.map(img => img.getAttribute('src'));
  const open = lightbox(srcs, i => strip[i].alt.replace(/"/g, '&quot;'));
  const photos = [...strip, ...document.querySelectorAll('.mosaic-img')];
  photos.forEach(img => {
    img.tabIndex = 0;
    img.setAttribute('role', 'button');
    const go = () => open(startIndex(srcs, img.getAttribute('src')));
    img.addEventListener('click', go);
    img.addEventListener('keydown', e => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); go(); } });
  });
}

if (typeof document !== 'undefined') {
  document.querySelectorAll('.gallery').forEach(wire);
  wireLightbox();
}
