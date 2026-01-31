import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../providers/preregistration_provider.dart';

/// 사전예약 입력 폼 (이메일 + 전화번호)
class PreregistrationForm extends ConsumerStatefulWidget {
  final VoidCallback? onSuccess;

  const PreregistrationForm({super.key, this.onSuccess});

  @override
  ConsumerState<PreregistrationForm> createState() => _PreregistrationFormState();
}

class _PreregistrationFormState extends ConsumerState<PreregistrationForm> {
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  bool _isPhoneFocused = false;
  bool _isEmailFocused = false;

  @override
  void initState() {
    super.initState();
    _phoneFocusNode.addListener(() {
      setState(() => _isPhoneFocused = _phoneFocusNode.hasFocus);
    });
    _emailFocusNode.addListener(() {
      setState(() => _isEmailFocused = _emailFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _phoneFocusNode.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();

    if (phone.isEmpty) {
      ref.read(preregistrationProvider.notifier).setError('전화번호를 입력해주세요');
      return;
    }

    final notifier = ref.read(preregistrationProvider.notifier);
    final success = await notifier.register(phone: phone, email: email.isEmpty ? null : email);

    if (success && mounted) {
      widget.onSuccess?.call();
      _phoneController.clear();
      _emailController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(preregistrationProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 640;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 전화번호 입력 (필수)
        _buildPhoneField(state),
        const SizedBox(height: AppTheme.space3),

        // 이메일 입력 (선택)
        _buildEmailField(state),
        const SizedBox(height: AppTheme.space4),

        // 제출 버튼
        _buildSubmitButton(state),

        // 에러 메시지
        if (state.error != null) ...[
          const SizedBox(height: AppTheme.space2),
          Text(
            state.error!,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.statusError,
            ),
            textAlign: TextAlign.center,
          ),
        ],

        // 안내 문구
        const SizedBox(height: AppTheme.space3),
        Text(
          '* 전화번호로 런칭 알림을 보내드려요',
          style: AppTypography.caption.copyWith(
            color: AppColors.textOnDarkMuted,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPhoneField(PreregistrationState state) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: _isPhoneFocused
              ? AppColors.snowPure
              : state.error != null
                  ? AppColors.statusError
                  : Colors.white.withOpacity(0.2),
          width: _isPhoneFocused ? 2 : 1,
        ),
        boxShadow: _isPhoneFocused
            ? [
                BoxShadow(
                  color: AppColors.snowPure.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: _phoneController,
        focusNode: _phoneFocusNode,
        enabled: !state.isLoading,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.next,
        onSubmitted: (_) => _emailFocusNode.requestFocus(),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          _PhoneNumberFormatter(),
        ],
        style: AppTypography.body.copyWith(
          color: AppColors.textOnDark,
          letterSpacing: 1,
        ),
        decoration: InputDecoration(
          hintText: '전화번호 (필수)',
          hintStyle: AppTypography.body.copyWith(
            color: AppColors.textOnDarkMuted,
            letterSpacing: 0,
          ),
          prefixIcon: Icon(
            Icons.phone_android,
            color: _isPhoneFocused
                ? AppColors.snowPure
                : AppColors.textOnDarkMuted,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space4,
            vertical: AppTheme.space4,
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField(PreregistrationState state) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: _isEmailFocused
              ? AppColors.snowPure
              : Colors.white.withOpacity(0.15),
          width: _isEmailFocused ? 2 : 1,
        ),
        boxShadow: _isEmailFocused
            ? [
                BoxShadow(
                  color: AppColors.snowPure.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: _emailController,
        focusNode: _emailFocusNode,
        enabled: !state.isLoading,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        style: AppTypography.body.copyWith(
          color: AppColors.textOnDark,
        ),
        decoration: InputDecoration(
          hintText: '이메일 (선택)',
          hintStyle: AppTypography.body.copyWith(
            color: AppColors.textOnDarkMuted,
          ),
          prefixIcon: Icon(
            Icons.email_outlined,
            color: _isEmailFocused
                ? AppColors.snowPure
                : AppColors.textOnDarkMuted,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space4,
            vertical: AppTheme.space4,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(PreregistrationState state) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: state.isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.snowPure,
          foregroundColor: AppColors.deepNight,
          disabledBackgroundColor: AppColors.snowPure.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          elevation: 0,
        ),
        child: state.isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.deepNight,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_active, size: 20),
                  const SizedBox(width: AppTheme.space2),
                  Text(
                    '사전예약하기',
                    style: AppTypography.button.copyWith(
                      color: AppColors.deepNight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// 전화번호 포맷터 (010-1234-5678)
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    final buffer = StringBuffer();
    for (int i = 0; i < text.length && i < 11; i++) {
      if (i == 3 || i == 7) {
        buffer.write('-');
      }
      buffer.write(text[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

/// 성공 모달
class RegistrationSuccessModal extends StatelessWidget {
  final String phone;
  final String? email;
  final VoidCallback onClose;

  const RegistrationSuccessModal({
    super.key,
    required this.phone,
    this.email,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(AppTheme.space6),
        decoration: BoxDecoration(
          color: AppColors.deepShadow,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.snowPure.withOpacity(0.1),
              blurRadius: 40,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 축하 아이콘
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.gradientSnowPearl,
                boxShadow: AppTheme.glowMedium,
              ),
              child: const Icon(
                Icons.celebration,
                size: 40,
                color: AppColors.deepNight,
              ),
            ),
            const SizedBox(height: AppTheme.space6),

            // 타이틀
            Text(
              '사전예약 완료!',
              style: AppTypography.heading2,
            ),
            const SizedBox(height: AppTheme.space2),

            // 설명
            Text(
              '런칭 알림을 보내드릴게요',
              style: AppTypography.body.copyWith(
                color: AppColors.textOnDarkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space4),

            // 등록 정보
            Container(
              padding: const EdgeInsets.all(AppTheme.space4),
              decoration: BoxDecoration(
                color: AppColors.deepNight,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_android,
                        size: 16,
                        color: AppColors.snowPure,
                      ),
                      const SizedBox(width: AppTheme.space2),
                      Text(
                        phone,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.snowPure,
                        ),
                      ),
                    ],
                  ),
                  if (email != null) ...[
                    const SizedBox(height: AppTheme.space2),
                    Row(
                      children: [
                        const Icon(
                          Icons.email_outlined,
                          size: 16,
                          color: AppColors.textOnDarkMuted,
                        ),
                        const SizedBox(width: AppTheme.space2),
                        Text(
                          email!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textOnDarkMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space6),

            // 혜택 안내
            Container(
              padding: const EdgeInsets.all(AppTheme.space4),
              decoration: BoxDecoration(
                color: AppColors.deepNight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Column(
                children: [
                  Text(
                    '사전예약 혜택',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textOnDarkMuted,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space2),
                  _buildBenefit('첫 달 무료 이용'),
                  _buildBenefit('한정판 프로필 배지'),
                  _buildBenefit('얼리버드 전용 굿즈 할인'),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space6),

            // 닫기 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.snowPure,
                  foregroundColor: AppColors.deepNight,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.space4,
                  ),
                ),
                child: const Text('확인'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefit(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            size: 16,
            color: AppColors.statusSuccess,
          ),
          const SizedBox(width: AppTheme.space2),
          Text(
            text,
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }
}
