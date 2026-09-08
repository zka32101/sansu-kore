/// Security utilities for input validation and sanitization
/// Prevents injection attacks and ensures data integrity

class SecurityUtils {
  /// Allowed profile fields that can be updated via API
  static const Set<String> allowedProfileFields = {
    'name',
    'grade',
    'favoriteItem',
    'bio',
    'theme',
  };

  /// Allowed user fields for direct updates
  static const Set<String> allowedUserFields = {
    'coins',
    'xp',
    'streak',
    'lastLoginAt',
    'preferences',
  };

  /// Validate and sanitize profile update data
  /// Only allows whitelisted fields to prevent unauthorized modifications
  static Map<String, dynamic> validateProfileUpdate(Map<String, dynamic> data) {
    if (data.isEmpty) {
      throw ArgumentError('Update data cannot be empty');
    }

    final sanitized = <String, dynamic>{};

    data.forEach((key, value) {
      if (!allowedProfileFields.contains(key)) {
        throw SecurityException('Unauthorized profile field: $key');
      }

      // Validate specific field types and values
      switch (key) {
        case 'name':
          if (value is! String) throw ArgumentError('name must be String');
          final trimmed = (value as String).trim();
          if (trimmed.isEmpty) throw ArgumentError('name cannot be empty');
          if (trimmed.length > 50) throw ArgumentError('name too long');
          sanitized[key] = trimmed;
          break;

        case 'grade':
          if (value is! int) throw ArgumentError('grade must be int');
          if (value < 1 || value > 6) {
            throw ArgumentError('grade must be between 1 and 6');
          }
          sanitized[key] = value;
          break;

        case 'favoriteItem':
          if (value is! String) throw ArgumentError('favoriteItem must be String');
          final trimmed = (value as String).trim();
          if (trimmed.length > 30) throw ArgumentError('favoriteItem too long');
          sanitized[key] = trimmed;
          break;

        case 'bio':
          if (value is! String) throw ArgumentError('bio must be String');
          if ((value as String).length > 500) {
            throw ArgumentError('bio too long');
          }
          sanitized[key] = (value as String).trim();
          break;

        case 'theme':
          if (value is! String) throw ArgumentError('theme must be String');
          final validThemes = {'light', 'dark', 'auto'};
          if (!validThemes.contains(value)) {
            throw ArgumentError('Invalid theme value');
          }
          sanitized[key] = value;
          break;
      }
    });

    return sanitized;
  }

  /// Validate user update data (for internal use, stricter controls)
  static Map<String, dynamic> validateUserUpdate(Map<String, dynamic> data) {
    if (data.isEmpty) {
      throw ArgumentError('Update data cannot be empty');
    }

    final sanitized = <String, dynamic>{};

    data.forEach((key, value) {
      if (!allowedUserFields.contains(key)) {
        throw SecurityException('Unauthorized user field: $key');
      }

      switch (key) {
        case 'coins':
        case 'xp':
          if (value is! int) throw ArgumentError('$key must be int');
          if (value < 0) throw ArgumentError('$key cannot be negative');
          sanitized[key] = value;
          break;

        case 'streak':
          if (value is! int) throw ArgumentError('streak must be int');
          if (value < 0) throw ArgumentError('streak cannot be negative');
          sanitized[key] = value;
          break;

        case 'preferences':
          if (value is! Map) throw ArgumentError('preferences must be Map');
          sanitized[key] = Map<String, dynamic>.from(value as Map);
          break;

        case 'lastLoginAt':
          if (value != null && value is! DateTime && value is! String) {
            throw ArgumentError('lastLoginAt must be DateTime or String');
          }
          sanitized[key] = value;
          break;
      }
    });

    return sanitized;
  }

  /// Validate string length within bounds
  static String validateString(
    String value, {
    required String fieldName,
    required int minLength,
    required int maxLength,
  }) {
    final trimmed = value.trim();
    if (trimmed.length < minLength) {
      throw ArgumentError('$fieldName too short (min: $minLength)');
    }
    if (trimmed.length > maxLength) {
      throw ArgumentError('$fieldName too long (max: $maxLength)');
    }
    return trimmed;
  }

  /// Validate grade number (1-6)
  static int validateGrade(int grade) {
    if (grade < 1 || grade > 6) {
      throw ArgumentError('Grade must be between 1 and 6');
    }
    return grade;
  }

  /// Validate question index
  static int validateQuestionIndex(int index, int maxIndex) {
    if (index < 0 || index >= maxIndex) {
      throw ArgumentError('Invalid question index');
    }
    return index;
  }

  /// Validate coin transaction amount
  static int validateCoinAmount(int amount) {
    if (amount < 0) throw ArgumentError('Coin amount cannot be negative');
    if (amount > 999999) throw ArgumentError('Coin amount exceeds maximum');
    return amount;
  }
}

/// Custom exception for security violations
class SecurityException implements Exception {
  final String message;

  SecurityException(this.message);

  @override
  String toString() => 'SecurityException: $message';
}
