import {
  Controller,
  Get,
  Param,
  Query,
  ParseIntPipe,
  DefaultValuePipe,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiQuery, ApiResponse } from '@nestjs/swagger';

import { CastsService } from './casts.service';

@ApiTags('casts')
@Controller('casts')
export class CastsController {
  constructor(private readonly castsService: CastsService) {}

  @Get()
  @ApiOperation({ summary: '캐스트 목록' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'search', required: false, type: String })
  @ApiQuery({ name: 'teamId', required: false, type: String })
  async findAll(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
    @Query('search') search?: string,
    @Query('teamId') teamId?: string,
  ) {
    return this.castsService.findAll({ page, limit, search, teamId });
  }

  @Get('popular')
  @ApiOperation({ summary: '인기 캐스트' })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async findPopular(
    @Query('limit', new DefaultValuePipe(10), ParseIntPipe) limit: number,
  ) {
    return this.castsService.findPopular(limit);
  }

  @Get('teams')
  @ApiOperation({ summary: '팀 목록' })
  async findAllTeams() {
    return this.castsService.findAllTeams();
  }

  @Get('teams/:id')
  @ApiOperation({ summary: '팀 상세' })
  @ApiResponse({ status: 404, description: '팀 없음' })
  async findTeam(@Param('id') id: string) {
    return this.castsService.findTeamById(id);
  }

  @Get(':id')
  @ApiOperation({ summary: '캐스트 상세' })
  @ApiResponse({ status: 404, description: '캐스트 없음' })
  async findOne(@Param('id') id: string) {
    return this.castsService.findById(id);
  }
}
