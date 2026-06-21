import { useEffect, useState } from 'react';
import { detectLocationAddress, locationErrorMessage } from '../lib/geo.js';

// Delivery address with one-tap geolocation autofill.
export default function AddressField({
  value,
  onChange,
  onCountryDetected,
  onLocated,
  disabled = false,
  autoDetectOnMount = false,
  id = 'address',
}) {
  const [locating, setLocating] = useState(false);
  const [locError, setLocError] = useState('');
  const [autoTried, setAutoTried] = useState(false);

  const locate = async () => {
    setLocating(true);
    setLocError('');
    try {
      const result = await detectLocationAddress();
      onChange(result.address);
      onCountryDetected?.(result.countryIso);
      onLocated?.(result);
    } catch (err) {
      setLocError(locationErrorMessage(err));
    } finally {
      setLocating(false);
    }
  };

  useEffect(() => {
    if (!autoDetectOnMount || autoTried || value) return;
    setAutoTried(true);
    locate();
  }, [autoDetectOnMount, autoTried, value]); // eslint-disable-line react-hooks/exhaustive-deps

  return (
    <div className="address-field">
      <div className="address-input-row">
        <input
          id={id}
          className="address-input"
          value={value}
          onChange={(e) => onChange(e.target.value)}
          placeholder="Street, city, country"
          autoComplete="street-address"
          disabled={disabled || locating}
        />
        <button
          type="button"
          className="address-locate-btn"
          onClick={locate}
          disabled={disabled || locating}
          title="Use my current location"
        >
          {locating ? '…' : '📍'}
        </button>
      </div>
      {locating && <p className="address-hint">Detecting your location…</p>}
      {locError && <p className="address-hint address-hint--error">{locError}</p>}
      {!locating && !locError && (
        <p className="address-hint">We use your location to pre-fill delivery details.</p>
      )}
    </div>
  );
}
