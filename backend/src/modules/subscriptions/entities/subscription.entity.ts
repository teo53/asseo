import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  Unique,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Cast } from '../../casts/entities/cast.entity';
import { SubscriptionTier } from './subscription-tier.entity';

@Entity('subscriptions')
@Unique(['fanId', 'castId'])
export class Subscription {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'fan_id' })
  fanId: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'fan_id' })
  fan: User;

  @Column({ name: 'cast_id' })
  castId: string;

  @ManyToOne(() => Cast)
  @JoinColumn({ name: 'cast_id' })
  cast: Cast;

  @Column({ name: 'tier_id' })
  tierId: string;

  @ManyToOne(() => SubscriptionTier)
  @JoinColumn({ name: 'tier_id' })
  tier: SubscriptionTier;

  @Column({ name: 'started_at', type: 'timestamptz', default: () => 'NOW()' })
  startedAt: Date;

  @Column({ name: 'expires_at', type: 'timestamptz', nullable: true })
  expiresAt: Date;

  @Column({ name: 'auto_renew', default: true })
  autoRenew: boolean;

  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  @Column({ name: 'cancelled_at', type: 'timestamptz', nullable: true })
  cancelledAt: Date;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
