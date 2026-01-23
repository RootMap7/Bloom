class ProfileDetails {
  const ProfileDetails({
    required this.userId,
    this.birthdayDate,
    this.shortNote,
    this.interests,
    this.loveLanguage,
    this.carePreferences,
  });

  final String userId;
  final DateTime? birthdayDate;
  final String? shortNote;
  final String? interests;
  final String? loveLanguage;
  final String? carePreferences;

  factory ProfileDetails.fromMap(Map<String, dynamic> map) {
    return ProfileDetails(
      userId: (map['user_id'] ?? '').toString(),
      birthdayDate: _parseDate(map['birthday_date']),
      shortNote: _normalizeText(map['short_note']),
      interests: _normalizeText(map['interests']),
      loveLanguage: _normalizeText(map['love_language']),
      carePreferences: _normalizeText(map['care_preferences']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static String? _normalizeText(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
