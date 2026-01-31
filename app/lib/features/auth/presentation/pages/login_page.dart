import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/widgets/snow_animation.dart';
import '../../../../main.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/snow_button.dart';

/// 로그인 페이지
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 데모 모드에서는 테스트 계정으로 로그인
      if (isDemoMode) {
        final email = _emailController.text.trim();
        final password = _passwordController.text;

        // 테스트 계정 확인
        if (email == 'test@test.com' && password == 'password') {
          ref.read(demoAuthStateProvider.notifier).state = true;
          if (mounted) context.go('/home');
          return;
        } else {
          throw Exception('Invalid credentials');
        }
      }

      final authService = ref.read(authServiceProvider);
      await authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // 로그인 성공 시 라우터가 자동으로 리다이렉트
    } catch (e) {
      setState(() {
        _errorMessage = '이메일 또는 비밀번호가 올바르지 않습니다.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 데모 로그인 (테스트 계정으로 자동 로그인)
  void _handleDemoLogin() {
    ref.read(demoAuthStateProvider.notifier).state = true;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SnowAnimation(
        snowflakeCount: 30,
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.gradientVoid,
          ),
          child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space6),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),

                  // 타이틀
                  Text(
                    'Welcome Back',
                    style: AppTypography.displayMedium.copyWith(
                      fontWeight: FontWeight.w300,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.space2),
                  Text(
                    '다시 만나서 반가워요',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textOnDarkMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppTheme.space10),

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

                  // 로그인 버튼
                  SnowButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    isLoading: _isLoading,
                    child: const Text('로그인'),
                  ),

                  const SizedBox(height: AppTheme.space4),

                  // 회원가입 링크
                  TextButton(
                    onPressed: () => context.push('/register'),
                    child: Text(
                      '계정이 없으신가요? 회원가입',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textOnDarkSecondary,
                      ),
                    ),
                  ),

                  // 데모 모드일 때만 데모 로그인 버튼 표시
                  if (isDemoMode) ...[
                    const SizedBox(height: AppTheme.space4),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.space4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '데모 모드',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.snowPearl,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppTheme.space2),
                          Text(
                            '테스트 계정: test@test.com / password',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textOnDarkMuted,
                            ),
                          ),
                          const SizedBox(height: AppTheme.space3),
                          TextButton(
                            onPressed: _handleDemoLogin,
                            child: Text(
                              '데모로 바로 시작하기',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.snowPure,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }
}
