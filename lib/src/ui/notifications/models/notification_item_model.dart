enum NotificationCategory {
  applications,
  visaUpdates,
  offers,
  system;

  String get label {
    switch (this) {
      case NotificationCategory.applications:
        return 'Applications';
      case NotificationCategory.visaUpdates:
        return 'Visa Updates';
      case NotificationCategory.offers:
        return 'Offers & Grants';
      case NotificationCategory.system:
        return 'System Alerts';
    }
  }
}

class NotificationItemModel {
  const NotificationItemModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.category,
    this.isRead = false,
    this.actionRoute,
    this.actionLabel,
    this.metadata,
  });

  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final NotificationCategory category;
  final bool isRead;
  final String? actionRoute;
  final String? actionLabel;
  final Map<String, dynamic>? metadata;

  NotificationItemModel copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? timestamp,
    NotificationCategory? category,
    bool? isRead,
    String? actionRoute,
    String? actionLabel,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      category: category ?? this.category,
      isRead: isRead ?? this.isRead,
      actionRoute: actionRoute ?? this.actionRoute,
      actionLabel: actionLabel ?? this.actionLabel,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'category': category.name,
      'isRead': isRead,
      'actionRoute': actionRoute,
      'actionLabel': actionLabel,
    };
  }

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) {
    return NotificationItemModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      category: NotificationCategory.values.firstWhere(
        (c) => c.name == (json['category'] as String?),
        orElse: () => NotificationCategory.system,
      ),
      isRead: json['isRead'] as bool? ?? false,
      actionRoute: json['actionRoute'] as String?,
      actionLabel: json['actionLabel'] as String?,
    );
  }
}
