class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult({required this.isValid, this.errorMessage});

  static const ValidationResult success = ValidationResult(isValid: true);
  static ValidationResult failure(String msg) =>
      ValidationResult(isValid: false, errorMessage: msg);
}

/// Pre-flight security validation engine ensuring payload integrity before API or payment calls
class PayloadValidator {
  static final RegExp _phoneRegex = RegExp(r'^(\+91[\-\s]?)?[6-9]\d{9}$');
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$',
  );
  static final RegExp _scriptTagRegex = RegExp(
    r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>',
    caseSensitive: false,
  );

  /// Validates cashfree or payment gateway checkout payload
  static ValidationResult validatePaymentRequest({
    required double amount,
    required String customerId,
    required String orderId,
    String currency = 'INR',
  }) {
    if (amount <= 0 || amount > 500000) {
      return ValidationResult.failure(
        'Invalid transaction amount ($amount). Amount must be greater than zero.',
      );
    }
    if (currency.toUpperCase() != 'INR') {
      return ValidationResult.failure(
        'Unsupported currency ($currency). Transactions must be in INR.',
      );
    }
    if (customerId.trim().isEmpty) {
      return ValidationResult.failure('Customer ID cannot be empty.');
    }
    if (orderId.trim().isEmpty) {
      return ValidationResult.failure('Order ID cannot be empty.');
    }
    return ValidationResult.success;
  }

  /// Sanitizes text input to prevent XSS and malicious characters
  static String sanitizeText(String input) {
    if (input.isEmpty) return input;
    String clean = input.replaceAll(_scriptTagRegex, '');
    clean = clean.replaceAll('<', '&lt;').replaceAll('>', '&gt;');
    return clean.trim();
  }

  /// Validates phone number format
  static ValidationResult validatePhoneNumber(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return ValidationResult.failure('Phone number is required.');
    }
    final clean = phone.replaceAll(RegExp(r'[\s\-]'), '');
    if (!_phoneRegex.hasMatch(clean)) {
      return ValidationResult.failure(
        'Invalid mobile number. Please provide a valid 10-digit mobile number.',
      );
    }
    return ValidationResult.success;
  }

  /// Validates email address format
  static ValidationResult validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return ValidationResult.failure('Email address is required.');
    }
    if (!_emailRegex.hasMatch(email.trim())) {
      return ValidationResult.failure('Invalid email format.');
    }
    return ValidationResult.success;
  }

  /// Validates profile mutation payload before dispatching to Supabase
  static ValidationResult validateProfilePayload(Map<String, dynamic> data) {
    if (data.containsKey('name')) {
      final name = (data['name'] ?? '').toString().trim();
      if (name.isEmpty)
  { return ValidationResult.failure('Profile name cannot be empty.'); }
      if (name.length > 100)
  { return ValidationResult.failure('Profile name exceeds 100 characters.'); }
    }

    if (data.containsKey('phone')) {
      final res = validatePhoneNumber(data['phone']?.toString());
      if (!res.isValid) return res;
    }

    return ValidationResult.success;
  }
}
