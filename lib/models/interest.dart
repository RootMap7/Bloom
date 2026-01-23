class Interest {
  final String id;
  final String category;
  final String vibeColor;
  final String name;

  Interest({
    required this.id,
    required this.category,
    required this.vibeColor,
    required this.name,
  });

  factory Interest.fromMap(Map<String, dynamic> map) {
    return Interest(
      id: (map['id'] ?? '').toString(),
      category: (map['category'] ?? 'Other').toString(),
      vibeColor: (map['vibe_color'] ?? 'orange').toString(),
      name: (map['name'] ?? 'Unknown').toString(),
    );
  }
}
