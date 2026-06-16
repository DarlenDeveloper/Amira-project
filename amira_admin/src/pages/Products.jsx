import { useMemo, useState } from 'react';
import PageHeader from '../components/PageHeader.jsx';
import FilterPills from '../components/FilterPills.jsx';
import StatusBadge from '../components/StatusBadge.jsx';
import { EyeIcon, DotsIcon } from '../components/icons.jsx';
import { products, productCategories } from '../data/products.js';
import { money } from '../utils.js';

const STATUS_LABEL = { active: 'In stock', low: 'Low stock', out: 'Out of stock' };

export default function Products() {
  const [filter, setFilter] = useState('all');

  const counts = useMemo(() => {
    const c = {};
    for (const cat of productCategories) c[cat] = products.filter((p) => p.category === cat).length;
    return c;
  }, []);

  const rows = filter === 'all' ? products : products.filter((p) => p.category === filter);

  const options = [
    { value: 'all', label: 'All' },
    ...productCategories.map((cat) => ({ value: cat, label: cat, count: counts[cat] })),
  ];

  return (
    <div className="page">
      <PageHeader
        eyebrow="Catalogue"
        title="Products"
        subtitle={`${products.length} materials across ${productCategories.length} categories`}
        action={<button className="primary-btn">+ New product</button>}
      />

      <FilterPills options={options} active={filter} onChange={setFilter} />

      <div className="table-card">
        <table className="data-table">
          <thead>
            <tr>
              <th>Product</th>
              <th>Category</th>
              <th className="num">Price</th>
              <th className="num">Stock</th>
              <th>Status</th>
              <th className="right">Actions</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((p) => (
              <tr key={p.name}>
                <td>
                  <div className="product-cell">
                    <img className="product-thumb" src={p.image} alt={p.name} loading="lazy" />
                    <span className="cell-strong">{p.name}</span>
                  </div>
                </td>
                <td className="cell-muted">{p.category}</td>
                <td className="num serif-num">{money(p.value)}<span className="unit"> /{p.unit}</span></td>
                <td className="num">{p.stock}</td>
                <td><StatusBadge status={p.status} label={STATUS_LABEL[p.status]} /></td>
                <td className="right">
                  <div className="row-actions">
                    <button className="icon-btn" aria-label="View product"><EyeIcon /></button>
                    <button className="icon-btn" aria-label="More"><DotsIcon /></button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
