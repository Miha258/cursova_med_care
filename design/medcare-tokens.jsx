/* MedCare CRM — shared tokens & helpers */
const C = {
  primary: '#1565C0',
  primaryDark: '#0D47A1',
  primaryLight: '#1E88E5',
  accent: '#FFC107',
  bg: '#F5F7FA',
  white: '#FFFFFF',
  card: '#FFFFFF',
  text: '#1A1A2E',
  textSec: '#6B7280',
  danger: '#EF4444',
  success: '#22C55E',
  warning: '#F59E0B',
  border: '#E5E7EB',
};

const FONT = "'Nunito', -apple-system, sans-serif";

const Icon = ({ d, size = 22, color = '#fff', strokeWidth = 2 }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round">
    <path d={d} />
  </svg>
);

const ICONS = {
  home: 'M3 12l9-9 9 9M5 10v10a1 1 0 001 1h12a1 1 0 001-1V10',
  calendar: 'M8 2v4M16 2v4M3 10h18M5 4h14a2 2 0 012 2v14a2 2 0 01-2 2H5a2 2 0 01-2-2V6a2 2 0 012-2z',
  users: 'M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2M9 11a4 4 0 100-8 4 4 0 000 8M23 21v-2a4 4 0 00-3-3.87M16 3.13a4 4 0 010 7.75',
  chart: 'M18 20V10M12 20V4M6 20v-6',
  back: 'M19 12H5M12 19l-7-7 7-7',
  pill: 'M10.5 1.5l3 3M4.5 7.5l12 12M8.5 3.5a5 5 0 017 7l-10 10a5 5 0 01-7-7z',
  file: 'M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8zM14 2v6h6',
  user: 'M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2M12 3a4 4 0 100 8 4 4 0 000-8z',
  search: 'M11 19a8 8 0 100-16 8 8 0 000 16zM21 21l-4.35-4.35',
  clock: 'M12 22c5.5 0 10-4.5 10-10S17.5 2 12 2 2 6.5 2 12s4.5 10 10 10zM12 6v6l4 2',
  check: 'M20 6L9 17l-5-5',
  flask: 'M9 3h6M10 3v6L4 19a2 2 0 001.7 3h12.6a2 2 0 001.7-3L14 9V3',
  heart: 'M12 21s-8-5-8-11a5 5 0 0110 0 5 5 0 0110 0c0 6-8 11-8 11z',
  plus: 'M12 5v14M5 12h14',
  bell: 'M18 8a6 6 0 10-12 0c0 7-3 9-3 9h18s-3-2-3-9M14 21a2 2 0 01-4 0',
  phone: 'M22 16.92v3a2 2 0 01-2.18 2 19.79 19.79 0 01-8.63-3.07 19.5 19.5 0 01-6-6 19.79 19.79 0 01-3.07-8.67A2 2 0 014.11 2h3a2 2 0 012 1.72',
};

window.MC_C = C;
window.MC_FONT = FONT;
window.MC_Icon = Icon;
window.MC_ICONS = ICONS;
