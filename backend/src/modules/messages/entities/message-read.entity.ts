import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  Unique,
  CreateDateColumn,
} from 'typeorm';
import { Message } from './message.entity';
import { User } from '../../users/entities/user.entity';

@Entity('message_reads')
@Unique(['messageId', 'fanId'])
export class MessageRead {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'message_id' })
  messageId: string;

  @ManyToOne(() => Message)
  @JoinColumn({ name: 'message_id' })
  message: Message;

  @Column({ name: 'fan_id' })
  fanId: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'fan_id' })
  fan: User;

  @CreateDateColumn({ name: 'read_at', type: 'timestamptz' })
  readAt: Date;
}
