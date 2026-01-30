import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { Content, ContentType } from './entities/content.entity';
import { SubscriptionsService } from '../subscriptions/subscriptions.service';

@Injectable()
export class ContentsService {
  constructor(
    @InjectRepository(Content)
    private readonly contentRepository: Repository<Content>,
    private readonly subscriptionsService: SubscriptionsService,
  ) {}

  /**
   * 캐스트의 콘텐츠 목록 조회
   */
  async findByCastId(
    castId: string,
    userId: string,
    options?: { page?: number; limit?: number; type?: ContentType },
  ): Promise<{ contents: Content[]; total: number; hasMore: boolean }> {
    const { page = 1, limit = 20, type } = options || {};

    // 구독 확인
    const subscription = await this.subscriptionsService.findActiveSubscription(
      userId,
      castId,
    );

    if (!subscription) {
      throw new ForbiddenException('구독이 필요합니다.');
    }

    const queryBuilder = this.contentRepository
      .createQueryBuilder('content')
      .where('content.cast_id = :castId', { castId })
      .andWhere('content.is_deleted = false');

    if (type) {
      queryBuilder.andWhere('content.type = :type', { type });
    }

    const total = await queryBuilder.getCount();

    const contents = await queryBuilder
      .orderBy('content.created_at', 'DESC')
      .skip((page - 1) * limit)
      .take(limit)
      .getMany();

    // 티어에 따른 필터링
    const tierPriority: Record<string, number> = { BASIC: 1, PREMIUM: 2, ULTIMATE: 3 };
    const userTierLevel = tierPriority[subscription.tier.code] || 1;

    const filteredContents = contents.map((content) => {
      const requiredLevel = tierPriority[content.tierRequired] || 1;
      if (userTierLevel < requiredLevel) {
        // 티어 부족 시 썸네일만 제공
        return {
          ...content,
          mediaUrl: null,
          isLocked: true,
        };
      }
      return { ...content, isLocked: false };
    });

    return {
      contents: filteredContents as any,
      total,
      hasMore: page * limit < total,
    };
  }

  /**
   * 콘텐츠 상세 조회
   */
  async findById(id: string, userId: string): Promise<Content> {
    const content = await this.contentRepository.findOne({
      where: { id, isDeleted: false },
      relations: ['cast'],
    });

    if (!content) {
      throw new NotFoundException('콘텐츠를 찾을 수 없습니다.');
    }

    // 구독 확인
    const subscription = await this.subscriptionsService.findActiveSubscription(
      userId,
      content.castId,
    );

    if (!subscription) {
      throw new ForbiddenException('구독이 필요합니다.');
    }

    // 조회수 증가
    await this.contentRepository.increment({ id }, 'viewCount', 1);

    return content;
  }

  /**
   * 캐스트가 콘텐츠 업로드
   */
  async create(
    castId: string,
    data: Partial<Content>,
  ): Promise<Content> {
    const content = this.contentRepository.create({
      castId,
      ...data,
    });

    return this.contentRepository.save(content);
  }

  /**
   * 콘텐츠 삭제
   */
  async delete(id: string, castId: string): Promise<void> {
    const content = await this.contentRepository.findOne({
      where: { id, castId },
    });

    if (!content) {
      throw new NotFoundException('콘텐츠를 찾을 수 없습니다.');
    }

    content.isDeleted = true;
    await this.contentRepository.save(content);
  }
}
