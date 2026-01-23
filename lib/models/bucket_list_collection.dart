class BucketListCollection {
  final String id;
  final String userId;
  final String name;

  BucketListCollection({
    required this.id,
    required this.userId,
    required this.name,
  });

  factory BucketListCollection.fromMap(Map<String, dynamic> map) {
    return BucketListCollection(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      name: map['name'] ?? '',
    );
  }
}
