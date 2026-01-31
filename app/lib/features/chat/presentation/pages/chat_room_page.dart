import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/providers/demo_providers.dart';
import '../../../../main.dart';
import '../../../cast/presentation/widgets/donation_modal.dart';

/// 채팅방 페이지
class ChatRoomPage extends ConsumerStatefulWidget {
  final String castId;

  const ChatRoomPage({super.key, required this.castId});

  @override
  ConsumerState<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends ConsumerState<ChatRoomPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 채팅방 진입 시 읽음 처리
    if (isDemoMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(demoUnreadCountProvider.notifier).markAsRead(widget.castId);
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(supabaseServiceProvider);
    final userReplies = ref.watch(demoUserRepliesProvider(widget.castId));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.gradientVoid,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 헤더
              _ChatHeader(castId: widget.castId),

              // 메시지 목록
              Expanded(
                child: FutureBuilder(
                  future: service.getMessages(widget.castId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final castMessages = snapshot.data ?? [];

                    // 캐스트 메시지와 사용자 답장을 합쳐서 시간순 정렬
                    final allMessages = <Map<String, dynamic>>[
                      ...castMessages,
                      ...userReplies,
                    ];
                    allMessages.sort((a, b) {
                      final aTime = DateTime.parse(a['created_at']);
                      final bTime = DateTime.parse(b['created_at']);
                      return bTime.compareTo(aTime); // 최신순
                    });

                    if (allMessages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.message_outlined,
                              size: 48,
                              color: AppColors.textOnDarkMuted,
                            ),
                            const SizedBox(height: AppTheme.space4),
                            Text(
                              '아직 메시지가 없습니다',
                              style: AppTypography.body.copyWith(
                                color: AppColors.textOnDarkMuted,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.all(AppTheme.space4),
                      itemCount: allMessages.length,
                      itemBuilder: (context, index) {
                        final message = allMessages[index];
                        final isUserReply = message['is_user_reply'] == true;
                        return _MessageBubble(
                          message: message,
                          isUserMessage: isUserReply,
                        );
                      },
                    );
                  },
                ),
              ),

              // 답장 입력창
              _ReplyInput(
                controller: _messageController,
                castId: widget.castId,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 채팅방 헤더
class _ChatHeader extends ConsumerWidget {
  final String castId;

  const _ChatHeader({required this.castId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(supabaseServiceProvider);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space4,
        vertical: AppTheme.space3,
      ),
      decoration: BoxDecoration(
        color: AppColors.deepNight,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          // 뒤로가기
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
          ),

          // 캐스트 정보
          FutureBuilder(
            future: service.getCast(castId),
            builder: (context, snapshot) {
              final cast = snapshot.data;

              return Row(
                children: [
                  // 프로필 이미지
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.profileBackground,
                      border: Border.all(
                        color: AppColors.profileBorder,
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      size: 22,
                      color: AppColors.textOnDarkMuted,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space3),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cast?['stage_name'] ?? '로딩 중...',
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '프라이빗 메시지',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          const Spacer(),

          // 더보기
          IconButton(
            onPressed: () => _showChatSettings(context, ref, castId),
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
    );
  }

  void _showChatSettings(BuildContext context, WidgetRef ref, String castId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.deepShadow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppTheme.space2),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppTheme.space6),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('알림 설정'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('알림 설정이 변경되었습니다')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.block_outlined),
              title: const Text('알림 끄기'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('이 채팅방의 알림이 꺼졌습니다')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.cancel_outlined, color: AppColors.statusError),
              title: Text('구독 취소', style: TextStyle(color: AppColors.statusError)),
              onTap: () {
                Navigator.pop(context);
                _showUnsubscribeConfirm(context, ref, castId);
              },
            ),
            const SizedBox(height: AppTheme.space4),
          ],
        ),
      ),
    );
  }

  void _showUnsubscribeConfirm(BuildContext context, WidgetRef ref, String castId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.deepShadow,
        title: const Text('구독 취소'),
        content: const Text('정말 구독을 취소하시겠습니까?\n더 이상 프라이빗 메시지를 받을 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('아니오'),
          ),
          ElevatedButton(
            onPressed: () {
              if (isDemoMode) {
                ref.read(demoSubscriptionsProvider.notifier).unsubscribe(castId);
              }
              Navigator.pop(context);
              context.go('/chat');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('구독이 취소되었습니다')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusError,
            ),
            child: const Text('구독 취소'),
          ),
        ],
      ),
    );
  }
}

