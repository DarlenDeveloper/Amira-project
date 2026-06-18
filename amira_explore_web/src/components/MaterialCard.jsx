import { useShop } from '../context/ShopContext.jsx';

// Single material tile: image with badge + heart overlay, then title + price
// below. The heart is backed by the user's favourites in Firestore.
export default function MaterialCard({ data, onOpen }) {
  const { favourites, toggleFavourite } = useShop();
  const favorite = favourites.has(data.id);

  return (
    <article className="material-card" onClick={onOpen}>
      <div className="card-image-wrap">
        <img className="card-image" src={data.image} alt={data.name} loading="lazy" />

        {data.badge && <span className="card-badge">{data.badge}</span>}
        {data.outOfStock && <span className="card-soldout">Sold out</span>}

        <button
          type="button"
          className="card-heart"
          aria-label={favorite ? 'Remove from favourites' : 'Add to favourites'}
          aria-pressed={favorite}
          onClick={(e) => {
            e.stopPropagation();
            toggleFavourite(data.id);
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
