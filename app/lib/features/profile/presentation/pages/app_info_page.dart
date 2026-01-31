import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../main.dart';

/// 앱 정보 페이지
class AppInfoPage extends StatelessWidget {
  const AppInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('앱 정보'),
        backgroundColor: AppColors.deepVoid,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.gradientVoid,
        ),
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.space6),
          children: [
            // 로고 및 앱 이름
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientSnowPearl,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      boxShadow: AppTheme.glowMedium,
                    ),
                    child: const Center(
                      child: Text(
                        'M',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w300,
                          color: AppColors.deepNight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.space4),
                  Text(
                    'MOE BACKSTAGE',
                    style: AppTypography.heading2.copyWith(
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space1),
                  Text(
                    'Version 1.0.0${isDemoMode ? ' (Demo)' : ''}',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.space10),

            // 정보 섹션
            _InfoSection(
              title: '앱 정보',
              items: [
                _InfoItem(label: '버전', value: '1.0.0'),
                _InfoItem(label: '빌드', value: '2024.01.30'),
                _InfoItem(label: '최소 OS', value: 'iOS 13.0 / Android 6.0'),
              ],
            ),

            const SizedBox(height: AppTheme.space4),

            // 법적 정보
            _InfoSection(
              title: '법적 정보',
              items: [
                _InfoLink(
                  label: '이용약관',
                  onTap: () => _showTermsDialog(context),
                ),
                _InfoLink(
                  label: '개인정보처리방침',
                  onTap: () => _showPrivacyDialog(context),
                ),
                _InfoLink(
                  label: '오픈소스 라이선스',
                  onTap: () => _showLicensesDialog(context),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.space4),

            // 개발 정보
            _InfoSection(
              title: '개발',
              items: [
                const _InfoItem(label: '개발', value: 'MOE Studio'),
                const _InfoItem(label: '디자인', value: 'MOE Design Team'),
                _InfoLink(
                  label: '피드백 보내기',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('피드백 기능은 준비 중입니다')),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: AppTheme.space10),

            // 카피라이트
            Center(
              child: Column(
                children: [
                  Text(
                    '© 2024 MOE Studio',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textOnDarkMuted,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space1),
                  Text(
                    'Made with ❤️ for fans',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textOnDarkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.deepShadow,
        title: const Text('이용약관'),
        content: const SingleChildScrollView(
          child: Text(
            '''MOE BACKSTAGE 이용약관

제1조 (목적)
이 약관은 MOE Studio가 운영하는 MOE BACKSTAGE(이하 "서비스")의 이용과 관련하여 회사와 회원 간의 권리, 의무 및 책임사항, 기타 필요한 사항을 규정함을 목적으로 합니다.

제2조 (정의)
1. "서비스"란 MOE BACKSTAGE 앱을 통해 제공되는 모든 서비스를 말합니다.
2. "회원"이란 서비스에 가입하여 이용하는 자를 말합니다.
3. "캐스트"란 서비스에서 콘텐츠를 제공하는 크리에이터를 말합니다.

제3조 (서비스의 제공)
회사는 다음과 같은 서비스를 제공합니다:
- 캐스트와 팬 간의 커뮤니케이션 서비스
- 유료 구독 서비스
- 디지털 화폐(DreamTime) 서비스

(이하 약관 전문은 웹사이트에서 확인하세요)''',
            style: AppTypography.bodySmall,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.deepShadow,
        title: const Text('개인정보처리방침'),
        content: const SingleChildScrollView(
          child: Text(
            '''MOE BACKSTAGE 개인정보처리방침

1. 개인정보의 수집 및 이용 목적
MOE Studio는 다음의 목적을 위하여 개인정보를 처리합니다:
- 회원 가입 및 관리
- 서비스 제공
- 결제 처리
- 고객 지원

2. 수집하는 개인정보 항목
- 필수: 이메일, 닉네임
- 선택: 프로필 사진
- 자동 수집: 기기 정보, 접속 로그

3. 개인정보의 보유 및 이용 기간
회원 탈퇴 시까지 또는 법령에 따른 보존 기간까지

4. 개인정보의 파기
회원 탈퇴 시 지체 없이 파기합니다.

(이하 전문은 웹사이트에서 확인하세요)''',
            style: AppTypography.bodySmall,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _showLicensesDialog(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'MOE BACKSTAGE',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2024 MOE Studio',
    );
  }
}

/// 정보 섹션
class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _InfoSection({
    required this.title,
    required this.items,
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
            children: items,
          ),
        ),
      ],
    );
  }
}

/// 정보 아이템
class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space4,
        vertical: AppTheme.space3,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.body,
          ),
          Text(
            value,
            style: AppTypography.body.copyWith(
              color: AppColors.textOnDarkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 정보 링크
class _InfoLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _InfoLink({
    required this.label,
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
            vertical: AppTheme.space3,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTypography.body,
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textOnDarkMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
