import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/demo_providers.dart';

/// 언어 설정 페이지
class LanguageSettingsPage extends ConsumerWidget {
  const LanguageSettingsPage({super.key});

  static const List<Map<String, String>> _languages = [
    {'code': 'ko', 'name': '한국어', 'nativeName': '한국어'},
    {'code': 'en', 'name': 'English', 'nativeName': 'English'},
    {'code': 'ja', 'name': '日本語', 'nativeName': '日本語'},
    {'code': 'zh', 'name': '中文', 'nativeName': '中文 (简体)'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(demoLanguageProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('언어 설정'),
        backgroundColor: AppColors.deepVoid,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.gradientVoid,
        ),
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.space4),
          children: [
            // 안내 문구
            Padding(
              padding: const EdgeInsets.all(AppTheme.space4),
              child: Text(
                '앱에서 사용할 언어를 선택하세요.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textOnDarkMuted,
                ),
              ),
            ),

            // 언어 목록
            Container(
              decoration: BoxDecoration(
                color: AppColors.deepShadow,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
              child: Column(
                children: _languages.map((lang) {
                  final isSelected = currentLanguage == lang['code'];
                  return _LanguageTile(
                    name: lang['name']!,
                    nativeName: lang['nativeName']!,
                    isSelected: isSelected,
                    onTap: () {
                      ref.read(demoLanguageProvider.notifier).state = lang['code']!;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${lang['name']}로 변경되었습니다'),
                          backgroundColor: AppColors.statusSuccess,
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: AppTheme.space6),

            // 안내 문구
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space2),
              child: Text(
                '언어 변경은 앱을 다시 시작할 때 완전히 적용됩니다.\n일부 콘텐츠는 원본 언어로 표시될 수 있습니다.',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textOnDarkMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 언어 타일
class _LanguageTile extends StatelessWidget {
  final String name;
  final String nativeName;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.name,
    required this.nativeName,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space4,
            vertical: AppTheme.space4,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nativeName,
                      style: AppTypography.body.copyWith(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? AppColors.snowPure : AppColors.textOnDark,
                      ),
                    ),
                    if (name != nativeName)
                      Text(
                        name,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textOnDarkMuted,
                        ),
                      ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: AppColors.statusSuccess,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
