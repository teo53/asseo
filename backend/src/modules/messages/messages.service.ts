import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { Message, MessageType } from './entities/message.entity';
import { MessageRead } from './entities/message-read.entity';
import { CreateMessageDto } from './dto/create-message.dto';
import { SubscriptionsService } from '../subscriptions/subscriptions.service';
import { ReplyTokensService } from './reply-tokens.service';
import { NotificationsService } from '../notifications/notifications.service';
import { User, UserRole } from '../users/entities/user.entity';

@Injectable()
export class MessagesService {
  constructor(
    @InjectRepository(Message)
    private readonly messageRepository: Repository<Message>,
    @InjectRepository(MessageRead)
    private readonly messageReadRepository: Repository<MessageRead>,
    private readonly subscriptionsService: SubscriptionsService,
    private readonly replyTokensService: ReplyTokensService,
    private readonly notificationsService: NotificationsService,
  ) {}

  /**
   * 캐스트가 메시지를 발송합니다 (모든 구독자에게 브로드캐스트)
   */
  async create(castId: string, createMessageDto: CreateMessageDto): Promise<Message> {
    const message = this.messageRepository.create({
      castId,
      ...createMessageDto,
    });

    const savedMessage = await this.messageRepository.save(message);

    // 모든 활성 구독자에게 답장 토큰 생성
    await this.replyTokensService.createTokensForMessage(savedMessage);

    // 구독자들에게 알림 발송 (비동기)
    this.notificationsService.notifyNewMessage(savedMessage).catch(console.error);

    return savedMessage;
  }

  /**
   * 특정 캐스트의 메시지 목록 조회 (팬용)
   */
  async findByCastId(
    castId: string,
    userId: string,
    page = 1,
    limit = 20,
  ): Promise<{ messages: Message[]; total: number; hasMore: boolean }> {
    // 구독 확인
    const subscription = await this.subscriptionsService.findActiveSubscription(
      userId,
      castId,
    );

    if (!subscription) {
      throw new ForbiddenException('구독이 필요합니다.');
    }

    const [messages, total] = await this.messageRepository.findAndCount({
      where: { castId, isDeleted: false },
      order: { createdAt: 'DESC' },
      skip: (page - 1) * limit,
      take: limit,
      relations: ['cast'],
    });

    // 티어에 따른 필터링
    const tierPriority = { BASIC: 1, PREMIUM: 2, ULTIMATE: 3 };
    const userTierLevel = tierPriority[subscription.tier.code] || 1;

    const filteredMessages = messages.filter((msg) => {
      const requiredLevel = tierPriority[msg.tierRequired] || 1;
      return userTierLevel >= requiredLevel;
    });

    return {
      messages: filteredMessages,
      total,
      hasMore: page * limit < total,
    };
  }

  /**
   * 메시지 상세 조회
   */
  async findOne(id: string, userId: string): Promise<Message> {
    const message = await this.messageRepository.findOne({
      where: { id, isDeleted: false },
      relations: ['cast'],
    });

    if (!message) {
      throw new NotFoundException('메시지를 찾을 수 없습니다.');
    }

    // 구독 확인
    const subscription = await this.subscriptionsService.findActiveSubscription(
      userId,
      message.castId,
    );

    if (!subscription) {
      throw new ForbiddenException('구독이 필요합니다.');
    }

    return message;
  }

  /**
   * 메시지 읽음 처리
   */
  async markAsRead(messageId: string, fanId: string): Promise<void> {
    const existing = await this.messageReadRepository.findOne({
      where: { messageId, fanId },
    });

    if (!existing) {
      const messageRead = this.messageReadRepository.create({
        messageId,
        fanId,
      });
      await this.messageReadRepository.save(messageRead);
    }
  }

  /**
   * 읽지 않은 메시지 수 조회
   */
  async getUnreadCount(castId: string, fanId: string): Promise<number> {
    const result = await this.messageRepository
      .createQueryBuilder('message')
      .leftJoin(
        'message_reads',
        'mr',
        'mr.message_id = message.id AND mr.fan_id = :fanId',
        { fanId },
      )
      .where('message.cast_id = :castId', { castId })
      .andWhere('message.is_deleted = false')
      .andWhere('mr.id IS NULL')
      .getCount();

    return result;
  }

  /**
   * 캐스트의 메시지 통계
   */
  async getCastMessageStats(castId: string): Promise<{
    totalMessages: number;
    totalReads: number;
    lastMessageAt: Date | null;
  }> {
    const totalMessages = await this.messageRepository.count({
      where: { castId, isDeleted: false },
    });

    const totalReads = await this.messageReadRepository
      .createQueryBuilder('mr')
      .innerJoin('messages', 'm', 'm.id = mr.message_id')
      .where('m.cast_id = :castId', { castId })
      .getCount();

    const lastMessage = await this.messageRepository.findOne({
      where: { castId, isDeleted: false },
      order: { createdAt: 'DESC' },
    });

    return {
      totalMessages,
      totalReads,
      lastMessageAt: lastMessage?.createdAt || null,
    };
  }
}
