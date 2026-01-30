import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { ReplyToken } from './entities/reply-token.entity';
import { Message } from './entities/message.entity';
import { Subscription } from '../subscriptions/entities/subscription.entity';
import { SubscriptionMilestone } from '../subscriptions/entities/subscription-milestone.entity';

@Injectable()
export class ReplyTokensService {
  constructor(
    @InjectRepository(ReplyToken)
    private readonly replyTokenRepository: Repository<ReplyToken>,
    @InjectRepository(Subscription)
    private readonly subscriptionRepository: Repository<Subscription>,
    @InjectRepository(SubscriptionMilestone)
    private readonly milestoneRepository: Repository<SubscriptionMilestone>,
  ) {}

  /**
   * 새 메시지에 대해 모든 구독자에게 답장 토큰 생성
   */
  async createTokensForMessage(message: Message): Promise<void> {
    // 해당 캐스트의 모든 활성 구독자 조회
    const subscriptions = await this.subscriptionRepository.find({
      where: { castId: message.castId, isActive: true },
      relations: ['tier'],
    });

    // 마일스톤 조회
    const milestones = await this.milestoneRepository.find({
      order: { days: 'ASC' },
    });

    const tokens: Partial<ReplyToken>[] = [];

    for (const subscription of subscriptions) {
      // 구독 일수 계산
      const daysSubscribed = Math.floor(
        (Date.now() - subscription.startedAt.getTime()) / (1000 * 60 * 60 * 24),
      );

      // 기본 글자 수
      let charLimit = subscription.tier.baseCharLimit;

      // 마일스톤 보너스 적용
      for (const milestone of milestones) {
        if (daysSubscribed >= milestone.days) {
          charLimit = subscription.tier.baseCharLimit + milestone.charLimitBonus;
        }
      }

      tokens.push({
        subscriptionId: subscription.id,
        messageId: message.id,
        total: subscription.tier.replyTokensPerMessage,
        used: 0,
        charLimit,
        expiresAt: new Date(message.createdAt.getTime() + 7 * 24 * 60 * 60 * 1000), // 7일 후 만료
      });
    }

    if (tokens.length > 0) {
      await this.replyTokenRepository.insert(tokens);
    }
  }

  /**
   * 특정 구독의 답장 토큰 통계
   */
  async getTokenStats(subscriptionId: string): Promise<{
    totalTokensGiven: number;
    totalTokensUsed: number;
    currentCharLimit: number;
  }> {
    const result = await this.replyTokenRepository
      .createQueryBuilder('token')
      .select('SUM(token.total)', 'totalGiven')
      .addSelect('SUM(token.used)', 'totalUsed')
      .addSelect('MAX(token.char_limit)', 'currentCharLimit')
      .where('token.subscription_id = :subscriptionId', { subscriptionId })
      .getRawOne();

    return {
      totalTokensGiven: parseInt(result.totalGiven) || 0,
      totalTokensUsed: parseInt(result.totalUsed) || 0,
      currentCharLimit: parseInt(result.currentCharLimit) || 50,
    };
  }
}
