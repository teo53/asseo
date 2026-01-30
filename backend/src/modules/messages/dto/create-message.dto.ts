import {
  IsString,
  IsOptional,
  IsEnum,
  MaxLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { MessageType } from '../entities/message.entity';

export class CreateMessageDto {
  @ApiPropertyOptional({ description: '메시지 내용' })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  content?: string;

  @ApiPropertyOptional({ enum: MessageType, default: MessageType.TEXT })
  @IsOptional()
  @IsEnum(MessageType)
  type?: MessageType;

  @ApiPropertyOptional({ description: '미디어 URL' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  mediaUrl?: string;

  @ApiPropertyOptional({ description: '미디어 썸네일 URL' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  mediaThumbnail?: string;

  @ApiPropertyOptional({ description: '필요 구독 티어', default: 'BASIC' })
  @IsOptional()
  @IsString()
  tierRequired?: string;
}
