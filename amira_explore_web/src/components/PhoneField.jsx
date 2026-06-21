import { COUNTRIES } from '../lib/countries.js';

// Country code + local number. Defaults to the visitor's detected region.
export default function PhoneField({
  countryIso,
  nationalNumber,
  onCountryChange,
  onNumberChange,
  disabled = false,
  id = 'phone',
}) {
  return (
    <div className="phone-field">
      <label className="phone-country-wrap" htmlFor={`${id}-country`}>
        <span className="sr-only">Country code</span>
        <select
          id={`${id}-country`}
          className="phone-country"
          value={countryIso}
          onChange={(e) => onCountryChange(e.target.value)}
          disabled={disabled}
          aria-label="Country code"
        >
          {COUNTRIES.map((c) => (
            <option key={c.iso} value={c.iso}>
              {c.dial} {c.name}
            </option>
          ))}
        </select>
      </label>
      <input
        id={id}
        type="tel"
        className="phone-number"
        value={nationalNumber}
        onChange={(e) => onNumberChange(e.target.value)}
        placeholder="700 123 456"
        autoComplete="tel-national"
        inputMode="tel"
        disabled={disabled}
        aria-label="Phone number"
      />
    </div>
  );
}
