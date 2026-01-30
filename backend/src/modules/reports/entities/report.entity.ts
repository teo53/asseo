import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

export enum ReportStatus {
  PENDING = 'PENDING',
  REVIEWING = 'REVIEWING',
  RESOLVED = 'RESOLVED',
  DISMISSED = 'DISMISSED',
}

export enum ReportTargetType {
  MESSAGE = 'MESSAGE',
  REPLY = 'REPLY',
  USER = 'USER',
  CONTENT = 'CONTENT',
}

@Entity('reports')
export class Report {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'reporter_id' })
  reporterId: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'reporter_id' })
  reporter: User;

  @Column({
    name: 'target_type',
    type: 'enum',
    enum: ReportTargetType,
  })
  targetType: ReportTargetType;

  @Column({ name: 'target_id' })
  targetId: string;

  @Column({ length: 50 })
  reason: string;

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({ name: 'evidence_urls', type: 'text', array: true, nullable: true })
  evidenceUrls: string[];

  @Column({
    type: 'enum',
    enum: ReportStatus,
    default: ReportStatus.PENDING,
  })
  status: ReportStatus;

  @Column({ default: 1 })
  severity: number;

  @Column({ name: 'resolved_by', nullable: true })
  resolvedById: string;

  @ManyToOne(() => User, { nullable: true })
  @JoinColumn({ name: 'resolved_by' })
  resolvedBy: User;

  @Column({ name: 'resolution_note', type: 'text', nullable: true })
  resolutionNote: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'resolved_at', type: 'timestamptz', nullable: true })
  resolvedAt: Date;
}