/// 메시지 버블
class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isUserMessage;

  const _MessageBubble({
    required this.message,
    this.isUserMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space4),
      child: Row(
        mainAxisAlignment: isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isUserMessage) ...[
            Text(
              _formatTime(message['created_at']),
              style: AppTypography.caption,
            ),
            const SizedBox(width: AppTheme.space2),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(AppTheme.space4),
              decoration: BoxDecoration(
                color: isUserMessage ? AppColors.bubbleUser : AppColors.bubbleCast,
                border: isUserMessage ? null : Border.all(
                  color: AppColors.bubbleCastBorder,
                  width: 1,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusLg),
                  topRight: Radius.circular(AppTheme.radiusLg),
                  bottomRight: Radius.circular(isUserMessage ? AppTheme.radiusSm : AppTheme.radiusLg),
                  bottomLeft: Radius.circular(isUserMessage ? AppTheme.radiusLg : AppTheme.radiusSm),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message['content'] != null)
                    Text(
                      message['content'],
                      style: AppTypography.body.copyWith(
                        color: AppColors.textOnDark,
                      ),
                    ),
                  if (message['media_url'] != null) ...[
                    const SizedBox(height: AppTheme.space2),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      child: Image.network(
                        message['media_url'],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (!isUserMessage) ...[
            const SizedBox(width: AppTheme.space2),
            Text(
              _formatTime(message['created_at']),
              style: AppTypography.caption,
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.parse(dateStr);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// 답장 입력창
class _ReplyInput extends ConsumerWidget {
  final TextEditingController controller;
  final String castId;

  const _ReplyInput({
    required this.controller,
    required this.castId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.only(
        left: AppTheme.space4,
        right: AppTheme.space4,
        top: AppTheme.space3,
        bottom: AppTheme.space3 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.deepNight,
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          // 후원 버튼
          _DonationButton(castId: castId),

          const SizedBox(width: AppTheme.space2),

          // 입력 필드
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space4,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: TextField(
                controller: controller,
                style: AppTypography.body,
                decoration: const InputDecoration(
                  hintText: '답장을 입력하세요...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: AppTheme.space3,
                  ),
                ),
                maxLines: null,
              ),
            ),
          ),

          const SizedBox(width: AppTheme.space3),

          // 전송 버튼
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.snowPure,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () => _sendReply(context, ref),
              icon: const Icon(
                Icons.send,
                color: AppColors.deepNight,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendReply(BuildContext context, WidgetRef ref) {
    final content = controller.text.trim();
    if (content.isEmpty) return;

    if (isDemoMode) {
      // 데모 모드: 로컬 상태에 메시지 추가
      ref.read(demoUserRepliesProvider(castId).notifier).addReply(content);
      controller.clear();

      // 피드백 스낵바
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('답장이 전송되었습니다!'),
          backgroundColor: AppColors.statusSuccess,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
      );
    } else {
      // 실제 모드: Supabase API 호출
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('실제 서버 연동이 필요합니다')),
      );
    }
  }
}

/// 채팅방 후원 버튼
class _DonationButton extends ConsumerWidget {
  final String castId;

  const _DonationButton({required this.castId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(supabaseServiceProvider);

    return FutureBuilder(
      future: service.getCast(castId),
      builder: (context, snapshot) {
        final cast = snapshot.data;

        return GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => DonationModal(
                cast: cast,
                castId: castId,
              ),
            );
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF4ECDC4).withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: const Color(0xFF4ECDC4).withOpacity(0.3),
              ),
            ),
            child: const Icon(
              Icons.favorite_outline,
              color: Color(0xFF4ECDC4),
              size: 22,
            ),
          ),
        );
      },
    );
  }
}
