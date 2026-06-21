// Browser geolocation + reverse geocoding for delivery address autofill.
import { detectCountryIso } from './countries.js';

/** CORS-friendly reverse geocode (works from localhost and production). */
async function reverseGeocodeClient(lat, lng) {
  const url =
    `https://api.bigdatacloud.net/data/reverse-geocode-client` +
    `?latitude=${encodeURIComponent(lat)}` +
    `&longitude=${encodeURIComponent(lng)}` +
    `&localityLanguage=en`;

  const res = await fetch(url);
  if (!res.ok) throw new Error('geocode-failed');

  const data = await res.json();
  const parts = [
    data.locality,
    data.city || data.localityInfo?.administrative?.find((a) => a.order === 6)?.name,
    data.principalSubdivision,
    data.countryName,
  ].filter(Boolean);

  // De-dupe consecutive identical parts (locality often equals city).
  const address = [...new Set(parts)].join(', ');

  return {
    address: address || data.countryName || '',
    countryIso: (data.countryCode || detectCountryIso()).toUpperCase(),
  };
}

function geolocationError(err) {
  const code = err?.code;
  if (code === 1) return new Error('geolocation-permission-denied');
  if (code === 2) return new Error('geolocation-unavailable');
  if (code === 3) return new Error('geolocation-timeout');
  return err instanceof Error ? err : new Error('geolocation-failed');
}

function getPosition() {
  return new Promise((resolve, reject) => {
    if (!navigator.geolocation) {
      reject(new Error('geolocation-unavailable'));
      return;
    }
    if (!window.isSecureContext) {
      reject(new Error('geolocation-insecure'));
      return;
    }
    navigator.geolocation.getCurrentPosition(resolve, (err) => reject(geolocationError(err)), {
      enableHighAccuracy: true,
      timeout: 20000,
      maximumAge: 120000,
    });
  });
}

/**
 * Requests location permission, reverse-geocodes, and returns address + country.
 */
export async function detectLocationAddress() {
  const pos = await getPosition();
  const { latitude, longitude } = pos.coords;
  if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
    throw new Error('geolocation-unavailable');
  }
  return reverseGeocodeClient(latitude, longitude);
}

/** User-facing message for a location error code. */
export function locationErrorMessage(err) {
  switch (err?.message) {
    case 'geolocation-permission-denied':
      return 'Location access was denied. Allow location in your browser settings, or enter your address manually.';
    case 'geolocation-unavailable':
      return 'Location is unavailable on this device. Enter your address manually.';
    case 'geolocation-timeout':
      return 'Location took too long. Try the 📍 button again or enter your address manually.';
    case 'geolocation-insecure':
      return 'Location only works on a secure connection (HTTPS). Enter your address manually.';
    case 'geocode-failed':
      return 'We found your position but could not resolve an address. Enter it manually.';
    default:
      return 'Could not detect your location. Enter your address manually.';
  }
}

/** Fire-and-forget autofill — swallows errors (permission denied, etc.). */
export async function tryAutoFillAddress() {
  try {
    return await detectLocationAddress();
  } catch (err) {
    console.info('[Amira] Location autofill skipped:', err?.message || err);
    return null;
  }
}
