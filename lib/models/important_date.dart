class ImportantDate {
  const ImportantDate({
    required this.id,
    required this.coupleId,
    required this.dateTitle,
    required this.eventDate,
    this.isRecurring = false,
    this.remindMe = true,
    this.milestoneTypeId,
    this.milestoneTypeName,
    this.category,
    this.notes,
    this.addedBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String coupleId;
  final String dateTitle;
  final DateTime eventDate;
  final bool isRecurring;
  final bool remindMe;
  final String? milestoneTypeId;
  final String? milestoneTypeName;
  final String? category;
  final String? notes;
  final String? addedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ImportantDate.fromMap(Map<String, dynamic> map) {
    return ImportantDate(
      id: map['id'] as String,
      coupleId: map['couple_id'] as String,
      dateTitle: map['date_title'] as String,
      eventDate: DateTime.parse(map['event_date'] as String),
      isRecurring: map['is_recurring'] as bool? ?? false,
      remindMe: map['remind_me'] as bool? ?? true,
      milestoneTypeId: map['milestone_type_id'] as String?,
      milestoneTypeName: _extractMilestoneTypeName(map),
      category: map['category'] as String?,
      notes: map['notes'] as String?,
      addedBy: map['added_by'] as String?,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  static String? _extractMilestoneTypeName(Map<String, dynamic> map) {
    if (map['milestone_types'] != null) {
      final milestoneTypes = map['milestone_types'];
      if (milestoneTypes is Map && milestoneTypes.containsKey('name')) {
        return milestoneTypes['name'] as String?;
      }
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'couple_id': coupleId,
      'date_title': dateTitle,
      'event_date': eventDate.toIso8601String().split('T')[0],
      'is_recurring': isRecurring,
      'remind_me': remindMe,
      'milestone_type_id': milestoneTypeId,
      'category': category,
      'notes': notes,
      'added_by': addedBy,
    };
  }

  ImportantDate copyWith({
    String? id,
    String? coupleId,
    String? dateTitle,
    DateTime? eventDate,
    bool? isRecurring,
    bool? remindMe,
    String? milestoneTypeId,
    String? milestoneTypeName,
    String? category,
    String? notes,
    String? addedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ImportantDate(
      id: id ?? this.id,
      coupleId: coupleId ?? this.coupleId,
      dateTitle: dateTitle ?? this.dateTitle,
      eventDate: eventDate ?? this.eventDate,
      isRecurring: isRecurring ?? this.isRecurring,
      remindMe: remindMe ?? this.remindMe,
      milestoneTypeId: milestoneTypeId ?? this.milestoneTypeId,
      milestoneTypeName: milestoneTypeName ?? this.milestoneTypeName,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      addedBy: addedBy ?? this.addedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class MilestoneType {
  const MilestoneType({
    required this.id,
    required this.name,
    this.createdAt,
  });

  final String id;
  final String name;
  final DateTime? createdAt;

  factory MilestoneType.fromMap(Map<String, dynamic> map) {
    return MilestoneType(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }
}
