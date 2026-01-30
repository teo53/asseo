import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/supabase_service.dart';

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
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(supabaseServiceProvider);

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

                    final messages = snapshot.data ?? [];

                    if (messages.isEmpty) {
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
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        return _MessageBubble(message: message);
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
                      gradient: AppColors.gradientSnowPearl,
                    ),
                    child: cast?['profile_image'] != null
                        ? ClipOval(
                            child: Image.network(
                              cast!['profile_image'],
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 24,
                            color: AppColors.deepNight,
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
            onPressed: () {
              // TODO: 채팅방 설정
            },
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
    );
  }
}

/// 메시지 버블
class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(AppTheme.space4),
              decoration: BoxDecoration(
                gradient: AppColors.gradientSnowPearl,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                borderBottomLeftRadius: Radius.circular(AppTheme.radiusSm),
                boxShadow: AppTheme.glowSoft,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message['content'] != null)
                    Text(
                      message['content'],
                      style: AppTypography.body.copyWith(
                        color: AppColors.deepNight,
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
          const SizedBox(width: AppTheme.space2),
          Text(
            _formatTime(message['created_at']),
            style: AppTypography.caption,
          ),
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
              gradient: AppColors.gradientSnowPearl,
              shape: BoxShape.circle,
              boxShadow: AppTheme.glowSoft,
            ),
            child: IconButton(
              onPressed: () {
                // TODO: 답장 전송
              },
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
}
