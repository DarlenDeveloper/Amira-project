// Renders an image, or a neutral "no image" placeholder when there's no src.
// Used for products/portfolio whose images come from the backend (imageUrl).
export default function Thumb({ src, alt, className }) {
  if (src) {
    return <img className={className} src={src} alt={alt} loading="lazy" />;
  }
  return (
    <div
      className={className}
      style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        background: '#EDEDE8',
        color: '#9A9A94',
        fontSize: 11,
        minHeight: '100%',
        textAlign: 'center',
      }}
    >
      No image
    </div>
  );
}
