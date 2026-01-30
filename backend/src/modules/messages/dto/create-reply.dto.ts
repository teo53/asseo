import { IsString, MaxLength, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateReplyDto {
  @ApiProperty({ description: '답장 내용', minLength: 1, maxLength: 500 })
  @IsString()
  @MinLength(1, { message: '답장 내용을 입력해주세요.' })
  @MaxLength(500, { message: '답장은 최대 500자까지 가능합니다.' })
  content: string;
}
