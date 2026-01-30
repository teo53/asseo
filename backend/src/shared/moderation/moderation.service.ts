import { Injectable, OnModuleInit } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ConfigService } from '@nestjs/config';

import { BlockedPattern } from '../../modules/reports/entities/blocked-pattern.entity';

export interface ModerationResult {
  blocked: boolean;
  reason?: string;
  matchedPatterns: string[];
  severity: number;
}

@Injectable()
export class ModerationService implements OnModuleInit {
  private patterns: Map<string, RegExp[]> = new Map();
  private enabled: boolean;

  // 기본 내장 패턴 (DB 로드 실패 시 fallback)
  private readonly defaultPatterns = {
    // 한국 전화번호
    PHONE_KR: [
      /010[-\s]?\d{4}[-\s]?\d{4}/gi,
      /01[1-9][-\s]?\d{3,4}[-\s]?\d{4}/gi,
      /\+82[-\s]?\d{2}[-\s]?\d{4}[-\s]?\d{4}/gi,
    ],
    // 이메일
    EMAIL: [/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/gi],
    // SNS 계정
    SNS_HANDLE: [
      /@[a-zA-Z0-9_]{1,30}/gi,
      /인스타(그램)?[\s:]*[a-zA-Z0-9_]+/gi,
      /카카오(톡)?[\s]*아이디[\s:]*[a-zA-Z0-9_]+/gi,
      /카톡[\s]*아이디[\s:]*[a-zA-Z0-9_]+/gi,
      /라인[\s]*아이디[\s:]*[a-zA-Z0-9_]+/gi,
      /트위터[\s:]*[a-zA-Z0-9_]+/gi,
    ],
    // 개인정보 요청
    PERSONAL_INFO_REQUEST: [
      /연락처[\s]*(알려|줘|주|보내)/gi,
      /전화번호[\s]*(알려|줘|주|보내)/gi,
      /번호[\s]*(알려|줘|주|보내)/gi,
      /(어디|어느)[\s]*(사|살|거주)/gi,
      /주소[\s]*(알려|줘|주|보내)/gi,
      /실명[\s]*(뭐|알려|줘)/gi,
      /본명[\s]*(뭐|알려|줘)/gi,
    ],
    // 부적절한 표현 (예시, 실제 서비스에서는 더 포괄적으로)
    INAPPROPRIATE: [
      /사귀자/gi,
      /만나자/gi,
      /몸매/gi,
      /섹시/gi,
    ],
  };

  constructor(
    @InjectRepository(BlockedPattern)
    private readonly blockedPatternRepository: Repository<BlockedPattern>,
    private readonly configService: ConfigService,
  ) {
    this.enabled = this.configService.get<boolean>('MODERATION_ENABLED', true);
  }

  async onModuleInit() {
    await this.loadPatterns();
  }

  /**
   * DB에서 패턴 로드
   */
  async loadPatterns(): Promise<void> {
    try {
      const dbPatterns = await this.blockedPatternRepository.find({
        where: { isActive: true },
      });

      this.patterns.clear();

      // DB 패턴 로드
      for (const pattern of dbPatterns) {
        if (!this.patterns.has(pattern.patternType)) {
          this.patterns.set(pattern.patternType, []);
        }
        try {
          this.patterns.get(pattern.patternType)!.push(new RegExp(pattern.pattern, 'gi'));
        } catch (e) {
          console.warn(`Invalid regex pattern: ${pattern.pattern}`);
        }
      }

      // 기본 패턴 추가 (DB에 없는 타입만)
      for (const [type, regexes] of Object.entries(this.defaultPatterns)) {
        if (!this.patterns.has(type)) {
          this.patterns.set(type, regexes);
        }
      }

      console.log(`Loaded ${this.patterns.size} pattern types for moderation`);
    } catch (error) {
      console.error('Failed to load moderation patterns from DB, using defaults');
      // 기본 패턴 사용
      for (const [type, regexes] of Object.entries(this.defaultPatterns)) {
        this.patterns.set(type, regexes);
      }
    }
  }

  /**
   * 콘텐츠 검사
   */
  async checkContent(content: string): Promise<ModerationResult> {
    if (!this.enabled) {
      return { blocked: false, matchedPatterns: [], severity: 0 };
    }

    const matchedPatterns: string[] = [];
    let maxSeverity = 0;

    // 각 패턴 타입별 검사
    for (const [patternType, regexes] of this.patterns) {
      for (const regex of regexes) {
        // 매번 새로운 정규식으로 검사 (lastIndex 리셋)
        const testRegex = new RegExp(regex.source, regex.flags);
        if (testRegex.test(content)) {
          matchedPatterns.push(patternType);
          maxSeverity = Math.max(maxSeverity, this.getSeverity(patternType));
          break; // 같은 타입에서 여러 번 매칭할 필요 없음
        }
      }
    }

    const blocked = matchedPatterns.length > 0;

    return {
      blocked,
      reason: blocked ? this.getBlockReason(matchedPatterns) : undefined,
      matchedPatterns,
      severity: maxSeverity,
    };
  }

  /**
   * 패턴 타입별 심각도
   */
  private getSeverity(patternType: string): number {
    const severityMap: Record<string, number> = {
      PHONE_KR: 5,
      EMAIL: 4,
      SNS_HANDLE: 4,
      PERSONAL_INFO_REQUEST: 3,
      INAPPROPRIATE: 2,
    };
    return severityMap[patternType] || 1;
  }

  /**
   * 차단 사유 메시지 생성
   */
  private getBlockReason(matchedPatterns: string[]): string {
    const reasons: Record<string, string> = {
      PHONE_KR: '전화번호가 포함되어 있습니다.',
      EMAIL: '이메일 주소가 포함되어 있습니다.',
      SNS_HANDLE: 'SNS 계정 정보가 포함되어 있습니다.',
      PERSONAL_INFO_REQUEST: '개인정보 요청으로 보이는 내용이 포함되어 있습니다.',
      INAPPROPRIATE: '부적절한 표현이 포함되어 있습니다.',
    };

    const primaryPattern = matchedPatterns[0];
    return reasons[primaryPattern] || '서비스 정책에 위반되는 내용이 포함되어 있습니다.';
  }

  /**
   * 콘텐츠 정화 (필터링된 내용을 마스킹)
   */
  sanitizeContent(content: string): string {
    let sanitized = content;

    for (const [, regexes] of this.patterns) {
      for (const regex of regexes) {
        sanitized = sanitized.replace(regex, '[필터링됨]');
      }
    }

    return sanitized;
  }

  /**
   * 패턴 추가 (런타임)
   */
  async addPattern(pattern: string, patternType: string, description?: string): Promise<void> {
    const blockedPattern = this.blockedPatternRepository.create({
      pattern,
      patternType,
      description,
    });

    await this.blockedPatternRepository.save(blockedPattern);
    await this.loadPatterns(); // 리로드
  }

  /**
   * 패턴 비활성화
   */
  async disablePattern(id: string): Promise<void> {
    await this.blockedPatternRepository.update(id, { isActive: false });
    await this.loadPatterns(); // 리로드
  }
}
