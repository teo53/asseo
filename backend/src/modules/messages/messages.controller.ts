import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
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

import { MessagesService } from './messages.service';
import { RepliesService } from './replies.service';
import { CreateMessageDto } from './dto/create-message.dto';
import { CreateReplyDto } from './dto/create-reply.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { User, UserRole } from '../users/entities/user.entity';

@ApiTags('messages')
@Controller('messages')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class MessagesController {
  constructor(
    private readonly messagesService: MessagesService,
    private readonly repliesService: RepliesService,
  ) {}

  // ============ 캐스트 전용 API ============

  @Post('cast/send')
  @UseGuards(RolesGuard)
  @Roles(UserRole.CAST)
  @ApiOperation({ summary: '메시지 발송 (캐스트)' })
  @ApiResponse({ status: 201, description: '발송 성공' })
  async sendMessage(
    @CurrentUser() user: User,
    @Body() createMessageDto: CreateMessageDto,
  ) {
    // TODO: user.id로 캐스트 ID 조회 필요
    return this.messagesService.create(user.id, createMessageDto);
  }

  @Get('cast/replies')
  @UseGuards(RolesGuard)
  @Roles(UserRole.CAST)
  @ApiOperation({ summary: '받은 답장 목록 (캐스트)' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'unreadOnly', required: false, type: Boolean })
  async getReplies(
    @CurrentUser() user: User,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
    @Query('unreadOnly') unreadOnly?: boolean,
  ) {
    return this.repliesService.findRepliesForCast(
      user.id, // TODO: castId로 변환 필요
      page,
      limit,
      unreadOnly === true,
    );
  }

  @Post('cast/replies/read')
  @UseGuards(RolesGuard)
  @Roles(UserRole.CAST)
  @ApiOperation({ summary: '답장 읽음 처리 (캐스트)' })
  async markRepliesAsRead(
    @CurrentUser() user: User,
    @Body('replyIds') replyIds: string[],
  ) {
    await this.repliesService.markAsReadByCast(replyIds, user.id);
    return { success: true };
  }

  // ============ 팬 전용 API ============

  @Get('chatroom/:castId')
  @ApiOperation({ summary: '채팅방 메시지 목록 (팬)' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async getChatroomMessages(
    @CurrentUser() user: User,
    @Param('castId') castId: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
  ) {
    return this.messagesService.findByCastId(castId, user.id, page, limit);
  }

  @Get('chatroom/:castId/unread-count')
  @ApiOperation({ summary: '읽지 않은 메시지 수 (팬)' })
  async getUnreadCount(
    @CurrentUser() user: User,
    @Param('castId') castId: string,
  ) {
    const count = await this.messagesService.getUnreadCount(castId, user.id);
    return { unreadCount: count };
  }

  @Post('chatroom/:castId/messages/:messageId/read')
  @ApiOperation({ summary: '메시지 읽음 처리 (팬)' })
  async markMessageAsRead(
    @CurrentUser() user: User,
    @Param('messageId') messageId: string,
  ) {
    await this.messagesService.markAsRead(messageId, user.id);
    return { success: true };
  }

  @Post('chatroom/:castId/messages/:messageId/reply')
  @ApiOperation({ summary: '메시지에 답장 (팬)' })
  @ApiResponse({ status: 201, description: '답장 성공' })
  @ApiResponse({ status: 400, description: '토큰 부족 또는 글자수 초과' })
  async replyToMessage(
    @CurrentUser() user: User,
    @Param('messageId') messageId: string,
    @Body() createReplyDto: CreateReplyDto,
  ) {
    return this.repliesService.create(messageId, user.id, createReplyDto);
  }

  @Get('chatroom/:castId/messages/:messageId/reply-info')
  @ApiOperation({ summary: '답장 토큰 정보 (팬)' })
  async getReplyTokenInfo(
    @CurrentUser() user: User,
    @Param('messageId') messageId: string,
  ) {
    return this.repliesService.getReplyTokenInfo(messageId, user.id);
  }

  @Get('my-replies')
  @ApiOperation({ summary: '내 답장 목록 (팬)' })
  async getMyReplies(
    @CurrentUser() user: User,
    @Query('messageId') messageId?: string,
  ) {
    return this.repliesService.findRepliesByFan(user.id, messageId);
  }
}
