// Simple, reusable pager for table pages. Renders nothing when there's only a
// single page so short lists stay clean.
export default function Pagination({ page, totalPages, totalItems, pageSize, onChange }) {
  if (totalPages <= 1) return null;

  const first = (page - 1) * pageSize + 1;
  const last = Math.min(page * pageSize, totalItems);

  return (
    <div className="pagination">
      <span className="pagination-info">
        {first}–{last} of {totalItems}
      </span>
      <div className="pagination-controls">
        <button
          type="button"
          className="page-btn"
          disabled={page <= 1}
          onClick={() => onChange(page - 1)}
        >
          Previous
        </button>
        <span className="page-current">
          Page {page} of {totalPages}
        </span>
        <button
          type="button"
          className="page-btn"
          disabled={page >= totalPages}
          onClick={() => onChange(page + 1)}
        >
          Next
        </button>
      </div>
    </div>
  );
}
