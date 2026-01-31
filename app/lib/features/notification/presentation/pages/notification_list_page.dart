import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/demo_providers.dart';

/// 알림 목록 페이지
class NotificationListPage extends ConsumerWidget {
  const NotificationListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(demoNotificationsProvider);
    final unreadCount = ref.watch(demoUnreadNotificationCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('알림'),
        backgroundColor: AppColors.deepVoid,
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () {
                ref.read(demoNotificationsProvider.notifier).markAllAsRead();
              },
              child: Text(
                '모두 읽음',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.snowPure,
                ),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.gradientVoid,
        ),
        child: notifications.isEmpty
            ? _EmptyState()
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.space2),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  return _NotificationItem(
                    notification: notif,
                    onTap: () {
                      // 읽음 처리
                      ref.read(demoNotificationsProvider.notifier).markAsRead(notif['id']);

                      // 액션 URL로 이동
                      final actionUrl = notif['action_url'] as String?;
                      if (actionUrl != null) {
                        context.push(actionUrl);
                      }
                    },
                  );
                },
              ),
      ),
    );
  }
}

/// 빈 상태
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: AppColors.textOnDarkMuted,
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            '알림이 없습니다',
            style: AppTypography.heading3.copyWith(
              color: AppColors.textOnDarkSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.space2),
          Text(
            '캐스트의 새 소식이 오면 알려드릴게요',
            style: AppTypography.body.copyWith(
              color: AppColors.textOnDarkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// 알림 아이템
class _NotificationItem extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;

  const _NotificationItem({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = notification['is_read'] as bool? ?? false;
    final type = notification['type'] as String;
    final createdAt = DateTime.parse(notification['created_at'] as String);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.space4,
        vertical: AppTheme.space1,
      ),
      decoration: BoxDecoration(
        color: isRead ? AppColors.deepShadow : AppColors.deepSlate,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isRead
              ? Colors.white.withOpacity(0.05)
              : AppColors.snowPearl.withOpacity(0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 아이콘
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _getIconBackgroundColor(type),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(
                    _getIcon(type),
                    color: _getIconColor(type),
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppTheme.space3),

                // 내용
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // 타입 뱃지
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getIconColor(type).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getTypeLabel(type),
                              style: AppTypography.caption.copyWith(
                                fontSize: 10,
                                color: _getIconColor(type),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatRelativeTime(createdAt),
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textOnDarkMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space2),
                      Text(
                        notification['title'] as String,
                        style: AppTypography.body.copyWith(
                          fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        notification['body'] as String,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textOnDarkSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // 읽지 않음 표시
                if (!isRead)
                  Container(
                    margin: const EdgeInsets.only(left: AppTheme.space2),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.snowPure,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'newMessage':
        return Icons.chat_bubble_outline;
      case 'newContent':
        return Icons.photo_library_outlined;
      case 'goodsDrop':
        return Icons.shopping_bag_outlined;
      case 'eventReminder':
        return Icons.event_outlined;
      case 'subscription':
        return Icons.person_add_outlined;
      case 'system':
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'newMessage':
        return const Color(0xFF4ECDC4);
      case 'newContent':
        return const Color(0xFFFF6B9D);
      case 'goodsDrop':
        return const Color(0xFFFFD93D);
      case 'eventReminder':
        return const Color(0xFF6BCB77);
      case 'subscription':
        return const Color(0xFFA66CFF);
      case 'system':
      default:
        return AppColors.snowPearl;
    }
  }

  Color _getIconBackgroundColor(String type) {
    return _getIconColor(type).withOpacity(0.15);
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'newMessage':
        return '메시지';
      case 'newContent':
        return '콘텐츠';
      case 'goodsDrop':
        return '굿즈';
      case 'eventReminder':
        return '이벤트';
      case 'subscription':
        return '구독';
      case 'system':
      default:
        return '시스템';
    }
  }

  String _formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return '방금';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${date.month}/${date.day}';
  }
}
