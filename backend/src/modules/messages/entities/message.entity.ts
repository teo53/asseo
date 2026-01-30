import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  OneToMany,
  JoinColumn,
} from 'typeorm';
import { Cast } from '../../casts/entities/cast.entity';

export enum MessageType {
  TEXT = 'TEXT',
  IMAGE = 'IMAGE',
  VOICE = 'VOICE',
  VIDEO = 'VIDEO',
}

@Entity('messages')
export class Message {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'cast_id' })
  castId: string;

  @ManyToOne(() => Cast)
  @JoinColumn({ name: 'cast_id' })
  cast: Cast;

  @Column({ type: 'text', nullable: true })
  content: string;

  @Column({
    type: 'enum',
    enum: MessageType,
    default: MessageType.TEXT,
  })
  type: MessageType;

  @Column({ name: 'media_url', nullable: true, length: 500 })
  mediaUrl: string;

  @Column({ name: 'media_thumbnail', nullable: true, length: 500 })
  mediaThumbnail: string;

  @Column({ name: 'tier_required', default: 'BASIC', length: 20 })
  tierRequired: string;

  @Column({ name: 'is_deleted', default: false })
  isDeleted: boolean;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
