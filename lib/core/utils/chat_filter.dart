class ChatFilter {
  /// Regular expression to match common email address patterns.
  static final RegExp _emailRegex = RegExp(
    r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
    caseSensitive: false,
  );

  static final RegExp _phoneRegex = RegExp(
    r'(?:\+?[\d][\s\-.]*){10,}',
  );

  /// Regular expression to match common URL patterns.
  static final RegExp _urlRegex = RegExp(
    r'(https?:\/\/)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
    caseSensitive: false,
  );

  static final List<String> _prohibitedKeywords = [
    'whatsapp',
    'insta',
    'instagram',
    'facebook',
    'fb',
    '@',
    '.com',
    'phone',
    'contact'
  ];

  /// Filters the given [text] by replacing sensitive contact information with placeholders.
  static String filter(String text) {
    if (text.isEmpty) return text;

    String filteredText = text;

    // 1. Mask Email Addresses
    filteredText = filteredText.replaceAll(_emailRegex, '[EMAIL REMOVED]');

    // 2. Mask Phone Numbers (if they look like 10 digits)
    filteredText = filteredText.replaceAllMapped(_phoneRegex, (match) {
      final digits = match.group(0)!.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= 10) {
        return '[PHONE REMOVED]';
      }
      return match.group(0)!;
    });

    // 3. Mask URLs / External Links
    filteredText = filteredText.replaceAll(_urlRegex, '[LINK REMOVED]');

    return filteredText;
  }

  /// Returns true if the text contains any prohibited contact information.
  static bool hasProhibitedContent(String text) {
    if (text.isEmpty) return false;

    if (_emailRegex.hasMatch(text)) return true;
    if (_urlRegex.hasMatch(text)) return true;

    final phoneMatch = _phoneRegex.firstMatch(text);
    if (phoneMatch != null) {
      final digits = phoneMatch.group(0)!.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= 10) return true;
    }

    final lowerText = text.toLowerCase();
    for (var keyword in _prohibitedKeywords) {
      if (lowerText.contains(keyword)) {
        return true;
      }
    }

    return false;
  }
}
