import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/auth_service.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/snow_button.dart';

/// 회원가입 페이지
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        nickname: _nicknameController.text.trim(),
      );
      // 회원가입 성공 시 라우터가 자동으로 리다이렉트
    } catch (e) {
      setState(() {
        _errorMessage = '회원가입에 실패했습니다. 다시 시도해주세요.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.gradientVoid,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.space6),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppTheme.space10),

                  // 타이틀
                  Text(
                    'Join Us',
                    style: AppTypography.displayMedium.copyWith(
                      fontWeight: FontWeight.w300,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.space2),
                  Text(
                    '새로운 경험을 시작하세요',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textOnDarkMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppTheme.space10),

                  // 닉네임 입력
                  AuthTextField(
                    controller: _nicknameController,
                    hintText: '닉네임',
                    prefixIcon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '닉네임을 입력해주세요';
                      }
                      if (value.length < 2) {
                        return '닉네임은 2자 이상이어야 합니다';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppTheme.space4),

                  // 이메일 입력
                  AuthTextField(
                    controller: _emailController,
                    hintText: '이메일',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.mail_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '이메일을 입력해주세요';
                      }
                      if (!value.contains('@')) {
                        return '올바른 이메일 형식이 아닙니다';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppTheme.space4),

                  // 비밀번호 입력
                  AuthTextField(
                    controller: _passwordController,
                    hintText: '비밀번호',
                    obscureText: true,
                    prefixIcon: Icons.lock_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '비밀번호를 입력해주세요';
                      }
                      if (value.length < 8) {
                        return '비밀번호는 8자 이상이어야 합니다';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppTheme.space4),

                  // 비밀번호 확인
                  AuthTextField(
                    controller: _confirmPasswordController,
                    hintText: '비밀번호 확인',
                    obscureText: true,
                    prefixIcon: Icons.lock_outline,
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return '비밀번호가 일치하지 않습니다';
                      }
                      return null;
                    },
                  ),

                  // 에러 메시지
                  if (_errorMessage != null) ...[
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      _errorMessage!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.statusError,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: AppTheme.space8),

                  // 회원가입 버튼
                  SnowButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    isLoading: _isLoading,
                    child: const Text('회원가입'),
                  ),

                  const SizedBox(height: AppTheme.space4),

                  // 로그인 링크
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Text(
                      '이미 계정이 있으신가요? 로그인',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textOnDarkSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
