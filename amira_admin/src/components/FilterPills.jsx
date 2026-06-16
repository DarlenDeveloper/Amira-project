// Row of filter pills (ALL + per-status counts), as in the Orders mock.
export default function FilterPills({ options, active, onChange }) {
  return (
    <div className="filter-pills">
      {options.map((opt) => (
        <button
          key={opt.value}
          type="button"
          className={`pill${active === opt.value ? ' pill--active' : ''}`}
          onClick={() => onChange(opt.value)}
        >
          {opt.label}
          {opt.count != null && <span className="pill-count"> · {opt.count}</span>}
        </button>
      ))}
    </div>
  );
}
