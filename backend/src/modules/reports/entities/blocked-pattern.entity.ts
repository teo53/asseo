import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
} from 'typeorm';

@Entity('blocked_patterns')
export class BlockedPattern {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ length: 500 })
  pattern: string;

  @Column({ name: 'pattern_type', length: 50 })
  patternType: string;

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
