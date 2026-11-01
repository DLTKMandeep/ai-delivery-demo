import { describe, expect, it } from 'vitest';
import { ROWS, filterByRegion, formatCurrency, totalRevenue } from './report';

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
