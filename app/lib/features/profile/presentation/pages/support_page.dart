import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// 고객센터 페이지
class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  static const List<Map<String, String>> _faqs = [
    {
      'question': '구독은 어떻게 하나요?',
      'answer': '탐색 탭에서 마음에 드는 캐스트를 찾아 구독하기 버튼을 눌러주세요. 스탠다드, 프리미엄, VIP 중 원하는 티어를 선택하면 됩니다.',
    },
    {
      'question': 'DreamTime은 무엇인가요?',
      'answer': 'DreamTime(DT)은 MOE BACKSTAGE에서 사용하는 가상 화폐입니다. DT로 캐스트에게 후원하거나 특별한 콘텐츠를 구매할 수 있습니다.',
    },
    {
      'question': '구독 취소는 어떻게 하나요?',
      'answer': '채팅방에서 오른쪽 상단의 더보기(...) 버튼을 눌러 구독 취소를 선택하면 됩니다. 다음 결제일부터 구독이 해지됩니다.',
    },
    {
      'question': '환불은 가능한가요?',
      'answer': 'DreamTime 충전 후 7일 이내, 사용하지 않은 DT에 한해 환불이 가능합니다. 프로필 > 지갑 > 환불 신청에서 요청할 수 있습니다.',
    },
    {
      'question': '메시지에 답장하려면 어떻게 해야 하나요?',
      'answer': '프리미엄 이상의 구독 티어에서 답장 기능을 이용할 수 있습니다. 메시지 하단의 입력창에 답장을 작성해 보내주세요.',
    },
    {
      'question': '알림이 오지 않아요',
      'answer': '프로필 > 알림 설정에서 알림이 켜져 있는지 확인해주세요. 기기 설정에서도 MOE BACKSTAGE의 알림 권한을 허용해야 합니다.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('고객센터'),
        backgroundColor: AppColors.deepVoid,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.gradientVoid,
        ),
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.space4),
          children: [
            // 문의하기 버튼
            Container(
              margin: const EdgeInsets.only(bottom: AppTheme.space6),
              padding: const EdgeInsets.all(AppTheme.space4),
              decoration: BoxDecoration(
                gradient: AppColors.gradientSnowPearl,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space3),
                    decoration: BoxDecoration(
                      color: AppColors.deepNight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: const Icon(
                      Icons.headset_mic_outlined,
                      color: AppColors.deepNight,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '1:1 문의하기',
                          style: AppTypography.body.copyWith(
                            color: AppColors.deepNight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '평균 24시간 내 답변',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.deepNight.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.deepNight.withOpacity(0.5),
                  ),
                ],
              ),
            ),

            // FAQ 섹션
            Padding(
              padding: const EdgeInsets.only(
                left: AppTheme.space2,
                bottom: AppTheme.space3,
              ),
              child: Text(
                '자주 묻는 질문',
                style: AppTypography.heading3,
              ),
            ),

            // FAQ 목록
            ..._faqs.map((faq) => _FaqItem(
              question: faq['question']!,
              answer: faq['answer']!,
            )),

            const SizedBox(height: AppTheme.space6),

            // 연락처 정보
            Container(
              padding: const EdgeInsets.all(AppTheme.space4),
              decoration: BoxDecoration(
                color: AppColors.deepShadow,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '기타 문의',
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space3),
                  _ContactRow(
                    icon: Icons.email_outlined,
                    label: '이메일',
                    value: 'support@moebackstage.com',
                  ),
                  const SizedBox(height: AppTheme.space2),
                  _ContactRow(
                    icon: Icons.access_time,
                    label: '운영 시간',
                    value: '평일 10:00 - 18:00 (공휴일 제외)',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// FAQ 아이템
class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqItem({
    required this.question,
    required this.answer,
  });

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space2),
      decoration: BoxDecoration(
        color: AppColors.deepShadow,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.question,
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.textOnDarkMuted,
                    ),
                  ],
                ),
                if (_isExpanded) ...[
                  const SizedBox(height: AppTheme.space3),
                  Container(
                    width: double.infinity,
                    height: 1,
                    color: Colors.white.withOpacity(0.05),
                  ),
                  const SizedBox(height: AppTheme.space3),
                  Text(
                    widget.answer,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textOnDarkSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 연락처 행
class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textOnDarkMuted,
        ),
        const SizedBox(width: AppTheme.space2),
        Text(
          '$label: ',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textOnDarkMuted,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textOnDarkSecondary,
          ),
        ),
      ],
    );
  }
}
