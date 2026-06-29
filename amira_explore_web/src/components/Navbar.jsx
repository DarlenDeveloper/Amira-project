import { useState } from 'react';

// Brand top navbar, overlaid on the hero — mirrors the Amira marketing site:
// a slim utility row (contact + language), the AMIRA logo, centered nav links,
// and a "Shop" call-to-action.
//
// Home and Shop scroll within the single-page shop. About / Services /
// Portfolio / Contact are brand links whose destinations live on the marketing
// site — wire their hrefs once those URLs are confirmed.
const NAV_LINKS = ['Home', 'Shop', 'About', 'Services', 'Portfolio', 'Contact'];

export default function Navbar() {
  const [active, setActive] = useState('Home');

  const scrollToTop = () =>
    window.scrollTo({ top: 0, behavior: 'smooth' });

  const scrollToShop = () => {
    const grid = document.getElementById('explore-grid');
    if (grid) grid.scrollIntoView({ behavior: 'smooth', block: 'start' });
    else scrollToTop();
  };

  const onLink = (label) => (e) => {
    e.preventDefault();
    setActive(label);
    if (label === 'Home') scrollToTop();
    else if (label === 'Shop') scrollToShop();
    // Other links: brand pages on the marketing site (wire when available).
  };

  return (
    <header className="site-nav">
      <div className="site-nav-top">
        <span className="site-nav-contact">Contact</span>
        <span className="site-nav-lang">🌐 English</span>
      </div>

      <div className="site-nav-main">
        <button
          type="button"
          className="site-nav-logo"
          onClick={scrollToTop}
          aria-label="Amira Interior Hub — home"
        >
          <img src="/images/amira-logo.png" alt="Amira Interior Hub" />
        </button>

        <nav className="site-nav-links" aria-label="Primary">
          {NAV_LINKS.map((label) => (
            <a
              key={label}
              href="#"
              className={`site-nav-link${active === label ? ' site-nav-link--active' : ''}`}
              onClick={onLink(label)}
            >
              {label}
            </a>
          ))}
        </nav>

        <button type="button" className="site-nav-cta" onClick={scrollToShop}>
          Shop
        </button>
      </div>
    </header>
  );
}
