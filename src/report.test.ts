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

  describe('toCsv', () => {
    it('includes a header row followed by the given rows only', () => {
      const rows = filterByRegion(ROWS, 'West');
      const lines = toCsv(rows).split('\n');
      expect(lines[0]).toBe('Region,Rep,Deals,Revenue');
      expect(lines).toHaveLength(rows.length + 1);
    });

    it('escapes commas by quoting the field', () => {
      const csv = toCsv([{ region: 'North', rep: 'Doe, Jane', deals: 1, revenue: 100 }]);
      expect(csv.split('\n')[1]).toBe('North,"Doe, Jane",1,100');
    });

    it('escapes double quotes by doubling them and quoting the field', () => {
      const csv = toCsv([{ region: 'West', rep: 'Noah "Nate" Brooks', deals: 11, revenue: 133700 }]);
      expect(csv.split('\n')[1]).toBe('West,"Noah ""Nate"" Brooks",11,133700');
    });

    it('leaves apostrophes as-is without quoting', () => {
      const csv = toCsv([{ region: 'North', rep: "Liam O'Neil", deals: 9, revenue: 97250 }]);
      expect(csv.split('\n')[1]).toBe("North,Liam O'Neil,9,97250");
    });

    it('handles an empty row list with just a header', () => {
      expect(toCsv([])).toBe('Region,Rep,Deals,Revenue');
    });
  });
});
