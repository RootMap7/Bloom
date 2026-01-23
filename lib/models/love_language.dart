class LoveLanguage {
  final String id;
  final String type;
  final String description;

  const LoveLanguage({
    required this.id,
    required this.type,
    required this.description,
  });

  factory LoveLanguage.fromMap(Map<String, dynamic> map) {
    return LoveLanguage(
      id: map['id'] as String,
      type: map['type'] as String,
      description: map['description'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'description': description,
    };
  }
}
