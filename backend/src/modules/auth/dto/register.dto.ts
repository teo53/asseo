import {
  IsEmail,
  IsString,
  MinLength,
  MaxLength,
  IsOptional,
  IsEnum,
  Matches,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { UserRole } from '../../users/entities/user.entity';

export class RegisterDto {
  @ApiProperty({ example: 'user@example.com', description: '이메일' })
  @IsEmail({}, { message: '올바른 이메일 형식이 아닙니다.' })
  email: string;

  @ApiProperty({ example: 'password123!', description: '비밀번호 (8-30자)' })
  @IsString()
  @MinLength(8, { message: '비밀번호는 최소 8자 이상이어야 합니다.' })
  @MaxLength(30, { message: '비밀번호는 최대 30자까지 가능합니다.' })
  @Matches(/^(?=.*[a-zA-Z])(?=.*\d)/, {
    message: '비밀번호는 영문과 숫자를 포함해야 합니다.',
  })
  password: string;

  @ApiProperty({ example: '눈꽃', description: '닉네임 (2-20자)' })
  @IsString()
  @MinLength(2, { message: '닉네임은 최소 2자 이상이어야 합니다.' })
  @MaxLength(20, { message: '닉네임은 최대 20자까지 가능합니다.' })
  nickname: string;

  @ApiPropertyOptional({ enum: UserRole, default: UserRole.FAN })
  @IsOptional()
  @IsEnum(UserRole)
  role?: UserRole;
}
