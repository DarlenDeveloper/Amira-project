/// Currency formatting for Amira. The client prices in **UGX** (Ugandan
/// shillings), never USD. Use [formatUgx] everywhere a price is shown.
library;

/// Formats a number as "UGX 1,234,000" (no decimals, thousands-grouped).
String formatUgx(num value) {
  final n = value.round();
  final digits = n.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return 'UGX ${n < 0 ? '-' : ''}$buf';
}
