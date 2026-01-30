import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
} from 'typeorm';

@Entity('subscription_tiers')
export class SubscriptionTier {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ length: 50 })
  name: string;

  @Column({ unique: true, length: 20 })
  code: string;

  @Column({ name: 'price_monthly' })
  priceMonthly: number;

  @Column({ name: 'reply_tokens_per_message', default: 3 })
  replyTokensPerMessage: number;

  @Column({ name: 'base_char_limit', default: 50 })
  baseCharLimit: number;

  @Column({ type: 'jsonb', default: {} })
  features: Record<string, any>;

  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
