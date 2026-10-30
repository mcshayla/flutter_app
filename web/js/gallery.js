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

if (typeof document !== 'undefined') document.querySelectorAll('.gallery').forEach(wire);
