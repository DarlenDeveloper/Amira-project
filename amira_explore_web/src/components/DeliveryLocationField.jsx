import { useState, useEffect } from 'react';
import AddressField from './AddressField.jsx';
import { watchProfile } from '../services/profile.js';

// Delivery address block for checkout — prefills from profile, supports GPS.
export default function DeliveryLocationField({
  user,
  hasAccount,
  address,
  onAddressChange,
  onLocated,
  disabled = false,
  id = 'delivery-address',
}) {
  useEffect(() => {
    if (!user?.uid || !hasAccount || address.trim()) return undefined;
    return watchProfile(user.uid, (profile) => {
      const saved = profile?.address?.trim();
      if (saved) onAddressChange(saved);
    });
  }, [user?.uid, hasAccount, address, onAddressChange]);

  return (
    <div className="delivery-location-field">
      <label className="delivery-location-label" htmlFor={id}>
        Delivery location
      </label>
      <AddressField
        id={id}
        value={address}
        onChange={onAddressChange}
        onLocated={onLocated}
        disabled={disabled}
        autoDetectOnMount={hasAccount && !address}
      />
    </div>
  );
}
