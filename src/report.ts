export type Row = { region: string; rep: string; deals: number; revenue: number };

export const ROWS: Row[] = [
  { region: 'North', rep: 'Asha Patel', deals: 14, revenue: 182400 },
  { region: 'North', rep: 'Liam O\'Neil', deals: 9, revenue: 97250 },
  { region: 'South', rep: 'Mateo García', deals: 17, revenue: 210900 },
  { region: 'South', rep: 'Grace Kim', deals: 6, revenue: 64100 },
  { region: 'West', rep: 'Noah "Nate" Brooks', deals: 11, revenue: 133700 },
  { region: 'West', rep: 'Priya Singh', deals: 12, revenue: 149800 },
];

export function filterByRegion(rows: Row[], region: string): Row[] {
  return region === 'All' ? rows : rows.filter((r) => r.region === region);
}

export function totalRevenue(rows: Row[]): number {
  return rows.reduce((sum, r) => sum + r.revenue, 0);
}

export function formatCurrency(n: number): string {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 }).format(n);
}

function csvField(value: string | number): string {
  const s = String(value);
  return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
}

export function toCsv(rows: Row[]): string {
  const header = ['Region', 'Rep', 'Deals', 'Revenue'];
  const lines = [header.join(',')];
  for (const r of rows) {
    lines.push([r.region, r.rep, r.deals, r.revenue].map(csvField).join(','));
  }
  return lines.join('\n');
}
