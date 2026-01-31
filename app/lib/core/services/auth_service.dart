import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase 클라이언트 Provider
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// 인증 상태 Provider (실시간 스트림)
final authStateProvider = StreamProvider<User?>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return supabase.auth.onAuthStateChange.map((event) => event.session?.user);
});

/// 현재 사용자 Provider
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

/// 인증 서비스
class AuthService {
  final SupabaseClient _supabase;

  AuthService(this._supabase);

  /// 이메일 회원가입
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String nickname,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'nickname': nickname},
    );
  }

  /// 이메일 로그인
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// 로그아웃
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// 비밀번호 재설정 이메일
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  /// 현재 세션
  Session? get currentSession => _supabase.auth.currentSession;

  /// 현재 사용자
  User? get currentUser => _supabase.auth.currentUser;

  /// 현재 사용자 ID
  String? get currentUserId => _supabase.auth.currentUser?.id;
}

/// 인증 서비스 Provider
final authServiceProvider = Provider<AuthService>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return AuthService(supabase);
});
