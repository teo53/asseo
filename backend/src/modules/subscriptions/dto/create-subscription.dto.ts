import { IsString, IsUUID } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateSubscriptionDto {
  @ApiProperty({ description: '캐스트 ID' })
  @IsUUID()
  castId: string;

  @ApiProperty({ description: '티어 코드', example: 'BASIC' })
  @IsString()
  tierCode: string;
}
