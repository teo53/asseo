import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Like } from 'typeorm';

import { Cast } from './entities/cast.entity';
import { Team } from './entities/team.entity';

@Injectable()
export class CastsService {
  constructor(
    @InjectRepository(Cast)
    private readonly castRepository: Repository<Cast>,
    @InjectRepository(Team)
    private readonly teamRepository: Repository<Team>,
  ) {}

  /**
   * 캐스트 목록 조회
   */
  async findAll(options?: {
    page?: number;
    limit?: number;
    search?: string;
    teamId?: string;
  }): Promise<{ casts: Cast[]; total: number; hasMore: boolean }> {
    const { page = 1, limit = 20, search, teamId } = options || {};

    const queryBuilder = this.castRepository
      .createQueryBuilder('cast')
      .leftJoinAndSelect('cast.team', 'team')
      .where('cast.is_active = true');

    if (search) {
      queryBuilder.andWhere('cast.stage_name ILIKE :search', {
        search: `%${search}%`,
      });
    }

    if (teamId) {
      queryBuilder.andWhere('cast.team_id = :teamId', { teamId });
    }

    const total = await queryBuilder.getCount();

    const casts = await queryBuilder
      .orderBy('cast.subscriber_count', 'DESC')
      .skip((page - 1) * limit)
      .take(limit)
      .getMany();

    return {
      casts,
      total,
      hasMore: page * limit < total,
    };
  }

  /**
   * 캐스트 상세 조회
   */
  async findById(id: string): Promise<Cast> {
    const cast = await this.castRepository.findOne({
      where: { id, isActive: true },
      relations: ['team', 'user'],
    });

    if (!cast) {
      throw new NotFoundException('캐스트를 찾을 수 없습니다.');
    }

    return cast;
  }

  /**
   * 사용자 ID로 캐스트 조회
   */
  async findByUserId(userId: string): Promise<Cast | null> {
    return this.castRepository.findOne({
      where: { userId, isActive: true },
      relations: ['team'],
    });
  }

  /**
   * 팀 목록 조회
   */
  async findAllTeams(): Promise<Team[]> {
    return this.teamRepository.find({
      where: { isActive: true },
      relations: ['casts'],
      order: { name: 'ASC' },
    });
  }

  /**
   * 팀 상세 조회
   */
  async findTeamById(id: string): Promise<Team> {
    const team = await this.teamRepository.findOne({
      where: { id, isActive: true },
      relations: ['casts'],
    });

    if (!team) {
      throw new NotFoundException('팀을 찾을 수 없습니다.');
    }

    return team;
  }

  /**
   * 인기 캐스트 조회
   */
  async findPopular(limit = 10): Promise<Cast[]> {
    return this.castRepository.find({
      where: { isActive: true },
      order: { subscriberCount: 'DESC' },
      take: limit,
      relations: ['team'],
    });
  }
}
