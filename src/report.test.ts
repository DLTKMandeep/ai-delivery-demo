import { describe, expect, it } from 'vitest';
import { ROWS, filterByRegion, formatCurrency, toCsv, totalRevenue } from './report';

describe('report', () => {
  it('returns every row for All', () => {
    expect(filterByRegion(ROWS, 'All')).toHaveLength(ROWS.length);
  });

  it('filters by region', () => {
    expect(filterByRegion(ROWS, 'West').every((r) => r.region === 'West')).toBe(true);
  });

  it('sums revenue', () => {
    expect(totalRevenue(filterByRegion(ROWS, 'North'))).toBe(279650);
  });

  it('formats currency without cents', () => {
    expect(formatCurrency(1234.5)).toBe('$1,235');
  });
});

describe('toCsv', () => {
  it('starts with a header row', () => {
    const csv = toCsv([]);
    expect(csv).toBe('Region,Rep,Deals,Revenue');
  });

  it('includes a line per row after the header', () => {
    const rows = filterByRegion(ROWS, 'North');
    const lines = toCsv(rows).split('\n');
    expect(lines[0]).toBe('Region,Rep,Deals,Revenue');
    expect(lines).toHaveLength(rows.length + 1);
  });

  it('writes plain fields unquoted', () => {
    const csv = toCsv([{ region: 'North', rep: 'Asha Patel', deals: 14, revenue: 182400 }]);
    expect(csv.split('\n')[1]).toBe('North,Asha Patel,14,182400');
  });

  it('leaves apostrophes untouched', () => {
    const csv = toCsv([{ region: 'North', rep: "Liam O'Neil", deals: 9, revenue: 97250 }]);
    expect(csv.split('\n')[1]).toBe("North,Liam O'Neil,9,97250");
  });

  it('quotes and doubles embedded double quotes', () => {
    const csv = toCsv([{ region: 'West', rep: 'Noah "Nate" Brooks', deals: 11, revenue: 133700 }]);
    expect(csv.split('\n')[1]).toBe('West,"Noah ""Nate"" Brooks",11,133700');
  });

  it('quotes fields containing commas', () => {
    const csv = toCsv([{ region: 'South', rep: 'García, Mateo', deals: 17, revenue: 210900 }]);
    expect(csv.split('\n')[1]).toBe('South,"García, Mateo",17,210900');
  });

  it('quotes fields containing newlines', () => {
    const csv = toCsv([{ region: 'North', rep: 'Line1\nLine2', deals: 1, revenue: 10 }]);
    expect(csv.split('\n')[0]).toBe('Region,Rep,Deals,Revenue');
    expect(csv).toContain('"Line1\nLine2"');
  });

  it('exports only the rows it is given', () => {
    const rows = filterByRegion(ROWS, 'West');
    const csv = toCsv(rows);
    expect(csv).not.toContain('Asha Patel');
    expect(csv).toContain('Priya Singh');
  });
});
