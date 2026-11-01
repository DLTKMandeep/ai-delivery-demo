import { useState } from 'react';
import { ROWS, filterByRegion, formatCurrency, totalRevenue } from './report';

const REGIONS = ['All', 'North', 'South', 'West'];

export default function App() {
  const [region, setRegion] = useState('All');
  const rows = filterByRegion(ROWS, region);

  return (
    <main className="page">
      <header className="head">
        <div>
          <h1>Regional sales report</h1>
          <p className="lede">Closed deals this quarter, by sales rep.</p>
        </div>
        <div className="total">
          <span className="total-num">{formatCurrency(totalRevenue(rows))}</span>
          <span className="total-label">total revenue</span>
        </div>
      </header>

      <div className="controls" role="group" aria-label="Filter by region">
        {REGIONS.map((r) => (
          <button key={r} className={r === region ? 'chip on' : 'chip'} aria-pressed={r === region} onClick={() => setRegion(r)}>
            {r}
          </button>
        ))}
      </div>

      <table className="table">
        <thead>
          <tr><th>Region</th><th>Rep</th><th className="num">Deals</th><th className="num">Revenue</th></tr>
        </thead>
        <tbody>
          {rows.map((r) => (
            <tr key={r.rep}>
              <td>{r.region}</td><td>{r.rep}</td><td className="num">{r.deals}</td><td className="num">{formatCurrency(r.revenue)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </main>
  );
}
