import {
  IsString,
  IsOptional,
  MaxLength,
  MinLength,
  IsBoolean,
} from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class UpdateUserDto {
  @ApiPropertyOptional({ example: '눈꽃', description: '닉네임' })
  @IsOptional()
  @IsString()
  @MinLength(2)
  @MaxLength(20)
  nickname?: string;

  @ApiPropertyOptional({ description: '프로필 이미지 URL' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  profileImage?: string;

  @ApiPropertyOptional({ example: 'ko', description: '선호 언어' })
  @IsOptional()
  @IsString()
  @MaxLength(10)
  language?: string;

  @ApiPropertyOptional({ description: '푸시 알림 활성화' })
  @IsOptional()
  @IsBoolean()
  pushEnabled?: boolean;
}
