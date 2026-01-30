import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
  Unique,
} from 'typeorm';
import { Subscription } from '../../subscriptions/entities/subscription.entity';
import { Message } from './message.entity';

@Entity('reply_tokens')
@Unique(['subscriptionId', 'messageId'])
export class ReplyToken {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'subscription_id' })
  subscriptionId: string;

  @ManyToOne(() => Subscription)
  @JoinColumn({ name: 'subscription_id' })
  subscription: Subscription;

  @Column({ name: 'message_id' })
  messageId: string;

  @ManyToOne(() => Message)
  @JoinColumn({ name: 'message_id' })
  message: Message;

  @Column({ default: 3 })
  total: number;

  @Column({ default: 0 })
  used: number;

  @Column({ name: 'char_limit', default: 50 })
  charLimit: number;

  @Column({ name: 'expires_at', type: 'timestamptz', nullable: true })
  expiresAt: Date;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
