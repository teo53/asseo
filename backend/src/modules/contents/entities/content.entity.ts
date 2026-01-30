import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Cast } from '../../casts/entities/cast.entity';

export enum ContentType {
  PHOTO = 'PHOTO',
  VIDEO = 'VIDEO',
  AUDIO = 'AUDIO',
  POST = 'POST',
}

@Entity('contents')
export class Content {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'cast_id' })
  castId: string;

  @ManyToOne(() => Cast)
  @JoinColumn({ name: 'cast_id' })
  cast: Cast;

  @Column({
    type: 'enum',
    enum: ContentType,
  })
  type: ContentType;

  @Column({ nullable: true, length: 200 })
  title: string;

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({ name: 'media_url', length: 500 })
  mediaUrl: string;

  @Column({ name: 'thumbnail_url', nullable: true, length: 500 })
  thumbnailUrl: string;

  @Column({ name: 'tier_required', default: 'BASIC', length: 20 })
  tierRequired: string;

  @Column({ name: 'view_count', default: 0 })
  viewCount: number;

  @Column({ name: 'is_deleted', default: false })
  isDeleted: boolean;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
