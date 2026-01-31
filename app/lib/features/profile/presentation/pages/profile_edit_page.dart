import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/demo_providers.dart';
import '../../../../main.dart';

/// 프로필 수정 페이지
class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({super.key});

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  late TextEditingController _nicknameController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(demoProfileProvider);
    _nicknameController = TextEditingController(text: profile['nickname'] ?? '');
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(demoProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 수정'),
        backgroundColor: AppColors.deepVoid,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('저장'),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.gradientVoid,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.space6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppTheme.space6),

              // 프로필 아이콘
              Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.profileBackground,
                      border: Border.all(
                        color: AppColors.profileBorder,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      size: 60,
                      color: AppColors.textOnDarkMuted,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _changeProfileImage,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.snowPure,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.deepNight,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: AppColors.deepNight,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppTheme.space8),

              // 닉네임 입력
              Container(
                decoration: BoxDecoration(
                  color: AppColors.deepShadow,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: TextField(
                  controller: _nicknameController,
                  style: AppTypography.body,
                  decoration: InputDecoration(
                    labelText: '닉네임',
                    labelStyle: AppTypography.bodySmall.copyWith(
                      color: AppColors.textOnDarkMuted,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(AppTheme.space4),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => _nicknameController.clear(),
                    ),
                  ),
                  maxLength: 20,
                  buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                    return Padding(
                      padding: const EdgeInsets.only(right: AppTheme.space2),
                      child: Text(
                        '$currentLength/$maxLength',
                        style: AppTypography.caption,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: AppTheme.space4),

              // 이메일 (수정 불가)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.space4),
                decoration: BoxDecoration(
                  color: AppColors.deepShadow,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '이메일',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textOnDarkMuted,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space1),
                    Text(
                      profile['email'] ?? 'test@test.com',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textOnDarkSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.space2),
              Text(
                '이메일은 변경할 수 없습니다',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textOnDarkMuted,
                ),
              ),

              const SizedBox(height: AppTheme.space10),

              // 계정 삭제
              TextButton(
                onPressed: () => _showDeleteAccountDialog(),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.statusError,
                ),
                child: const Text('계정 삭제'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _changeProfileImage() {
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
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('갤러리에서 선택'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('데모 모드에서는 이미지 변경이 제한됩니다')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('카메라로 촬영'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('데모 모드에서는 이미지 변경이 제한됩니다')),
                );
              },
            ),
            if (ref.read(demoProfileProvider)['profile_image'] != null)
              ListTile(
                leading: Icon(Icons.delete_outline, color: AppColors.statusError),
                title: Text('프로필 사진 삭제', style: TextStyle(color: AppColors.statusError)),
                onTap: () {
                  ref.read(demoProfileProvider.notifier).updateProfileImage(null);
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: AppTheme.space4),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임을 입력해주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // 데모 모드에서는 로컬 상태 업데이트
    await Future.delayed(const Duration(milliseconds: 500)); // 시뮬레이션

    if (isDemoMode) {
      ref.read(demoProfileProvider.notifier).updateNickname(nickname);
    }

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('프로필이 저장되었습니다'),
          backgroundColor: AppColors.statusSuccess,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.deepShadow,
        title: const Text('계정 삭제'),
        content: const Text(
          '정말 계정을 삭제하시겠습니까?\n모든 데이터가 영구적으로 삭제되며 복구할 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('데모 모드에서는 계정 삭제가 제한됩니다')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusError,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}
