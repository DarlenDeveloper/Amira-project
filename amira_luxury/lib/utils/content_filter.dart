/// Lightweight client-side guard for the AI chat input.
///
/// Blocks obviously inappropriate messages (sexual / explicit content and the
/// harshest profanity) before they ever reach the assistant, keeping the Amira
/// experience on-brand. Matching is word-boundary based so everyday words like
/// "cockpit", "Essex", "cumulative", or "analysis" are not caught.
///
/// This is a UX safeguard, not a hard security boundary — a determined user can
/// edit a client. For real enforcement, add a matching server-side check in the
/// `chatAgent` function.
library;

class ContentFilter {
  ContentFilter._();

  // Stems — matched at a word boundary and allowed to carry common suffixes,
  // so "sex" catches "sexting", "fuck" catches "fucking", "nude" catches
  // "nudes/nudity", "masturbat" catches "masturbate/masturbation".
  static const List<String> _stems = [
    'sex', 'nude', 'naked', 'porn', 'erotic', 'masturbat', 'rape', 'rapist',
    'pedophil', 'paedophil', 'fuck', 'orgasm', 'fetish', 'horny',
  ];

  // Exact whole words — short/ambiguous terms matched only on their own, so
  // they don't trip on innocent words (e.g. "cum" vs "cumulative").
  static const List<String> _words = [
    'cum', 'cock', 'dick', 'tits', 'titties', 'boob', 'boobs', 'pussy',
    'penis', 'vagina', 'slut', 'whore', 'cunt', 'xxx', 'nsfw', 'blowjob',
    'handjob', 'incest', 'bestiality', 'lingerie', 'hardcore', 'motherfucker',
  ];

  // Multi-word phrases blocked regardless of surrounding text.
  static const List<String> _phrases = [
    'child porn',
    'child sex',
    'send nudes',
  ];

  static final RegExp _stemPattern =
      RegExp(r'\b(' + _stems.join('|') + r')\w*\b', caseSensitive: false);

  static final RegExp _wordPattern =
      RegExp(r'\b(' + _words.join('|') + r')\b', caseSensitive: false);

  /// Returns true if [text] contains blocked content.
  static bool isBlocked(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    final lower = trimmed.toLowerCase();
    for (final phrase in _phrases) {
      if (lower.contains(phrase)) return true;
    }
    return _stemPattern.hasMatch(trimmed) || _wordPattern.hasMatch(trimmed);
  }
}
