import { useMemo, useState } from 'react';
import PageHeader from '../components/PageHeader.jsx';
import FilterPills from '../components/FilterPills.jsx';
import StatusBadge from '../components/StatusBadge.jsx';
import Thumb from '../components/Thumb.jsx';
import { EyeIcon, DotsIcon } from '../components/icons.jsx';
import { useCollection } from '../db.js';
import { titleCase } from '../utils.js';

const PORTFOLIO_STATUSES = ['published', 'draft', 'concept'];

export default function Portfolio() {
  const [filter, setFilter] = useState('all');
  const { data: portfolio } = useCollection('portfolio');

  const counts = useMemo(() => {
    const c = {};
    for (const s of PORTFOLIO_STATUSES) c[s] = portfolio.filter((p) => p.status === s).length;
    return c;
  }, [portfolio]);

  const rows = filter === 'all' ? portfolio : portfolio.filter((p) => p.status === filter);

  const options = [
    { value: 'all', label: 'All' },
    ...PORTFOLIO_STATUSES.map((s) => ({ value: s, label: titleCase(s), count: counts[s] })),
  ];

  return (
    <div className="page">
      <PageHeader
        eyebrow="Showcase"
        title="Our Portfolio"
        subtitle={`${portfolio.length} interior projects`}
        action={<button className="primary-btn">+ New project</button>}
      />

      <FilterPills options={options} active={filter} onChange={setFilter} />

      <div className="portfolio-grid">
        {rows.map((p) => (
          <article className="portfolio-card" key={p.id}>
            <div className="portfolio-media">
              <Thumb src={p.imageUrl} alt={p.title} />
              <div className="portfolio-status"><StatusBadge status={p.status} /></div>
              <div className="portfolio-actions">
                <button className="round-btn" aria-label="View project"><EyeIcon /></button>
                <button className="round-btn" aria-label="More"><DotsIcon /></button>
              </div>
            </div>
            <div className="portfolio-body">
              <div className="portfolio-row">
                <h3 className="portfolio-title">{p.title}</h3>
                <span className="portfolio-room">{p.room}</span>
              </div>
              <div className="portfolio-meta">
                <span>{p.location}</span>
                <span className="dot-sep">·</span>
                <span>{p.size}</span>
              </div>
              <p className="portfolio-price">{p.productName}</p>
            </div>
          </article>
        ))}
      </div>
    </div>
  );
}
