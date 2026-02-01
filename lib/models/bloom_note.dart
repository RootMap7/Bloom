class BloomNote {
  final String id;
  final String coupleId;
  final String senderId;
  final String recipientId;
  final String message;
  final bool isLiked;
  final DateTime? likedAt;
  final DateTime expiresAt;
  final DateTime createdAt;

  BloomNote({
    required this.id,
    required this.coupleId,
    required this.senderId,
    required this.recipientId,
    required this.message,
    this.isLiked = false,
    this.likedAt,
    required this.expiresAt,
    required this.createdAt,
  });

  factory BloomNote.fromMap(Map<String, dynamic> map) {
    return BloomNote(
      id: map['id'] ?? '',
      coupleId: map['couple_id'] ?? '',
      senderId: map['sender_id'] ?? '',
      recipientId: map['recipient_id'] ?? '',
      message: map['message'] ?? '',
      isLiked: map['is_liked'] ?? false,
      likedAt: map['liked_at'] != null ? DateTime.parse(map['liked_at']) : null,
      expiresAt: DateTime.parse(map['expires_at']),
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'couple_id': coupleId,
      'sender_id': senderId,
      'recipient_id': recipientId,
      'message': message,
      'is_liked': isLiked,
      'liked_at': likedAt?.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
