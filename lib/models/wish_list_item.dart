class WishListItem {
  final String id;
  final String userId;
  final String title;
  final String? categoryId;
  final String? categoryName;
  final String? notes;
  final String? links;
  final String? themeColor;
  final bool isSurprise;
  final String wishFor;
  final bool isPrivate;
  final bool isCompleted;
  final DateTime createdAt;

  WishListItem({
    required this.id,
    required this.userId,
    required this.title,
    this.categoryId,
    this.categoryName,
    this.notes,
    this.links,
    this.themeColor,
    this.isSurprise = false,
    this.wishFor = 'Me',
    this.isPrivate = false,
    this.isCompleted = false,
    required this.createdAt,
  });

  factory WishListItem.fromMap(Map<String, dynamic> map) {
    return WishListItem(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      title: map['title'] ?? '',
      categoryId: map['category_id'],
      categoryName: map['bucket_list_categories']?['name'],
      notes: map['notes'],
      links: map['links'],
      themeColor: map['theme_color'],
      isSurprise: map['is_surprise'] ?? false,
      wishFor: map['wish_for'] ?? 'Me',
      isPrivate: map['is_private'] ?? false,
      isCompleted: map['is_completed'] ?? false,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
