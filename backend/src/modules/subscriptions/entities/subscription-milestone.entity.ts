import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
} from 'typeorm';

@Entity('subscription_milestones')
export class SubscriptionMilestone {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  days: number;

  @Column({ name: 'char_limit_bonus' })
  charLimitBonus: number;

  @Column({ name: 'badge_name', nullable: true, length: 50 })
  badgeName: string;

  @Column({ name: 'badge_image', nullable: true, length: 500 })
  badgeImage: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
