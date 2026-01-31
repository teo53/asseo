import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/demo_providers.dart';

/// 알림 설정 페이지
class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(demoNotificationSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('알림 설정'),
        backgroundColor: AppColors.deepVoid,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.gradientVoid,
        ),
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.space4),
          children: [
            // 전체 알림
            _SettingSection(
              title: '전체 알림',
              children: [
                _SwitchTile(
                  title: '푸시 알림',
                  subtitle: '앱 알림을 받습니다',
                  value: settings['push_enabled'] ?? true,
                  onChanged: (value) {
                    ref.read(demoNotificationSettingsProvider.notifier).set('push_enabled', value);
                  },
                ),
              ],
            ),

            const SizedBox(height: AppTheme.space4),

            // 메시지 알림
            _SettingSection(
              title: '메시지 알림',
              children: [
                _SwitchTile(
                  title: '새 메시지',
                  subtitle: '구독한 캐스트의 새 메시지 알림',
                  value: settings['new_message'] ?? true,
                  onChanged: settings['push_enabled'] == true
                      ? (value) {
                          ref.read(demoNotificationSettingsProvider.notifier).set('new_message', value);
                        }
                      : null,
                ),
                _SwitchTile(
                  title: '새 콘텐츠',
                  subtitle: '구독한 캐스트의 새 콘텐츠 알림',
                  value: settings['new_content'] ?? true,
                  onChanged: settings['push_enabled'] == true
                      ? (value) {
                          ref.read(demoNotificationSettingsProvider.notifier).set('new_content', value);
                        }
                      : null,
                ),
              ],
            ),

            const SizedBox(height: AppTheme.space4),

            // 마케팅 알림
            _SettingSection(
              title: '마케팅',
              children: [
                _SwitchTile(
                  title: '마케팅 알림',
                  subtitle: '이벤트, 프로모션 등의 알림',
                  value: settings['marketing'] ?? false,
                  onChanged: settings['push_enabled'] == true
                      ? (value) {
                          ref.read(demoNotificationSettingsProvider.notifier).set('marketing', value);
                        }
                      : null,
                ),
              ],
            ),

            const SizedBox(height: AppTheme.space6),

            // 안내 문구
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space2),
              child: Text(
                '푸시 알림을 끄면 모든 알림이 비활성화됩니다.\n기기 설정에서도 알림을 관리할 수 있습니다.',
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

/// 설정 섹션
class _SettingSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppTheme.space2,
            bottom: AppTheme.space2,
          ),
          child: Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textOnDarkMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.deepShadow,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: Colors.white.withOpacity(0.05),
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

/// 스위치 타일
class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onChanged != null;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space4,
        vertical: AppTheme.space3,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body.copyWith(
                    color: isEnabled ? AppColors.textOnDark : AppColors.textOnDarkMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textOnDarkMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.snowPure,
            activeTrackColor: AppColors.snowPearl.withOpacity(0.5),
          ),
        ],
      ),
    );
  }
}
