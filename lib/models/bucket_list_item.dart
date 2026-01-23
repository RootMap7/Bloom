class BucketListItem {
  final String id;
  final String userId;
  final String title;
  final DateTime? targetDate;
  final String? categoryId;
  final String? categoryName;
  final String? collection;
  final String? notes;
  final String? links;
  final String? themeColor;
  final bool isPrivate;
  final bool isCompleted;
  final DateTime createdAt;

  BucketListItem({
    required this.id,
    required this.userId,
    required this.title,
    this.targetDate,
    this.categoryId,
    this.categoryName,
    this.collection,
    this.notes,
    this.links,
    this.themeColor,
    this.isPrivate = false,
    this.isCompleted = false,
    required this.createdAt,
  });

  factory BucketListItem.fromMap(Map<String, dynamic> map) {
    return BucketListItem(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      title: map['title'] ?? '',
      targetDate: map['target_date'] != null ? DateTime.parse(map['target_date']) : null,
      categoryId: map['category_id'],
      categoryName: map['bucket_list_categories']?['name'],
      collection: map['collection'],
      notes: map['notes'],
      links: map['links'],
      themeColor: map['theme_color'],
      isPrivate: map['is_private'] ?? false,
      isCompleted: map['is_completed'] ?? false,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
