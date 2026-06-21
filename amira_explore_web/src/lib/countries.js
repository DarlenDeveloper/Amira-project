// Dial codes for the phone picker. Uganda and East Africa listed first, then A–Z.
export const COUNTRIES = [
  { iso: 'UG', name: 'Uganda', dial: '+256' },
  { iso: 'KE', name: 'Kenya', dial: '+254' },
  { iso: 'TZ', name: 'Tanzania', dial: '+255' },
  { iso: 'RW', name: 'Rwanda', dial: '+250' },
  { iso: 'SS', name: 'South Sudan', dial: '+211' },
  { iso: 'ET', name: 'Ethiopia', dial: '+251' },
  { iso: 'ZA', name: 'South Africa', dial: '+27' },
  { iso: 'NG', name: 'Nigeria', dial: '+234' },
  { iso: 'GH', name: 'Ghana', dial: '+233' },
  { iso: 'AE', name: 'United Arab Emirates', dial: '+971' },
  { iso: 'GB', name: 'United Kingdom', dial: '+44' },
  { iso: 'US', name: 'United States', dial: '+1' },
  { iso: 'CA', name: 'Canada', dial: '+1' },
  { iso: 'IN', name: 'India', dial: '+91' },
  { iso: 'AU', name: 'Australia', dial: '+61' },
  { iso: 'DE', name: 'Germany', dial: '+49' },
  { iso: 'FR', name: 'France', dial: '+33' },
  { iso: 'CN', name: 'China', dial: '+86' },
];

const BY_ISO = new Map(COUNTRIES.map((c) => [c.iso, c]));

export function countryByIso(iso) {
  return BY_ISO.get(iso) || BY_ISO.get('UG');
}

/** E.164-style phone stored in Firestore, e.g. +256700123456 */
export function formatPhone(countryIso, nationalNumber) {
  const digits = String(nationalNumber || '').replace(/\D/g, '');
  if (!digits) return '';
  const dial = countryByIso(countryIso).dial.replace('+', '');
  return `+${dial}${digits}`;
}

/** Split a stored +256… value back into picker state. */
export function parsePhone(stored) {
  if (!stored?.startsWith('+')) {
    return { countryIso: detectCountryIso(), nationalNumber: stored || '' };
  }
  const digits = stored.replace(/\D/g, '');
  const match = [...COUNTRIES]
    .sort((a, b) => b.dial.length - a.dial.length)
    .find((c) => digits.startsWith(c.dial.replace('+', '')));
  if (!match) return { countryIso: detectCountryIso(), nationalNumber: stored };
  const dialDigits = match.dial.replace('+', '');
  return {
    countryIso: match.iso,
    nationalNumber: digits.slice(dialDigits.length),
  };
}

/** Best-effort default country from browser locale / timezone (no permission). */
export function detectCountryIso() {
  const locales = navigator.languages?.length ? navigator.languages : [navigator.language];
  for (const loc of locales) {
    const region = loc.split('-')[1];
    if (region?.length === 2 && BY_ISO.has(region.toUpperCase())) {
      return region.toUpperCase();
    }
  }
  try {
    const tz = Intl.DateTimeFormat().resolvedOptions().timeZone || '';
    const tzMap = {
      'Africa/Kampala': 'UG',
      'Africa/Nairobi': 'KE',
      'Africa/Dar_es_Salaam': 'TZ',
      'Africa/Kigali': 'RW',
      'Africa/Juba': 'SS',
      'Africa/Addis_Ababa': 'ET',
      'Africa/Johannesburg': 'ZA',
      'Africa/Lagos': 'NG',
      'Africa/Accra': 'GH',
      'Europe/London': 'GB',
      'America/New_York': 'US',
      'America/Los_Angeles': 'US',
      'America/Toronto': 'CA',
      'Asia/Dubai': 'AE',
    };
    if (tzMap[tz]) return tzMap[tz];
  } catch {
    // ignore
  }
  return 'UG';
}
