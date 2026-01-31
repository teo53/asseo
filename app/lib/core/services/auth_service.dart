import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../main.dart';

/// Supabase 클라이언트 Provider
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// 데모 로그인 상태 Provider
final demoAuthStateProvider = StateProvider<bool>((ref) => false);

/// 인증 상태 Provider (실시간 스트림)
final authStateProvider = StreamProvider<User?>((ref) {
  // 데모 모드에서는 demoAuthStateProvider를 감시
  if (isDemoMode) {
    final isLoggedIn = ref.watch(demoAuthStateProvider);
    return Stream.value(isLoggedIn ? _createDemoUser() : null);
  }

  final supabase = ref.watch(supabaseProvider);

  // 초기 상태를 먼저 내보내고, 이후 변경사항을 스트림으로 전달
  return Stream.multi((controller) {
    // 현재 사용자 즉시 전달
    controller.add(supabase.auth.currentUser);

    // 이후 인증 상태 변경 구독
    final subscription = supabase.auth.onAuthStateChange.listen(
      (event) => controller.add(event.session?.user),
      onError: controller.addError,
    );

    controller.onCancel = () => subscription.cancel();
  });
});

/// 데모 사용자 생성 (User 타입 대신 null 반환하고 별도 처리)
User? _createDemoUser() {
  // Supabase User는 직접 생성 불가하므로 null 반환
  // 대신 demoAuthStateProvider로 로그인 상태 관리
  return null;
}

/// 데모 모드 로그인 여부 확인 Provider
final isDemoLoggedInProvider = Provider<bool>((ref) {
  if (isDemoMode) {
    return ref.watch(demoAuthStateProvider);
  }
  return ref.watch(authStateProvider).valueOrNull != null;
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
}

/// 인증 서비스 Provider
final authServiceProvider = Provider<AuthService>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return AuthService(supabase);
});
