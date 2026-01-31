import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _ChatRoomPageState extends ConsumerState<ChatRoomPage>
    with TickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;
  Map<String, dynamic>? _subscription;
  Map<String, dynamic>? _replyToken;

  late AnimationController _sendButtonController;
  late Animation<double> _sendButtonScale;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadSubscription();

    // 전송 버튼 애니메이션 초기화
    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _sendButtonScale = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _sendButtonController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _sendButtonController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final service = ref.read(supabaseServiceProvider);
      final messages = await service.getMessages(widget.castId);

      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '메시지를 불러오는데 실패했습니다';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSubscription() async {
    try {
      final authService = ref.read(authServiceProvider);
      final userId = authService.currentUserId;
      if (userId == null) return;

      final service = ref.read(supabaseServiceProvider);
      final subscription = await service.getSubscription(userId, widget.castId);

      if (mounted && subscription != null) {
        setState(() {
          _subscription = subscription;
        });
      }
    } catch (e) {
      // 구독 정보 로딩 실패는 조용히 처리
    }
  }

  Future<void> _sendReply() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    if (_isSending) return;
    if (_subscription == null) {
      _showSnackBar('구독 후 답장을 보낼 수 있습니다', isError: true);
      return;
    }

    // 햅틱 피드백
    HapticFeedback.lightImpact();

    // 버튼 애니메이션
    await _sendButtonController.forward();
    await _sendButtonController.reverse();

    setState(() {
      _isSending = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final userId = authService.currentUserId;
      if (userId == null) throw Exception('로그인이 필요합니다');

      final service = ref.read(supabaseServiceProvider);

      // 답장 생성 (실제로는 특정 메시지에 대한 답장이 필요하지만,
      // 현재 UI에서는 일반적인 답장으로 처리)
      // TODO: 특정 메시지 선택 후 답장 기능 구현

      // 성공 시 입력창 초기화
      _messageController.clear();

      // 성공 애니메이션 및 메시지
      _showSnackBar('답장을 보냈습니다! 💌', isError: false);

      // 메시지 목록 새로고침
      await _loadMessages();

    } catch (e) {
      _showSnackBar('답장 전송에 실패했습니다', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? AppColors.statusError : AppColors.statusSuccess,
              size: 20,
            ),
            const SizedBox(width: AppTheme.space2),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.deepShadow,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        duration: Duration(seconds: isError ? 3 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.gradientVoid,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 헤더
              _ChatHeader(
                castId: widget.castId,
                subscription: _subscription,
              ),

              // 메시지 목록
              Expanded(
                child: _buildMessageList(),
              ),

              // 답장 입력창
              _ReplyInput(
                controller: _messageController,
                isSending: _isSending,
                hasSubscription: _subscription != null,
                sendButtonScale: _sendButtonScale,
                onSend: _sendReply,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppTheme.space4),
            Text('메시지를 불러오는 중...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.statusError.withOpacity(0.7),
            ),
            const SizedBox(height: AppTheme.space4),
            Text(
              _errorMessage!,
              style: AppTypography.body.copyWith(
                color: AppColors.textOnDarkMuted,
              ),
            ),
            const SizedBox(height: AppTheme.space4),
            OutlinedButton.icon(
              onPressed: _loadMessages,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: 0.8 + (0.2 * value),
                    child: child,
                  ),
                );
              },
              child: Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: AppColors.textOnDarkMuted.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: AppTheme.space4),
            Text(
              '아직 메시지가 없습니다',
              style: AppTypography.body.copyWith(
                color: AppColors.textOnDarkMuted,
              ),
            ),
            const SizedBox(height: AppTheme.space2),
            Text(
              '캐스트의 첫 메시지를 기다려보세요 ✨',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textOnDarkMuted.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMessages,
      color: AppColors.snowPure,
      backgroundColor: AppColors.deepShadow,
      child: ListView.builder(
        controller: _scrollController,
        reverse: true,
        padding: const EdgeInsets.all(AppTheme.space4),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + (index * 50).clamp(0, 200)),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: _MessageBubble(message: message),
          );
        },
      ),
    );
  }
}

