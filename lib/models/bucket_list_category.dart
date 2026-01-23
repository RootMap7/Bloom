class BucketListCategory {
  final String id;
  final String name;

  const BucketListCategory({
    required this.id,
    required this.name,
  });

  factory BucketListCategory.fromMap(Map<String, dynamic> map) {
    return BucketListCategory(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
    );
  }
}
