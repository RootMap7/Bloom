class ReceiveCareOption {
  final String id;
  final String type;
  final String description;

  const ReceiveCareOption({
    required this.id,
    required this.type,
    required this.description,
  });

  factory ReceiveCareOption.fromMap(Map<String, dynamic> map) {
    return ReceiveCareOption(
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
