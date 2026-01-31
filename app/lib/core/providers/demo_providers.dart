import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 데모 모드 상태 관리 통합 파일
/// 모든 데모 관련 프로바이더를 한 곳에서 관리

// ============================================
// 데모 구독 관리
// ============================================

/// 데모 구독 목록 (cast_id 리스트)
final demoSubscriptionsProvider = StateNotifierProvider<DemoSubscriptionsNotifier, List<String>>((ref) {
  return DemoSubscriptionsNotifier();
});

class DemoSubscriptionsNotifier extends StateNotifier<List<String>> {
  DemoSubscriptionsNotifier() : super(['cast-1', 'cast-3']); // 기본 구독: 유키, 하나

  void subscribe(String castId) {
    if (!state.contains(castId)) {
      state = [...state, castId];
    }
  }

  void unsubscribe(String castId) {
    state = state.where((id) => id != castId).toList();
  }

  bool isSubscribed(String castId) => state.contains(castId);
}

// ============================================
// 데모 메시지 관리 (사용자가 보낸 답장)
// ============================================

/// 캐스트별 사용자 답장 메시지
final demoUserRepliesProvider = StateNotifierProvider.family<DemoUserRepliesNotifier, List<Map<String, dynamic>>, String>((ref, castId) {
  return DemoUserRepliesNotifier(castId);
});

class DemoUserRepliesNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final String castId;

  DemoUserRepliesNotifier(this.castId) : super([]);

  void addReply(String content) {
    final newReply = {
      'id': 'reply-${DateTime.now().millisecondsSinceEpoch}',
      'cast_id': castId,
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
      'is_user_reply': true,
    };
    state = [newReply, ...state];
  }
}

// ============================================
// 데모 지갑 관리
// ============================================

/// 데모 지갑 잔액
final demoWalletBalanceProvider = StateNotifierProvider<DemoWalletNotifier, int>((ref) {
  return DemoWalletNotifier();
});

class DemoWalletNotifier extends StateNotifier<int> {
  DemoWalletNotifier() : super(4500); // 초기 잔액: 4,500 DT

  void addBalance(int amount) {
    state = state + amount;
  }

  void spend(int amount) {
    if (state >= amount) {
      state = state - amount;
    }
  }

  bool canSpend(int amount) => state >= amount;
}

// ============================================
// 데모 프로필 관리
// ============================================

/// 데모 프로필 정보
final demoProfileProvider = StateNotifierProvider<DemoProfileNotifier, Map<String, dynamic>>((ref) {
  return DemoProfileNotifier();
});

class DemoProfileNotifier extends StateNotifier<Map<String, dynamic>> {
  DemoProfileNotifier() : super({
    'id': 'demo-user',
    'nickname': '테스트 유저',
    'profile_image': null,
    'email': 'test@test.com',
    'dreamtime_balance': 4500,
  });

  void updateNickname(String nickname) {
    state = {...state, 'nickname': nickname};
  }

  void updateProfileImage(String? imageUrl) {
    state = {...state, 'profile_image': imageUrl};
  }
}

// ============================================
// 데모 설정 관리
// ============================================

/// 알림 설정
final demoNotificationSettingsProvider = StateNotifierProvider<DemoNotificationSettingsNotifier, Map<String, bool>>((ref) {
  return DemoNotificationSettingsNotifier();
});

class DemoNotificationSettingsNotifier extends StateNotifier<Map<String, bool>> {
  DemoNotificationSettingsNotifier() : super({
    'push_enabled': true,
    'new_message': true,
    'new_content': true,
    'marketing': false,
  });

  void toggle(String key) {
    state = {...state, key: !(state[key] ?? false)};
  }

  void set(String key, bool value) {
    state = {...state, key: value};
  }
}

/// 언어 설정
final demoLanguageProvider = StateProvider<String>((ref) => 'ko');

// ============================================
// 데모 읽지 않은 메시지 관리
// ============================================

/// 캐스트별 읽지 않은 메시지 수
final demoUnreadCountProvider = StateNotifierProvider<DemoUnreadCountNotifier, Map<String, int>>((ref) {
  return DemoUnreadCountNotifier();
});

class DemoUnreadCountNotifier extends StateNotifier<Map<String, int>> {
  DemoUnreadCountNotifier() : super({
    'cast-1': 3,
    'cast-3': 1,
  });

  void markAsRead(String castId) {
    state = {...state, castId: 0};
  }

  void addUnread(String castId, [int count = 1]) {
    state = {...state, castId: (state[castId] ?? 0) + count};
  }

  int getCount(String castId) => state[castId] ?? 0;
}

// ============================================
// 데모 거래 내역 관리
// ============================================

/// 데모 거래 내역
final demoTransactionsProvider = StateNotifierProvider<DemoTransactionsNotifier, List<Map<String, dynamic>>>((ref) {
  return DemoTransactionsNotifier();
});

class DemoTransactionsNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  DemoTransactionsNotifier() : super([
    {
      'id': 'tx-1',
      'type': 'topup',
      'amount': 5000,
      'balance_after': 5000,
      'description': '충전',
      'created_at': DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
    },
    {
      'id': 'tx-2',
      'type': 'donation',
      'amount': -300,
      'balance_after': 4700,
      'description': '유키에게 후원',
      'created_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
    },
    {
      'id': 'tx-3',
      'type': 'donation',
      'amount': -200,
      'balance_after': 4500,
      'description': '하나에게 후원',
      'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
    },
  ]);

  void addTransaction({
    required String type,
    required int amount,
    required int balanceAfter,
    required String description,
  }) {
    final newTx = {
      'id': 'tx-${DateTime.now().millisecondsSinceEpoch}',
      'type': type,
      'amount': amount,
      'balance_after': balanceAfter,
      'description': description,
      'created_at': DateTime.now().toIso8601String(),
    };
    state = [newTx, ...state];
  }
}

// ============================================
// 데모 알림 관리
// ============================================

/// 알림 타입
enum DemoNotificationType {
  newMessage,     // 새 메시지
  newContent,     // 새 콘텐츠 (피드/스토리)
  goodsDrop,      // 굿즈 출시
  eventReminder,  // 이벤트 알림 (오프회 등)
  subscription,   // 구독 관련
  system,         // 시스템 알림
}

/// 데모 알림 목록
final demoNotificationsProvider = StateNotifierProvider<DemoNotificationsNotifier, List<Map<String, dynamic>>>((ref) {
  return DemoNotificationsNotifier();
});

class DemoNotificationsNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  DemoNotificationsNotifier() : super([
    {
      'id': 'notif-1',
      'type': 'goodsDrop',
      'title': '새로운 굿즈가 출시되었어요! 🎁',
      'body': '유키의 Winter Photo Set이 출시되었습니다. 지금 바로 확인해보세요!',
      'cast_id': 'cast-1',
      'cast_name': '유키',
      'image_url': null,
      'action_url': '/cast/cast-1',
      'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      'is_read': false,
    },
    {
      'id': 'notif-2',
      'type': 'eventReminder',
      'title': '팬미팅 D-3 🗓️',
      'body': '하나의 첫 번째 팬미팅이 3일 후에 열립니다! 장소와 시간을 확인하세요.',
      'cast_id': 'cast-3',
      'cast_name': '하나',
      'image_url': null,
      'action_url': '/cast/cast-3',
      'created_at': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
      'is_read': false,
    },
    {
      'id': 'notif-3',
      'type': 'newMessage',
      'title': '유키님이 메시지를 보냈어요 💌',
      'body': '새로운 프라이빗 메시지가 도착했습니다.',
      'cast_id': 'cast-1',
      'cast_name': '유키',
      'image_url': null,
      'action_url': '/chat/cast-1',
      'created_at': DateTime.now().subtract(const Duration(hours: 8)).toIso8601String(),
      'is_read': true,
    },
    {
      'id': 'notif-4',
      'type': 'newContent',
      'title': '하나님이 새 스토리를 올렸어요 📸',
      'body': '지금 바로 확인해보세요!',
      'cast_id': 'cast-3',
      'cast_name': '하나',
      'image_url': null,
      'action_url': '/cast/cast-3',
      'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'is_read': true,
    },
    {
      'id': 'notif-5',
      'type': 'goodsDrop',
      'title': '한정판 굿즈 알림 ⏰',
      'body': '소라의 1st Anniversary 포토카드가 내일 오후 6시에 출시됩니다!',
      'cast_id': 'cast-2',
      'cast_name': '소라',
      'image_url': null,
      'action_url': '/cast/cast-2',
      'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'is_read': true,
    },
  ]);

  void addNotification({
    required String type,
    required String title,
    required String body,
    String? castId,
    String? castName,
    String? imageUrl,
    String? actionUrl,
  }) {
    final newNotif = {
      'id': 'notif-${DateTime.now().millisecondsSinceEpoch}',
      'type': type,
      'title': title,
      'body': body,
      'cast_id': castId,
      'cast_name': castName,
      'image_url': imageUrl,
      'action_url': actionUrl,
      'created_at': DateTime.now().toIso8601String(),
      'is_read': false,
    };
    state = [newNotif, ...state];
  }

  void markAsRead(String notifId) {
    state = state.map((n) {
      if (n['id'] == notifId) {
        return {...n, 'is_read': true};
      }
      return n;
    }).toList();
  }

  void markAllAsRead() {
    state = state.map((n) => {...n, 'is_read': true}).toList();
  }

  int get unreadCount => state.where((n) => n['is_read'] == false).length;
}

/// 읽지 않은 알림 수
final demoUnreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(demoNotificationsProvider);
  return notifications.where((n) => n['is_read'] == false).length;
});

// ============================================
// 데모 이벤트 리마인더 관리
// ============================================

/// 이벤트 알림 설정 (캐스트별)
final demoEventRemindersProvider = StateNotifierProvider<DemoEventRemindersNotifier, Map<String, bool>>((ref) {
  return DemoEventRemindersNotifier();
});

class DemoEventRemindersNotifier extends StateNotifier<Map<String, bool>> {
  DemoEventRemindersNotifier() : super({});

  void setReminder(String eventId, bool enabled) {
    state = {...state, eventId: enabled};
  }

  bool hasReminder(String eventId) => state[eventId] ?? false;

  void toggleReminder(String eventId) {
    state = {...state, eventId: !(state[eventId] ?? false)};
  }
}
