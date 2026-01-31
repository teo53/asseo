import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 사전예약 상태 모델
class PreregistrationState {
  final bool isRegistered;
  final String? phone;
  final String? email;
  final int totalCount;
  final bool isLoading;
  final String? error;

  const PreregistrationState({
    this.isRegistered = false,
    this.phone,
    this.email,
    this.totalCount = 12847,
    this.isLoading = false,
    this.error,
  });

  PreregistrationState copyWith({
    bool? isRegistered,
    String? phone,
    String? email,
    int? totalCount,
    bool? isLoading,
    String? error,
  }) {
    return PreregistrationState(
      isRegistered: isRegistered ?? this.isRegistered,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      totalCount: totalCount ?? this.totalCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 사전예약 Provider
final preregistrationProvider =
    StateNotifierProvider<PreregistrationNotifier, PreregistrationState>((ref) {
  return PreregistrationNotifier();
});

class PreregistrationNotifier extends StateNotifier<PreregistrationState> {
  PreregistrationNotifier() : super(const PreregistrationState()) {
    _loadSavedState();
  }

  static const String _phoneKey = 'preregistration_phone';
  static const String _emailKey = 'preregistration_email';
  static const String _countKey = 'preregistration_count';
  static const int _baseCount = 12847;

  /// 저장된 상태 로드
  Future<void> _loadSavedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPhone = prefs.getString(_phoneKey);
      final savedEmail = prefs.getString(_emailKey);
      final additionalCount = prefs.getInt(_countKey) ?? 0;

      state = state.copyWith(
        isRegistered: savedPhone != null,
        phone: savedPhone,
        email: savedEmail,
        totalCount: _baseCount + additionalCount,
      );
    } catch (e) {
      // SharedPreferences 로드 실패 시 기본값 유지
    }
  }

  /// 전화번호 유효성 검사 (한국 전화번호)
  bool isValidPhone(String phone) {
    // 하이픈 제거 후 검사
    final cleanPhone = phone.replaceAll('-', '');
    // 010, 011, 016, 017, 018, 019 시작, 10-11자리
    final phoneRegex = RegExp(r'^01[016789]\d{7,8}$');
    return phoneRegex.hasMatch(cleanPhone);
  }

  /// 이메일 유효성 검사
  bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// 에러 설정
  void setError(String message) {
    state = state.copyWith(error: message);
  }

  /// 사전예약 등록
  Future<bool> register({required String phone, String? email}) async {
    // 전화번호 유효성 검사
    if (!isValidPhone(phone)) {
      state = state.copyWith(error: '올바른 전화번호를 입력해주세요');
      return false;
    }

    // 이메일이 입력된 경우 유효성 검사
    if (email != null && email.isNotEmpty && !isValidEmail(email)) {
      state = state.copyWith(error: '올바른 이메일 주소를 입력해주세요');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // 시뮬레이션: 실제로는 서버에 저장
      await Future.delayed(const Duration(milliseconds: 800));

      final prefs = await SharedPreferences.getInstance();

      // 이미 등록된 전화번호인지 확인
      final savedPhone = prefs.getString(_phoneKey);
      if (savedPhone == phone) {
        state = state.copyWith(
          isLoading: false,
          error: '이미 등록된 전화번호입니다',
        );
        return false;
      }

      // 새 등록 저장
      await prefs.setString(_phoneKey, phone);
      if (email != null && email.isNotEmpty) {
        await prefs.setString(_emailKey, email);
      }

      // 등록 카운트 증가
      final currentAdditional = prefs.getInt(_countKey) ?? 0;
      await prefs.setInt(_countKey, currentAdditional + 1);

      state = state.copyWith(
        isRegistered: true,
        phone: phone,
        email: email,
        totalCount: _baseCount + currentAdditional + 1,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '등록 중 오류가 발생했습니다. 다시 시도해주세요.',
      );
      return false;
    }
  }

  /// 에러 초기화
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// 런칭일 (예시: 30일 후)
final launchDateProvider = Provider<DateTime>((ref) {
  return DateTime.now().add(const Duration(days: 30));
});

/// 런칭까지 남은 시간
final timeUntilLaunchProvider = StreamProvider<Duration>((ref) {
  final launchDate = ref.watch(launchDateProvider);

  return Stream.periodic(const Duration(seconds: 1), (_) {
    final now = DateTime.now();
    final difference = launchDate.difference(now);
    return difference.isNegative ? Duration.zero : difference;
  });
});
