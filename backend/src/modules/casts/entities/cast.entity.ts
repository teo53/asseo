import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  OneToMany,
  JoinColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Team } from './team.entity';

@Entity('casts')
export class Cast {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id' })
  userId: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ name: 'team_id', nullable: true })
  teamId: string;

  @ManyToOne(() => Team, { nullable: true })
  @JoinColumn({ name: 'team_id' })
  team: Team;

  @Column({ name: 'stage_name', length: 50 })
  stageName: string;

  @Column({ type: 'text', nullable: true })
  bio: string;

  @Column({ name: 'profile_image', nullable: true, length: 500 })
  profileImage: string;

  @Column({ name: 'cover_image', nullable: true, length: 500 })
  coverImage: string;

  @Column({ name: 'greeting_message', type: 'text', nullable: true })
  greetingMessage: string;

  @Column({ name: 'subscriber_count', default: 0 })
  subscriberCount: number;

  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  @Column({ name: 'is_verified', default: false })
  isVerified: boolean;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
