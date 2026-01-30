import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';

/// Supabase Database 서비스
class SupabaseService {
  final SupabaseClient _supabase;

  SupabaseService(this._supabase);

  // ============================================
  // Profiles
  // ============================================

  /// 프로필 조회
  Future<Map<String, dynamic>?> getProfile(String userId) async {
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
    final response = await _supabase
        .from('casts')
        .select('*, team:teams(*)')
        .eq('id', castId)
        .single();
    return response;
  }

  /// 인기 캐스트
  Future<List<Map<String, dynamic>>> getPopularCasts({int limit = 10}) async {
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
  Future<List<Map<String, dynamic>>> getMySubscriptions(String fanId) async {
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
