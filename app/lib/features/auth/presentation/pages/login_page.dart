import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/auth_service.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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

                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
