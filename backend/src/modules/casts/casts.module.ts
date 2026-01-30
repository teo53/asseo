import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { Cast } from './entities/cast.entity';
import { Team } from './entities/team.entity';
import { CastsService } from './casts.service';
import { CastsController } from './casts.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Cast, Team])],
  controllers: [CastsController],
  providers: [CastsService],
  exports: [CastsService],
})
export class CastsModule {}
