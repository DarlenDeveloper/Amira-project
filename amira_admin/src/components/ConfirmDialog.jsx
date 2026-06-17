import { useState } from 'react';
import Modal from './Modal.jsx';

// Confirmation dialog for destructive actions. `onConfirm` may be async.
export default function ConfirmDialog({ title, message, confirmLabel = 'Delete', onCancel, onConfirm }) {
  const [busy, setBusy] = useState(false);

  const confirm = async () => {
    setBusy(true);
    try {
      await onConfirm();
    } finally {
      setBusy(false);
    }
  };

  return (
    <Modal
      title={title}
      onClose={onCancel}
      footer={
        <>
          <button type="button" className="ghost-btn" onClick={onCancel} disabled={busy}>
            Cancel
          </button>
          <button type="button" className="danger-btn" onClick={confirm} disabled={busy}>
            {busy ? 'Deleting…' : confirmLabel}
          </button>
        </>
      }
    >
      <p className="confirm-message">{message}</p>
    </Modal>
  );
}
