import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { UseGuards } from '@nestjs/common';

import { MessagesService } from './messages.service';

interface AuthenticatedSocket extends Socket {
  userId?: string;
  castId?: string;
}

@WebSocketGateway({
  cors: {
    origin: '*',
  },
  namespace: '/chat',
})
export class MessagesGateway
  implements OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer()
  server: Server;

  // 캐스트별 구독자 소켓 관리
  private castRooms: Map<string, Set<string>> = new Map();

  handleConnection(client: AuthenticatedSocket) {
    console.log(`Client connected: ${client.id}`);
    // TODO: JWT 토큰 검증 및 userId 설정
  }

  handleDisconnect(client: AuthenticatedSocket) {
    console.log(`Client disconnected: ${client.id}`);
    // 모든 룸에서 제거
    this.castRooms.forEach((sockets, castId) => {
      sockets.delete(client.id);
    });
  }

  /**
   * 채팅방(캐스트) 입장
   */
  @SubscribeMessage('join_room')
  handleJoinRoom(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: { castId: string },
  ) {
    const { castId } = data;

    // Socket.IO 룸 입장
    client.join(`cast:${castId}`);

    // 내부 관리용 맵 업데이트
    if (!this.castRooms.has(castId)) {
      this.castRooms.set(castId, new Set());
    }
    this.castRooms.get(castId)!.add(client.id);

    console.log(`Client ${client.id} joined room cast:${castId}`);

    return { success: true, room: castId };
  }

  /**
   * 채팅방(캐스트) 퇴장
   */
  @SubscribeMessage('leave_room')
  handleLeaveRoom(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: { castId: string },
  ) {
    const { castId } = data;

    client.leave(`cast:${castId}`);
    this.castRooms.get(castId)?.delete(client.id);

    console.log(`Client ${client.id} left room cast:${castId}`);

    return { success: true };
  }

  /**
   * 메시지 읽음 처리
   */
  @SubscribeMessage('mark_read')
  handleMarkRead(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: { messageIds: string[] },
  ) {
    // TODO: 실제 읽음 처리 로직
    return { success: true };
  }

  /**
   * 캐스트가 새 메시지를 보낼 때 구독자들에게 브로드캐스트
   */
  broadcastNewMessage(castId: string, message: any) {
    this.server.to(`cast:${castId}`).emit('new_message', message);
  }

  /**
   * 캐스트에게 새 답장 알림
   */
  notifyNewReply(castId: string, reply: any) {
    // 캐스트 전용 룸으로 전송
    this.server.to(`cast:${castId}:owner`).emit('new_reply', reply);
  }

  /**
   * 팬에게 구독 상태 변경 알림
   */
  notifySubscriptionUpdate(userId: string, subscription: any) {
    this.server.to(`user:${userId}`).emit('subscription_updated', subscription);
  }

  /**
   * 토큰 갱신 알림
   */
  notifyTokensRefreshed(userId: string, castId: string, tokens: { available: number }) {
    this.server
      .to(`user:${userId}`)
      .emit('tokens_refreshed', { castId, ...tokens });
  }
}
