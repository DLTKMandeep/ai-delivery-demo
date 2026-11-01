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

  it('writes a header row and the given rows only', () => {
    const csv = toCsv(filterByRegion(ROWS, 'North'));
    const lines = csv.split('\n');
    expect(lines[0]).toBe('Region,Rep,Deals,Revenue');
    expect(lines).toHaveLength(3);
    expect(lines[1]).toBe('North,Asha Patel,14,182400');
  });

  it('leaves apostrophes untouched', () => {
    const csv = toCsv([{ region: 'North', rep: "Liam O'Neil", deals: 9, revenue: 97250 }]);
    expect(csv.split('\n')[1]).toBe("North,Liam O'Neil,9,97250");
  });

  it('quotes and escapes fields containing commas and double quotes', () => {
    const csv = toCsv([{ region: 'West', rep: 'Noah "Nate" Brooks, Jr.', deals: 11, revenue: 133700 }]);
    expect(csv.split('\n')[1]).toBe('West,"Noah ""Nate"" Brooks, Jr.",11,133700');
  });

  it('quotes fields containing newlines', () => {
    const csv = toCsv([{ region: 'East\nville', rep: 'Sam', deals: 1, revenue: 100 }]);
    expect(csv).toBe('Region,Rep,Deals,Revenue\n"East\nville",Sam,1,100');
  });
});
