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
    it('starts with a header row', () => {
      const lines = toCsv([]).split('\r\n');
      expect(lines[0]).toBe('Region,Rep,Deals,Revenue');
    });

    it('includes only the rows it is given', () => {
      const rows = filterByRegion(ROWS, 'North');
      const lines = toCsv(rows).split('\r\n');
      // header + one line per row
      expect(lines).toHaveLength(rows.length + 1);
      expect(lines[1]).toBe('North,Asha Patel,14,182400');
    });

    it('preserves apostrophes without mangling them', () => {
      const csv = toCsv([{ region: 'North', rep: "Liam O'Neil", deals: 9, revenue: 97250 }]);
      expect(csv).toBe('Region,Rep,Deals,Revenue\r\nNorth,Liam O\'Neil,9,97250');
    });

    it('quotes and escapes fields containing commas', () => {
      const csv = toCsv([{ region: 'North', rep: 'Smith, Jane', deals: 1, revenue: 10 }]);
      expect(csv).toBe('Region,Rep,Deals,Revenue\r\nNorth,"Smith, Jane",1,10');
    });

    it('doubles quotes inside quoted fields', () => {
      const csv = toCsv([{ region: 'West', rep: 'Noah "Nate" Brooks', deals: 11, revenue: 133700 }]);
      expect(csv).toBe('Region,Rep,Deals,Revenue\r\nWest,"Noah ""Nate"" Brooks",11,133700');
    });

    it('quotes fields containing newlines', () => {
      const csv = toCsv([{ region: 'North\nSouth', rep: 'Jo', deals: 1, revenue: 10 }]);
      expect(csv).toBe('Region,Rep,Deals,Revenue\r\n"North\nSouth",Jo,1,10');
    });
  });
});
