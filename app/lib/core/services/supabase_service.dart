import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../main.dart';
import 'auth_service.dart';

// ============================================
// 데모 더미 데이터
// ============================================

/// 데모 캐스트 데이터 - 밤에 내린 눈 컨셉
final List<Map<String, dynamic>> _demoCasts = [
  {
    'id': 'cast-1',
    'stage_name': '유키',
    'bio': '안녕하세요! 유키입니다 💕 밤하늘의 눈처럼 빛나고 싶어요',
    'profile_image': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&h=200&fit=crop',
    'subscriber_count': 1520,
    'is_active': true,
    'team': {'id': 'team-1', 'name': 'Snow Melody'},
  },
  {
    'id': 'cast-2',
    'stage_name': '미나',
    'bio': '여러분의 미나예요~ 겨울밤처럼 포근하게 💫',
    'profile_image': 'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=200&h=200&fit=crop',
    'subscriber_count': 980,
    'is_active': true,
    'team': {'id': 'team-1', 'name': 'Snow Melody'},
  },
  {
    'id': 'cast-3',
    'stage_name': '하나',
    'bio': '하나입니다! 첫눈처럼 설레는 만남을 🌨️',
    'profile_image': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200&h=200&fit=crop',
    'subscriber_count': 756,
    'is_active': true,
    'team': {'id': 'team-2', 'name': 'Moon Light'},
  },
  {
    'id': 'cast-4',
    'stage_name': '린',
    'bio': '린이에요! 밤눈처럼 조용히 다가갈게요 ❄️',
    'profile_image': 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=200&h=200&fit=crop',
    'subscriber_count': 643,
    'is_active': true,
    'team': {'id': 'team-2', 'name': 'Moon Light'},
  },
  {
    'id': 'cast-5',
    'stage_name': '사쿠라',
    'bio': '사쿠라입니다 🌸 눈 내린 밤의 벚꽃처럼',
    'profile_image': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200&h=200&fit=crop',
    'subscriber_count': 512,
    'is_active': true,
    'team': {'id': 'team-3', 'name': 'Winter Blossom'},
  },
  {
    'id': 'cast-6',
    'stage_name': '아이',
    'bio': '아이예요! 눈송이처럼 순수한 마음으로 💖',
    'profile_image': 'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=200&h=200&fit=crop',
    'subscriber_count': 489,
    'is_active': true,
    'team': {'id': 'team-1', 'name': 'Snow Melody'},
  },
];

/// 데모 구독 데이터
final List<Map<String, dynamic>> _demoSubscriptions = [
  {
    'id': 'sub-1',
    'fan_id': 'demo-user',
    'cast_id': 'cast-1',
    'is_active': true,
    'cast': _demoCasts[0],
    'tier': {'code': 'STANDARD', 'name': '스탠다드', 'price_monthly': 5900},
  },
  {
    'id': 'sub-2',
    'fan_id': 'demo-user',
    'cast_id': 'cast-3',
    'is_active': true,
    'cast': _demoCasts[2],
    'tier': {'code': 'PREMIUM', 'name': '프리미엄', 'price_monthly': 9900},
  },
];

/// 데모 메시지 데이터
final List<Map<String, dynamic>> _demoMessages = [
  {
    'id': 'msg-1',
    'cast_id': 'cast-1',
    'content': '안녕하세요 여러분! 오늘도 좋은 하루 되세요 💕',
    'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
    'is_deleted': false,
    'cast': _demoCasts[0],
  },
  {
    'id': 'msg-2',
    'cast_id': 'cast-1',
    'content': '오늘 연습 열심히 했어요! 곧 새로운 모습 보여드릴게요~',
    'created_at': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
    'is_deleted': false,
    'cast': _demoCasts[0],
  },
  {
    'id': 'msg-3',
    'cast_id': 'cast-1',
    'content': '다들 밥은 먹었나요? 저는 지금 맛있는 라멘 먹고 있어요 🍜',
    'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
    'is_deleted': false,
    'cast': _demoCasts[0],
  },
  {
    'id': 'msg-4',
    'cast_id': 'cast-3',
    'content': '하나입니다~ 오늘 공연 잘 봐주셔서 감사해요!',
    'created_at': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
    'is_deleted': false,
    'cast': _demoCasts[2],
  },
  {
    'id': 'msg-5',
    'cast_id': 'cast-3',
    'content': '내일도 열심히 할게요! 응원해주세요 🌸',
    'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
    'is_deleted': false,
    'cast': _demoCasts[2],
  },
];

