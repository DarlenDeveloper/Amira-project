// Full-width hero banner that opens the Explore page — warm, immersive, on-brand.
export default function HeroSection() {
  return (
    <section className="hero" aria-label="Amira Interiors">
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
    </section>
  );
}
