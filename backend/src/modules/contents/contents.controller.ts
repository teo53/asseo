import {
  Controller,
  Get,
  Post,
  Delete,
  Param,
  Query,
  Body,
  UseGuards,
  ParseIntPipe,
  DefaultValuePipe,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiQuery,
} from '@nestjs/swagger';

import { ContentsService } from './contents.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { User, UserRole } from '../users/entities/user.entity';
import { ContentType } from './entities/content.entity';

@ApiTags('contents')
@Controller('contents')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class ContentsController {
  constructor(private readonly contentsService: ContentsService) {}

  @Get('cast/:castId')
  @ApiOperation({ summary: '캐스트 콘텐츠 목록' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'type', required: false, enum: ContentType })
  async findByCast(
    @CurrentUser() user: User,
    @Param('castId') castId: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
    @Query('type') type?: ContentType,
  ) {
    return this.contentsService.findByCastId(castId, user.id, {
      page,
      limit,
      type,
    });
  }

  @Get(':id')
  @ApiOperation({ summary: '콘텐츠 상세' })
  @ApiResponse({ status: 403, description: '구독 필요' })
  @ApiResponse({ status: 404, description: '콘텐츠 없음' })
  async findOne(@CurrentUser() user: User, @Param('id') id: string) {
    return this.contentsService.findById(id, user.id);
  }

  @Post('cast/upload')
  @UseGuards(RolesGuard)
  @Roles(UserRole.CAST)
  @ApiOperation({ summary: '콘텐츠 업로드 (캐스트)' })
  async create(
    @CurrentUser() user: User,
    @Body() createContentDto: any, // TODO: CreateContentDto
  ) {
    // TODO: user.id로 castId 조회 필요
    return this.contentsService.create(user.id, createContentDto);
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.CAST)
  @ApiOperation({ summary: '콘텐츠 삭제 (캐스트)' })
  async delete(@CurrentUser() user: User, @Param('id') id: string) {
    await this.contentsService.delete(id, user.id);
    return { success: true };
  }
}
