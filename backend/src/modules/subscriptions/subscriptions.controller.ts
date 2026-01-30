import {
  Controller,
  Get,
  Post,
  Delete,
  Patch,
  Param,
  Body,
  UseGuards,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from '@nestjs/swagger';

import { SubscriptionsService } from './subscriptions.service';
import { CreateSubscriptionDto } from './dto/create-subscription.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { User } from '../users/entities/user.entity';

@ApiTags('subscriptions')
@Controller('subscriptions')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class SubscriptionsController {
  constructor(private readonly subscriptionsService: SubscriptionsService) {}

  @Get('tiers')
  @ApiOperation({ summary: '구독 티어 목록' })
  async getTiers() {
    return this.subscriptionsService.getTiers();
  }

  @Get('milestones')
  @ApiOperation({ summary: '마일스톤 목록' })
  async getMilestones() {
    return this.subscriptionsService.getMilestones();
  }

  @Get()
  @ApiOperation({ summary: '내 구독 목록' })
  async getMySubscriptions(@CurrentUser() user: User) {
    return this.subscriptionsService.findByFanId(user.id);
  }

  @Get(':id')
  @ApiOperation({ summary: '구독 상세 정보' })
  async getSubscriptionDetails(
    @CurrentUser() user: User,
    @Param('id') id: string,
  ) {
    return this.subscriptionsService.getSubscriptionDetails(id, user.id);
  }

  @Post()
  @ApiOperation({ summary: '구독 생성' })
  @ApiResponse({ status: 201, description: '구독 성공' })
  @ApiResponse({ status: 409, description: '이미 구독 중' })
  async create(
    @CurrentUser() user: User,
    @Body() createSubscriptionDto: CreateSubscriptionDto,
  ) {
    return this.subscriptionsService.create(user.id, createSubscriptionDto);
  }

  @Delete(':id')
  @ApiOperation({ summary: '구독 취소' })
  async cancel(@CurrentUser() user: User, @Param('id') id: string) {
    return this.subscriptionsService.cancel(id, user.id);
  }

  @Patch(':id/tier')
  @ApiOperation({ summary: '구독 티어 변경' })
  async changeTier(
    @CurrentUser() user: User,
    @Param('id') id: string,
    @Body('tierCode') tierCode: string,
  ) {
    return this.subscriptionsService.changeTier(id, user.id, tierCode);
  }
}
