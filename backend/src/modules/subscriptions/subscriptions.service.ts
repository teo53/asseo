import {
  Injectable,
  NotFoundException,
  ConflictException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { Subscription } from './entities/subscription.entity';
import { SubscriptionTier } from './entities/subscription-tier.entity';
import { SubscriptionMilestone } from './entities/subscription-milestone.entity';
import { CreateSubscriptionDto } from './dto/create-subscription.dto';

@Injectable()
export class SubscriptionsService {
  constructor(
    @InjectRepository(Subscription)
    private readonly subscriptionRepository: Repository<Subscription>,
    @InjectRepository(SubscriptionTier)
    private readonly tierRepository: Repository<SubscriptionTier>,
    @InjectRepository(SubscriptionMilestone)
    private readonly milestoneRepository: Repository<SubscriptionMilestone>,
  ) {}

  /**
   * 구독 생성
   */
  async create(
    fanId: string,
    createSubscriptionDto: CreateSubscriptionDto,
  ): Promise<Subscription> {
    const { castId, tierCode } = createSubscriptionDto;

    // 이미 구독 중인지 확인
    const existing = await this.subscriptionRepository.findOne({
      where: { fanId, castId },
    });

    if (existing && existing.isActive) {
      throw new ConflictException('이미 구독 중입니다.');
    }

    // 티어 조회
    const tier = await this.tierRepository.findOne({
      where: { code: tierCode, isActive: true },
    });

    if (!tier) {
      throw new NotFoundException('존재하지 않는 구독 티어입니다.');
    }

    // 기존 비활성 구독이 있으면 재활성화
    if (existing) {
      existing.tierId = tier.id;
      existing.isActive = true;
      existing.startedAt = new Date();
      existing.expiresAt = this.calculateExpiryDate();
      existing.cancelledAt = null;
      return this.subscriptionRepository.save(existing);
    }

    // 새 구독 생성
    const subscription = this.subscriptionRepository.create({
      fanId,
      castId,
      tierId: tier.id,
      startedAt: new Date(),
      expiresAt: this.calculateExpiryDate(),
    });

    return this.subscriptionRepository.save(subscription);
  }

  /**
   * 구독 취소
   */
  async cancel(id: string, fanId: string): Promise<Subscription> {
    const subscription = await this.subscriptionRepository.findOne({
      where: { id, fanId },
    });

    if (!subscription) {
      throw new NotFoundException('구독을 찾을 수 없습니다.');
    }

    subscription.isActive = false;
    subscription.cancelledAt = new Date();
    subscription.autoRenew = false;

    return this.subscriptionRepository.save(subscription);
  }

  /**
   * 활성 구독 조회
   */
  async findActiveSubscription(
    fanId: string,
    castId: string,
  ): Promise<Subscription | null> {
    return this.subscriptionRepository.findOne({
      where: { fanId, castId, isActive: true },
      relations: ['tier', 'cast'],
    });
  }

  /**
   * 팬의 구독 목록
   */
  async findByFanId(fanId: string): Promise<Subscription[]> {
    return this.subscriptionRepository.find({
      where: { fanId, isActive: true },
      relations: ['tier', 'cast'],
      order: { startedAt: 'DESC' },
    });
  }

  /**
   * 구독 상세 정보 (통계 포함)
   */
  async getSubscriptionDetails(id: string, fanId: string): Promise<{
    subscription: Subscription;
    daysSubscribed: number;
    currentCharLimit: number;
    currentMilestone: SubscriptionMilestone | null;
    nextMilestone: SubscriptionMilestone | null;
  }> {
    const subscription = await this.subscriptionRepository.findOne({
      where: { id, fanId },
      relations: ['tier', 'cast'],
    });

    if (!subscription) {
      throw new NotFoundException('구독을 찾을 수 없습니다.');
    }

    const daysSubscribed = Math.floor(
      (Date.now() - subscription.startedAt.getTime()) / (1000 * 60 * 60 * 24),
    );

    const milestones = await this.milestoneRepository.find({
      order: { days: 'ASC' },
    });

    let currentMilestone: SubscriptionMilestone | null = null;
    let nextMilestone: SubscriptionMilestone | null = null;

    for (let i = 0; i < milestones.length; i++) {
      if (daysSubscribed >= milestones[i].days) {
        currentMilestone = milestones[i];
      } else {
        nextMilestone = milestones[i];
        break;
      }
    }

    const currentCharLimit =
      subscription.tier.baseCharLimit +
      (currentMilestone?.charLimitBonus || 0);

    return {
      subscription,
      daysSubscribed,
      currentCharLimit,
      currentMilestone,
      nextMilestone,
    };
  }

  /**
   * 구독 티어 목록
   */
  async getTiers(): Promise<SubscriptionTier[]> {
    return this.tierRepository.find({
      where: { isActive: true },
      order: { priceMonthly: 'ASC' },
    });
  }

  /**
   * 마일스톤 목록
   */
  async getMilestones(): Promise<SubscriptionMilestone[]> {
    return this.milestoneRepository.find({
      order: { days: 'ASC' },
    });
  }

  /**
   * 구독 티어 변경
   */
  async changeTier(
    id: string,
    fanId: string,
    newTierCode: string,
  ): Promise<Subscription> {
    const subscription = await this.subscriptionRepository.findOne({
      where: { id, fanId, isActive: true },
    });

    if (!subscription) {
      throw new NotFoundException('활성 구독을 찾을 수 없습니다.');
    }

    const newTier = await this.tierRepository.findOne({
      where: { code: newTierCode, isActive: true },
    });

    if (!newTier) {
      throw new NotFoundException('존재하지 않는 구독 티어입니다.');
    }

    subscription.tierId = newTier.id;
    return this.subscriptionRepository.save(subscription);
  }

  private calculateExpiryDate(): Date {
    const expiry = new Date();
    expiry.setMonth(expiry.getMonth() + 1);
    return expiry;
  }
}