/// 데모 프로필 데이터
final Map<String, dynamic> _demoProfile = {
  'id': 'demo-user',
  'nickname': '테스트 유저',
  'profile_image': null,
  'dreamtime_balance': 4500,
};

/// 데모 마지막 메시지 데이터
final Map<String, Map<String, dynamic>> _demoLastMessages = {
  'cast-1': {
    'content': '오늘도 좋은 하루 되세요 💕',
    'created_at': DateTime.now().subtract(const Duration(minutes: 2)).toIso8601String(),
  },
  'cast-3': {
    'content': '공연 잘 봐주셔서 감사해요!',
    'created_at': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
  },
};

/// 데모 읽지 않은 메시지 수
final Map<String, int> _demoUnreadCounts = {
  'cast-1': 3,
  'cast-3': 1,
};

/// Supabase Database 서비스
class SupabaseService {
  final SupabaseClient _supabase;

  SupabaseService(this._supabase);

  // ============================================
  // Profiles
  // ============================================

  /// 프로필 조회
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    if (isDemoMode) {
      return _demoProfile;
    }
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return response;
  }

  /// 프로필 업데이트
  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    await _supabase.from('profiles').update(data).eq('id', userId);
  }

  // ============================================
  // Casts
  // ============================================

  /// 캐스트 목록 조회
  Future<List<Map<String, dynamic>>> getCasts({
    int page = 1,
    int limit = 20,
    String? search,
    String? teamId,
  }) async {
    if (isDemoMode) {
      var result = List<Map<String, dynamic>>.from(_demoCasts);
      if (search != null && search.isNotEmpty) {
        result = result.where((c) =>
          (c['stage_name'] as String).toLowerCase().contains(search.toLowerCase())
        ).toList();
      }
      if (teamId != null) {
        result = result.where((c) => c['team']?['id'] == teamId).toList();
      }
      return result;
    }

    var query = _supabase
        .from('casts')
        .select('*, team:teams(*)')
        .eq('is_active', true);

    if (search != null && search.isNotEmpty) {
      query = query.ilike('stage_name', '%$search%');
    }

    if (teamId != null) {
      query = query.eq('team_id', teamId);
    }

    final response = await query
        .order('subscriber_count', ascending: false)
        .range((page - 1) * limit, page * limit - 1);

    return List<Map<String, dynamic>>.from(response);
  }

  /// 캐스트 상세 조회
  Future<Map<String, dynamic>?> getCast(String castId) async {
    if (isDemoMode) {
      return _demoCasts.where((c) => c['id'] == castId).firstOrNull;
    }
    final response = await _supabase
        .from('casts')
        .select('*, team:teams(*)')
        .eq('id', castId)
        .single();
    return response;
  }

  /// 인기 캐스트
  Future<List<Map<String, dynamic>>> getPopularCasts({int limit = 10}) async {
    if (isDemoMode) {
      final sorted = List<Map<String, dynamic>>.from(_demoCasts)
        ..sort((a, b) => (b['subscriber_count'] as int).compareTo(a['subscriber_count'] as int));
      return sorted.take(limit).toList();
    }
    final response = await _supabase
        .from('casts')
        .select('*, team:teams(*)')
        .eq('is_active', true)
        .order('subscriber_count', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================
  // Subscriptions
  // ============================================

  /// 구독 생성
  Future<Map<String, dynamic>> createSubscription({
    required String fanId,
    required String castId,
    required String tierCode,
  }) async {
    // 티어 조회
    final tier = await _supabase
        .from('subscription_tiers')
        .select()
        .eq('code', tierCode)
        .single();

    // 구독 생성
    final response = await _supabase.from('subscriptions').insert({
      'fan_id': fanId,
      'cast_id': castId,
      'tier_id': tier['id'],
      'expires_at':
          DateTime.now().add(const Duration(days: 30)).toIso8601String(),
    }).select().single();

    return response;
  }

  /// 내 구독 목록
  Future<List<Map<String, dynamic>>> getMySubscriptions(String fanId, {List<String>? subscribedCastIds}) async {
    if (isDemoMode) {
      // subscribedCastIds가 전달되면 동적으로 구독 목록 생성
      if (subscribedCastIds != null) {
        return subscribedCastIds.map((castId) {
          final cast = _demoCasts.firstWhere(
            (c) => c['id'] == castId,
            orElse: () => <String, dynamic>{},
          );
          if (cast.isEmpty) return null;

          final lastMessage = _demoLastMessages[castId];
          final unreadCount = _demoUnreadCounts[castId] ?? 0;

          return {
            'id': 'sub-$castId',
            'fan_id': fanId,
            'cast_id': castId,
            'is_active': true,
            'cast': cast,
            'tier': {'code': 'PREMIUM', 'name': '프리미엄', 'price_monthly': 9900},
            'last_message': lastMessage,
            'unread_count': unreadCount,
          };
        }).whereType<Map<String, dynamic>>().toList();
      }

      // 기본 데모 구독 목록 반환 (마지막 메시지 정보 추가)
      return _demoSubscriptions.map((sub) {
        final castId = sub['cast_id'] as String;
        return {
          ...sub,
          'last_message': _demoLastMessages[castId],
          'unread_count': _demoUnreadCounts[castId] ?? 0,
        };
      }).toList();
    }
    final response = await _supabase
        .from('subscriptions')
        .select('*, cast:casts(*, team:teams(*)), tier:subscription_tiers(*)')
        .eq('fan_id', fanId)
        .eq('is_active', true);
    return List<Map<String, dynamic>>.from(response);
  }

  /// 구독 여부 확인
  Future<Map<String, dynamic>?> getSubscription(
      String fanId, String castId) async {
    if (isDemoMode) {
      return _demoSubscriptions.where((s) => s['cast_id'] == castId).firstOrNull;
    }
    try {
      final response = await _supabase
          .from('subscriptions')
          .select('*, tier:subscription_tiers(*)')
          .eq('fan_id', fanId)
          .eq('cast_id', castId)
          .eq('is_active', true)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  // ============================================
  // Messages
  // ============================================

  /// 메시지 목록 조회 (채팅방)
  Future<List<Map<String, dynamic>>> getMessages(
    String castId, {
    int page = 1,
    int limit = 20,
  }) async {
    if (isDemoMode) {
      return _demoMessages.where((m) => m['cast_id'] == castId).toList();
    }
    final response = await _supabase
        .from('messages')
        .select('*, cast:casts(*)')
        .eq('cast_id', castId)
        .eq('is_deleted', false)
        .order('created_at', ascending: false)
        .range((page - 1) * limit, page * limit - 1);
    return List<Map<String, dynamic>>.from(response);
  }

  /// 메시지 실시간 구독
  RealtimeChannel subscribeToMessages(
    String castId,
    void Function(Map<String, dynamic>) onMessage,
  ) {
    return _supabase
        .channel('messages:$castId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'cast_id',
            value: castId,
          ),
          callback: (payload) {
            onMessage(payload.newRecord);
          },
        )
        .subscribe();
  }

  // ============================================
  // Replies
  // ============================================

  /// 답장 토큰 조회
  Future<Map<String, dynamic>?> getReplyToken(
    String subscriptionId,
    String messageId,
  ) async {
    try {
      final response = await _supabase
          .from('reply_tokens')
          .select()
          .eq('subscription_id', subscriptionId)
          .eq('message_id', messageId)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  /// 답장 작성
  Future<Map<String, dynamic>> createReply({
    required String messageId,
    required String fanId,
    required String subscriptionId,
    required String content,
  }) async {
    // 답장 생성
    final reply = await _supabase.from('replies').insert({
      'message_id': messageId,
      'fan_id': fanId,
      'subscription_id': subscriptionId,
      'content': content,
    }).select().single();

    // 토큰 사용 처리
    await _supabase.rpc('increment_reply_token_used', params: {
      'p_subscription_id': subscriptionId,
      'p_message_id': messageId,
    });

    return reply;
  }

  /// 내 답장 목록
  Future<List<Map<String, dynamic>>> getMyReplies(
    String fanId, {
    String? messageId,
  }) async {
    var query = _supabase
        .from('replies')
        .select('*, message:messages(*)')
        .eq('fan_id', fanId)
        .eq('is_hidden', false);

    if (messageId != null) {
      query = query.eq('message_id', messageId);
    }

    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================
  // Subscription Tiers & Milestones
  // ============================================

  /// 구독 티어 목록
  Future<List<Map<String, dynamic>>> getSubscriptionTiers() async {
    final response = await _supabase
        .from('subscription_tiers')
        .select()
        .eq('is_active', true)
        .order('price_monthly');
    return List<Map<String, dynamic>>.from(response);
  }

  /// 마일스톤 목록
  Future<List<Map<String, dynamic>>> getMilestones() async {
    final response = await _supabase
        .from('subscription_milestones')
        .select()
        .order('days');
    return List<Map<String, dynamic>>.from(response);
  }
}

/// Supabase 서비스 Provider
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return SupabaseService(supabase);
});
