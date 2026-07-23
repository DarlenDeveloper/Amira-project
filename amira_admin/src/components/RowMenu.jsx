import { useEffect, useLayoutEffect, useRef, useState } from 'react';
import { createPortal } from 'react-dom';
import { DotsIcon } from './icons.jsx';

// Small "..." dropdown with Edit / Delete actions for a table/grid row.
//
// The popover is rendered in a portal with fixed positioning so it's never
// clipped by an ancestor's `overflow` (the table card and the scroll wrapper
// both clip their content). It aligns its right edge to the trigger button and
// closes on outside-click, scroll, resize, or Escape.
export default function RowMenu({ onEdit, onDelete }) {
  const [open, setOpen] = useState(false);
  const [style, setStyle] = useState(null);
  const btnRef = useRef(null);
  const popRef = useRef(null);

  // Position the popover under the button, right-aligned, once it's rendered.
  useLayoutEffect(() => {
    if (!open || !btnRef.current) return;
    const r = btnRef.current.getBoundingClientRect();
    const width = popRef.current?.offsetWidth || 150;
    setStyle({
      position: 'fixed',
      top: Math.round(r.bottom + 6),
      left: Math.round(r.right - width),
      right: 'auto',
    });
  }, [open]);

  useEffect(() => {
    if (!open) return undefined;
    const onDown = (e) => {
      if (
        btnRef.current && !btnRef.current.contains(e.target) &&
        popRef.current && !popRef.current.contains(e.target)
      ) {
        setOpen(false);
      }
    };
    const onDismiss = () => setOpen(false);
    const onKey = (e) => {
      if (e.key === 'Escape') setOpen(false);
    };
    document.addEventListener('mousedown', onDown);
    // capture=true so we catch scrolls on any nested scroll container.
    window.addEventListener('scroll', onDismiss, true);
    window.addEventListener('resize', onDismiss);
    document.addEventListener('keydown', onKey);
    return () => {
      document.removeEventListener('mousedown', onDown);
      window.removeEventListener('scroll', onDismiss, true);
      window.removeEventListener('resize', onDismiss);
      document.removeEventListener('keydown', onKey);
    };
  }, [open]);

  return (
    <div className="row-menu">
      <button
        ref={btnRef}
        type="button"
        className="icon-btn"
        aria-label="More"
        aria-haspopup="menu"
        aria-expanded={open}
        onClick={() => setOpen((v) => !v)}
      >
        <DotsIcon />
      </button>
      {open &&
        createPortal(
          <div
            ref={popRef}
            className="row-menu-pop"
            role="menu"
            style={style || { position: 'fixed', visibility: 'hidden' }}
          >
            <button
              type="button"
              className="row-menu-item"
              role="menuitem"
              onClick={() => {
                setOpen(false);
                onEdit();
              }}
            >
              Edit
            </button>
            <button
              type="button"
              className="row-menu-item row-menu-item--danger"
              role="menuitem"
              onClick={() => {
                setOpen(false);
                onDelete();
              }}
            >
              Delete
            </button>
          </div>,
          document.body,
        )}
    </div>
  );
}
