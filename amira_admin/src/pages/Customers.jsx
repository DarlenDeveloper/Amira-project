import PageHeader from '../components/PageHeader.jsx';
import { EyeIcon, DotsIcon } from '../components/icons.jsx';
import { customers } from '../data/customers.js';
import { money } from '../utils.js';

const initials = (name) =>
  name.split(' ').slice(0, 2).map((n) => n[0]).join('').toUpperCase();

export default function Customers() {
  const totalSpent = customers.reduce((s, c) => s + c.spent, 0);

  return (
    <div className="page">
      <PageHeader
        eyebrow="People"
        title="Customers"
        subtitle={`${customers.length} customers · ${money(totalSpent)} lifetime value`}
      />

      <div className="table-card">
        <table className="data-table">
          <thead>
            <tr>
              <th>Customer</th>
              <th>Phone</th>
              <th>Location</th>
              <th className="num">Orders</th>
              <th className="num">Spent</th>
              <th>Joined</th>
              <th className="right">Actions</th>
            </tr>
          </thead>
          <tbody>
            {customers.map((c) => (
              <tr key={c.email}>
                <td>
                  <div className="product-cell">
                    <span className="avatar">{initials(c.name)}</span>
                    <div>
                      <div className="cell-strong">{c.name}</div>
                      <div className="cell-sub">{c.email}</div>
                    </div>
                  </div>
                </td>
                <td className="cell-muted">{c.phone}</td>
                <td className="cell-muted">{c.location}</td>
                <td className="num">{c.orders}</td>
                <td className="num serif-num">{money(c.spent)}</td>
                <td className="cell-muted">{c.joined}</td>
                <td className="right">
                  <div className="row-actions">
                    <button className="icon-btn" aria-label="View customer"><EyeIcon /></button>
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
