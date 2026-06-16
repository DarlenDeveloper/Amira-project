export const money = (n) =>
  '$' + Number(n).toLocaleString('en-US', { maximumFractionDigits: 0 });

export const titleCase = (s) => s.charAt(0).toUpperCase() + s.slice(1);
