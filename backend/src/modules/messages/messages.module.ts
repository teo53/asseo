import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { Message } from './entities/message.entity';
import { MessageRead } from './entities/message-read.entity';
import { Reply } from './entities/reply.entity';
import { ReplyToken } from './entities/reply-token.entity';

import { MessagesService } from './messages.service';
import { RepliesService } from './replies.service';
import { ReplyTokensService } from './reply-tokens.service';
import { MessagesController } from './messages.controller';
import { MessagesGateway } from './messages.gateway';

import { SubscriptionsModule } from '../subscriptions/subscriptions.module';
import { ModerationModule } from '../../shared/moderation/moderation.module';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Message, MessageRead, Reply, ReplyToken]),
    SubscriptionsModule,
    ModerationModule,
    NotificationsModule,
  ],
  controllers: [MessagesController],
  providers: [
    MessagesService,
    RepliesService,
    ReplyTokensService,
    MessagesGateway,
  ],
  exports: [MessagesService, RepliesService],
})
export class MessagesModule {}
