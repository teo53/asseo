/// 알림 타입
enum NotificationType {
  newMessage,     // 새 메시지
  newContent,     // 새 콘텐츠 (피드/스토리)
  goodsDrop,      // 굿즈 출시
  eventReminder,  // 이벤트 알림 (오프회 등)
  subscription,   // 구독 관련
  system,         // 시스템 알림
}

/// 알림 모델
class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String? imageUrl;
  final String? castId;
  final String? castName;
  final String? actionUrl;
  final DateTime createdAt;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.imageUrl,
    this.castId,
    this.castName,
    this.actionUrl,
    required this.createdAt,
    this.isRead = false,
  });

  /// 타입별 아이콘
  String get iconName {
    switch (type) {
      case NotificationType.newMessage:
        return 'chat_bubble';
      case NotificationType.newContent:
        return 'photo_library';
      case NotificationType.goodsDrop:
        return 'shopping_bag';
      case NotificationType.eventReminder:
        return 'event';
      case NotificationType.subscription:
        return 'person_add';
      case NotificationType.system:
        return 'notifications';
    }
  }

  /// 타입별 라벨
  String get typeLabel {
    switch (type) {
      case NotificationType.newMessage:
        return '메시지';
      case NotificationType.newContent:
        return '새 콘텐츠';
      case NotificationType.goodsDrop:
        return '굿즈';
      case NotificationType.eventReminder:
        return '이벤트';
      case NotificationType.subscription:
        return '구독';
      case NotificationType.system:
        return '시스템';
    }
  }

  AppNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? body,
    String? imageUrl,
    String? castId,
    String? castName,
    String? actionUrl,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      castId: castId ?? this.castId,
      castName: castName ?? this.castName,
      actionUrl: actionUrl ?? this.actionUrl,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
