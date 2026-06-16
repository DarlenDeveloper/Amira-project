import { useState } from 'react';

// Single material tile: image with badge + heart overlay, then title + price
// below — mirroring the Flutter `_MaterialCard`.
export default function MaterialCard({ data, onOpen }) {
  const [favorite, setFavorite] = useState(false);

  return (
    <article className="material-card" onClick={onOpen}>
      <div className="card-image-wrap">
        <img className="card-image" src={data.image} alt={data.name} loading="lazy" />

        {data.badge && <span className="card-badge">{data.badge}</span>}

        <button
          type="button"
          className="card-heart"
          aria-label={favorite ? 'Remove from favourites' : 'Add to favourites'}
          aria-pressed={favorite}
          onClick={(e) => {
            e.stopPropagation();
            setFavorite((v) => !v);
          }}
        >
          <HeartIcon filled={favorite} />
        </button>
      </div>

      <h3 className="card-title">{data.name}</h3>
      <p className="card-price">{data.price}</p>
    </article>
  );
}

function HeartIcon({ filled }) {
  return (
    <svg
      width="19"
      height="19"
      viewBox="0 0 24 24"
      fill={filled ? 'currentColor' : 'none'}
      stroke="currentColor"
      strokeWidth="1.8"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
    </svg>
  );
}
