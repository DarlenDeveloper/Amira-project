import { useMemo, useState } from 'react';
import PageHeader from '../components/PageHeader.jsx';
import FilterPills from '../components/FilterPills.jsx';
import StatusBadge from '../components/StatusBadge.jsx';
import Thumb from '../components/Thumb.jsx';
import RowMenu from '../components/RowMenu.jsx';
import ProductForm from '../components/ProductForm.jsx';
import ConfirmDialog from '../components/ConfirmDialog.jsx';
import { EyeIcon } from '../components/icons.jsx';
import { useCollection, deleteDocById } from '../db.js';
import { money } from '../utils.js';

const STATUS_LABEL = { active: 'In stock', low: 'Low stock', out: 'Out of stock' };

export default function Products() {
  const [filter, setFilter] = useState('all');
  const { data: products } = useCollection('products');

  // editing: undefined = closed, null = new, object = edit. deleting = product|null.
  const [editing, setEditing] = useState(undefined);
  const [deleting, setDeleting] = useState(null);

  const categories = useMemo(
    () => [...new Set(products.map((p) => p.category).filter(Boolean))],
    [products],
  );

  const counts = useMemo(() => {
    const c = {};
    for (const cat of categories) c[cat] = products.filter((p) => p.category === cat).length;
    return c;
  }, [products, categories]);

  const rows = filter === 'all' ? products : products.filter((p) => p.category === filter);

  const options = [
    { value: 'all', label: 'All' },
    ...categories.map((cat) => ({ value: cat, label: cat, count: counts[cat] })),
  ];

  return (
    <div className="page">
      <PageHeader
        eyebrow="Catalogue"
        title="Products"
        subtitle={`${products.length} materials across ${categories.length} categories`}
        action={
          <button className="primary-btn" onClick={() => setEditing(null)}>
            + New product
          </button>
        }
      />

      <FilterPills options={options} active={filter} onChange={setFilter} />

      <div className="table-card">
        <table className="data-table">
          <thead>
            <tr>
              <th>Product</th>
              <th>Category</th>
              <th>Tag</th>
              <th className="num">Price</th>
              <th className="num">Stock</th>
              <th>Status</th>
              <th className="right">Actions</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((p) => (
              <tr key={p.id}>
                <td>
                  <div className="product-cell">
                    <Thumb className="product-thumb" src={p.imageUrl} alt={p.name} />
                    <span className="cell-strong">{p.name}</span>
                  </div>
                </td>
                <td className="cell-muted">{p.category}</td>
                <td>{p.badge ? <span className="tag-pill">{p.badge}</span> : <span className="cell-muted">—</span>}</td>
                <td className="num serif-num">{money(p.value)}<span className="unit"> /{p.unit}</span></td>
                <td className="num">{p.stock}</td>
                <td><StatusBadge status={p.status} label={STATUS_LABEL[p.status]} /></td>
                <td className="right">
                  <div className="row-actions">
                    <button className="icon-btn" aria-label="Edit product" onClick={() => setEditing(p)}>
                      <EyeIcon />
                    </button>
                    <RowMenu onEdit={() => setEditing(p)} onDelete={() => setDeleting(p)} />
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {editing !== undefined && (
        <ProductForm
          initial={editing}
          categories={categories}
          onClose={() => setEditing(undefined)}
          onSaved={() => setEditing(undefined)}
        />
      )}

      {deleting && (
        <ConfirmDialog
          title="Delete product"
          message={`Delete "${deleting.name}"? This can't be undone.`}
          onCancel={() => setDeleting(null)}
          onConfirm={async () => {
            await deleteDocById('products', deleting.id);
            setDeleting(null);
          }}
        />
      )}
    </div>
  );
}
