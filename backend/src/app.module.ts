import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';

// Feature modules
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { CastsModule } from './modules/casts/casts.module';
import { MessagesModule } from './modules/messages/messages.module';
import { SubscriptionsModule } from './modules/subscriptions/subscriptions.module';
import { ContentsModule } from './modules/contents/contents.module';
import { ReportsModule } from './modules/reports/reports.module';
import { NotificationsModule } from './modules/notifications/notifications.module';

// Shared modules
import { RedisModule } from './shared/redis/redis.module';
import { StorageModule } from './shared/storage/storage.module';
import { ModerationModule } from './shared/moderation/moderation.module';

@Module({
  imports: [
    // Configuration
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: ['.env.local', '.env'],
    }),

    // Database
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => ({
        type: 'postgres',
        host: configService.get<string>('DB_HOST', 'localhost'),
        port: configService.get<number>('DB_PORT', 5432),
        username: configService.get<string>('DB_USERNAME', 'postgres'),
        password: configService.get<string>('DB_PASSWORD', 'postgres'),
        database: configService.get<string>('DB_DATABASE', 'moe_backstage'),
        entities: [__dirname + '/**/*.entity{.ts,.js}'],
        synchronize: configService.get<string>('NODE_ENV') === 'development',
        logging: configService.get<string>('NODE_ENV') === 'development',
      }),
      inject: [ConfigService],
    }),

    // Shared modules
    RedisModule,
    StorageModule,
    ModerationModule,

    // Feature modules
    AuthModule,
    UsersModule,
    CastsModule,
    MessagesModule,
    SubscriptionsModule,
    ContentsModule,
    ReportsModule,
    NotificationsModule,
  ],
})
export class AppModule {}
