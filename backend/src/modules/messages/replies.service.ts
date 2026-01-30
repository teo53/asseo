import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { Reply } from './entities/reply.entity';
import { ReplyToken } from './entities/reply-token.entity';
import { CreateReplyDto } from './dto/create-reply.dto';
import { SubscriptionsService } from '../subscriptions/subscriptions.service';
import { ModerationService } from '../../shared/moderation/moderation.service';

@Injectable()
export class RepliesService {
  constructor(
    @InjectRepository(Reply)
    private readonly replyRepository: Repository<Reply>,
    @InjectRepository(ReplyToken)
    private readonly replyTokenRepository: Repository<ReplyToken>,
    private readonly subscriptionsService: SubscriptionsService,
    private readonly moderationService: ModerationService,
  ) {}

  /**
   * 팬이 메시지에 답장을 보냅니다
   */
  async create(
    messageId: string,
    fanId: string,
    createReplyDto: CreateReplyDto,
  ): Promise<Reply> {
    // 답장 토큰 조회
    const replyToken = await this.replyTokenRepository.findOne({
      where: {
        messageId,
        subscription: { fanId },
      },
      relations: ['subscription'],
    });

    if (!replyToken) {
      throw new ForbiddenException('이 메시지에 답장할 권한이 없습니다.');
    }

    // 토큰 사용 가능 여부 확인
    if (replyToken.used >= replyToken.total) {
      throw new BadRequestException('답장 가능 횟수를 초과했습니다.');
    }

    // 만료 확인
    if (replyToken.expiresAt && new Date() > replyToken.expiresAt) {
      throw new BadRequestException('답장 기간이 만료되었습니다.');
    }

    // 글자 수 확인
    if (createReplyDto.content.length > replyToken.charLimit) {
      throw new BadRequestException(
        `답장은 ${replyToken.charLimit}자 이내로 작성해주세요.`,
      );
    }

    // 콘텐츠 모더레이션
    const moderationResult = await this.moderationService.checkContent(
      createReplyDto.content,
    );

    if (moderationResult.blocked) {
      throw new BadRequestException(
        moderationResult.reason || '부적절한 내용이 포함되어 있습니다.',
      );
    }

    // 답장 생성
    const reply = this.replyRepository.create({
      messageId,
      fanId,
      subscriptionId: replyToken.subscriptionId,
      content: createReplyDto.content,
    });

    const savedReply = await this.replyRepository.save(reply);

    // 토큰 사용 처리
    replyToken.used += 1;
    await this.replyTokenRepository.save(replyToken);

    return savedReply;
  }

  /**
   * 캐스트가 받은 답장 목록 조회
   */
  async findRepliesForCast(
    castId: string,
    page = 1,
    limit = 20,
    unreadOnly = false,
  ): Promise<{ replies: Reply[]; total: number; hasMore: boolean }> {
    const queryBuilder = this.replyRepository
      .createQueryBuilder('reply')
      .innerJoin('messages', 'message', 'message.id = reply.message_id')
      .leftJoinAndSelect('reply.fan', 'fan')
      .leftJoinAndSelect('reply.message', 'msg')
      .where('message.cast_id = :castId', { castId })
      .andWhere('reply.is_hidden = false');

    if (unreadOnly) {
      queryBuilder.andWhere('reply.is_read_by_cast = false');
    }

    const total = await queryBuilder.getCount();

    const replies = await queryBuilder
      .orderBy('reply.created_at', 'DESC')
      .skip((page - 1) * limit)
      .take(limit)
      .getMany();

    return {
      replies,
      total,
      hasMore: page * limit < total,
    };
  }

  /**
   * 답장 읽음 처리 (캐스트)
   */
  async markAsReadByCast(replyIds: string[], castId: string): Promise<void> {
    await this.replyRepository
      .createQueryBuilder()
      .update(Reply)
      .set({ isReadByCast: true, readAt: new Date() })
      .whereInIds(replyIds)
      .execute();
  }

  /**
   * 팬의 답장 목록 조회
   */
  async findRepliesByFan(
    fanId: string,
    messageId?: string,
  ): Promise<Reply[]> {
    const where: any = { fanId, isHidden: false };
    if (messageId) {
      where.messageId = messageId;
    }

    return this.replyRepository.find({
      where,
      relations: ['message'],
      order: { createdAt: 'DESC' },
    });
  }

  /**
   * 답장 토큰 정보 조회
   */
  async getReplyTokenInfo(
    messageId: string,
    fanId: string,
  ): Promise<{
    total: number;
    used: number;
    remaining: number;
    charLimit: number;
    expiresAt: Date | null;
  } | null> {
    const replyToken = await this.replyTokenRepository.findOne({
      where: {
        messageId,
        subscription: { fanId },
      },
      relations: ['subscription'],
    });

    if (!replyToken) {
      return null;
    }

    return {
      total: replyToken.total,
      used: replyToken.used,
      remaining: replyToken.total - replyToken.used,
      charLimit: replyToken.charLimit,
      expiresAt: replyToken.expiresAt,
    };
  }
}