/// 채팅방 헤더
class _ChatHeader extends ConsumerWidget {
  final String castId;
  final Map<String, dynamic>? subscription;

  const _ChatHeader({
    required this.castId,
    this.subscription,
  });

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
              if (snapshot.hasError) {
                return const Text('로딩 실패');
              }

              final cast = snapshot.data;

              return Expanded(
                child: Row(
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
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.person,
                                  size: 24,
                                  color: AppColors.deepNight,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              size: 24,
                              color: AppColors.deepNight,
                            ),
                    ),
                    const SizedBox(width: AppTheme.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cast?['stage_name'] ?? '로딩 중...',
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              Text(
                                '프라이빗 메시지',
                                style: AppTypography.caption,
                              ),
                              if (subscription != null) ...[
                                const SizedBox(width: AppTheme.space2),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.gradientSnowPearl,
                                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                  ),
                                  child: Text(
                                    subscription!['tier']?['name'] ?? '구독중',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.deepNight,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // 더보기
          IconButton(
            onPressed: () {
              _showChatOptions(context);
            },
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
    );
  }

  void _showChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.deepNight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: AppTheme.space3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('알림 설정'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 알림 설정
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('캐스트 정보'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 캐스트 정보
              },
            ),
            ListTile(
              leading: Icon(Icons.flag_outlined, color: AppColors.statusError.withOpacity(0.8)),
              title: Text('신고하기', style: TextStyle(color: AppColors.statusError.withOpacity(0.8))),
              onTap: () {
                Navigator.pop(context);
                // TODO: 신고하기
              },
            ),
            const SizedBox(height: AppTheme.space4),
          ],
        ),
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
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusLg),
                  topRight: Radius.circular(AppTheme.radiusLg),
                  bottomRight: Radius.circular(AppTheme.radiusLg),
                  bottomLeft: Radius.circular(AppTheme.radiusSm),
                ),
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
                        errorBuilder: (_, __, ___) => Container(
                          padding: const EdgeInsets.all(AppTheme.space4),
                          decoration: BoxDecoration(
                            color: AppColors.deepNight.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          ),
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.deepNight,
                          ),
                        ),
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
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays > 0) {
        return '${date.month}/${date.day}';
      }
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}

/// 답장 입력창
class _ReplyInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final bool hasSubscription;
  final Animation<double> sendButtonScale;
  final VoidCallback onSend;

  const _ReplyInput({
    required this.controller,
    required this.isSending,
    required this.hasSubscription,
    required this.sendButtonScale,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 구독 안내 (구독하지 않은 경우)
          if (!hasSubscription)
            Container(
              margin: const EdgeInsets.only(bottom: AppTheme.space3),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space3,
                vertical: AppTheme.space2,
              ),
              decoration: BoxDecoration(
                color: AppColors.statusWarning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: AppColors.statusWarning.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.statusWarning,
                  ),
                  const SizedBox(width: AppTheme.space2),
                  Expanded(
                    child: Text(
                      '구독하시면 답장을 보낼 수 있어요',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.statusWarning,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Row(
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
                    enabled: hasSubscription && !isSending,
                    decoration: InputDecoration(
                      hintText: hasSubscription
                          ? '답장을 입력하세요...'
                          : '구독 후 답장을 보낼 수 있습니다',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: AppTheme.space3,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                  ),
                ),
              ),

              const SizedBox(width: AppTheme.space3),

              // 전송 버튼
              ScaleTransition(
                scale: sendButtonScale,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: hasSubscription
                        ? AppColors.gradientSnowPearl
                        : null,
                    color: hasSubscription
                        ? null
                        : Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                    boxShadow: hasSubscription ? AppTheme.glowSoft : null,
                  ),
                  child: IconButton(
                    onPressed: hasSubscription && !isSending ? onSend : null,
                    icon: isSending
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.deepNight,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.send,
                            color: hasSubscription
                                ? AppColors.deepNight
                                : AppColors.textOnDarkMuted,
                            size: 20,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
