import { useEffect, useMemo, useRef, useState } from 'react';
import { useShop } from '../context/ShopContext.jsx';

// Local fallback slides — real interior room shots, used when the live
// portfolio has fewer than two published images. The carousel slides
// horizontally (swipe), not a fade.
const FALLBACK = [
  '/images/hero/hero-1.jpg',
  '/images/hero/hero-2.jpg',
  '/images/hero/hero-3.jpg',
  '/images/hero/hero-4.jpg',
  '/images/hero/hero-5.jpg',
  '/images/hero/hero-6.jpg',
];
const INTERVAL = 5000; // ms between slides
const SWIPE_THRESHOLD = 60; // px drag needed to change slide

// Full-width hero with a horizontally-swiping background carousel. Images come
// from the live published portfolio (admin-managed) when there are 2+; otherwise
// the local room shots above. Auto-advances, loops seamlessly, and supports
// drag / touch swiping.
export default function HeroSection() {
  const { heroImages } = useShop();

  const slides = useMemo(
    () => (heroImages && heroImages.length >= 2 ? heroImages : FALLBACK),
    [heroImages],
  );

  // A clone of the first slide is appended so we can advance past the last one
  // and snap back without a visible "rewind".
  const track = useMemo(() => [...slides, slides[0]], [slides]);

  const [index, setIndex] = useState(0);
  const [animate, setAnimate] = useState(true);
  const [drag, setDrag] = useState(0); // live drag offset in px
  const dragState = useRef(null);

  // Reset when the slide set changes.
  useEffect(() => {
    setIndex(0);
    setAnimate(true);
  }, [slides.length]);

  // Auto-advance.
  useEffect(() => {
    if (slides.length < 2) return undefined;
    const id = window.setInterval(() => goTo((i) => i + 1), INTERVAL);
    return () => window.clearInterval(id);
  }, [slides.length]);

  const goTo = (next) => {
    setAnimate(true);
    setIndex((i) => (typeof next === 'function' ? next(i) : next));
  };

  // Seamless loop: after sliding onto the cloned first slide, jump back to the
  // real first slide with animation off so the eye doesn't catch it.
  const handleTransitionEnd = () => {
    if (index === slides.length) {
      setAnimate(false);
      setIndex(0);
    }
  };

  // ── Drag / touch swipe ──────────────────────────────────────────────────────
  const onPointerDown = (e) => {
    dragState.current = { startX: e.clientX };
    setAnimate(false);
  };
  const onPointerMove = (e) => {
    if (!dragState.current) return;
    setDrag(e.clientX - dragState.current.startX);
  };
  const onPointerUp = () => {
    if (!dragState.current) return;
    const dx = drag;
    dragState.current = null;
    setDrag(0);
    setAnimate(true);
    if (dx <= -SWIPE_THRESHOLD) goTo((i) => i + 1);
    else if (dx >= SWIPE_THRESHOLD) goTo((i) => (i <= 0 ? slides.length - 1 : i - 1));
  };

  const activeDot = index % slides.length;
  const offset = `calc(${-index * 100}% + ${drag}px)`;

  return (
    <section className="hero" aria-label="Amira Interiors">
      <div
        className="hero-viewport"
        onPointerDown={onPointerDown}
        onPointerMove={onPointerMove}
        onPointerUp={onPointerUp}
        onPointerLeave={onPointerUp}
      >
        <div
          className={`hero-track${animate ? ' hero-track--animate' : ''}`}
          style={{ transform: `translate3d(${offset}, 0, 0)` }}
          onTransitionEnd={handleTransitionEnd}
        >
          {track.map((src, i) => (
            <div
              key={i}
              className="hero-slide"
              style={{ backgroundImage: `url(${src})` }}
              aria-hidden="true"
            />
          ))}
        </div>
      </div>

      <div className="hero-scrim" />

      <div className="hero-content">
        <span className="hero-eyebrow">AMIRA INTERIORS</span>
        <h1 className="hero-headline">
          Explore finishes<br />crafted for refined living
        </h1>
        <p className="hero-sub">
          Wall panels, marble, stone, lighting and more — curated textures and
          materials that turn a space into an experience.
        </p>
        <a className="hero-cta" href="#explore-grid">
          Browse the collection
        </a>
      </div>

      {slides.length > 1 && (
        <div className="hero-dots" role="tablist" aria-label="Hero slides">
          {slides.map((_, i) => (
            <button
              key={i}
              type="button"
              role="tab"
              aria-selected={i === activeDot}
              aria-label={`Show slide ${i + 1}`}
              className={`hero-dot${i === activeDot ? ' hero-dot--active' : ''}`}
              onClick={() => goTo(i)}
            />
          ))}
        </div>
      )}
    </section>
  );
}
