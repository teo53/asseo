import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { BlockedPattern } from '../../modules/reports/entities/blocked-pattern.entity';
import { ModerationService } from './moderation.service';

@Module({
  imports: [TypeOrmModule.forFeature([BlockedPattern])],
  providers: [ModerationService],
  exports: [ModerationService],
})
export class ModerationModule {}
