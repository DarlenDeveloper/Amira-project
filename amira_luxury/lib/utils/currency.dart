/// Currency formatting for Amira. The client prices in **UGX** (Ugandan
/// shillings), never USD. UGX figures get large, so amounts are shown compactly
/// (UGX 1.2M, 700K, 20K, 1K, 1B). Use [formatUgx] everywhere a price is shown.
library;

String _trim(double v) {
  var s = v.toStringAsFixed(1);
  if (s.endsWith('.0')) s = s.substring(0, s.length - 2);
  return s;
}

/// Formats a number as a compact UGX amount, e.g. "UGX 1.2M", "UGX 700K".
/// Values below 1,000 are shown in full ("UGX 850").
String formatUgx(num value) {
  final n = value.toDouble();
  final a = n.abs();
  final String body;
  if (a >= 1e9) {
    body = '${_trim(a / 1e9)}B';
  } else if (a >= 1e6) {
    body = '${_trim(a / 1e6)}M';
  } else if (a >= 1e3) {
    body = '${_trim(a / 1e3)}K';
  } else {
    body = a.round().toString();
  }
  return 'UGX ${n < 0 ? '-' : ''}$body';
}
