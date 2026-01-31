// DreamTime Donation Edge Function
// Handles: commit donation, content moderation

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Allowed origins for CORS - configure based on environment
const ALLOWED_ORIGINS = (Deno.env.get('ALLOWED_ORIGINS') || 'http://localhost:3000,https://moe-backstage.app').split(',')

function getCorsHeaders(req: Request) {
  const origin = req.headers.get('Origin') || ''
  const allowedOrigin = ALLOWED_ORIGINS.includes(origin) ? origin : ALLOWED_ORIGINS[0]
  return {
    'Access-Control-Allow-Origin': allowedOrigin,
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  }
}

// Input validation constants
const MIN_DONATION_AMOUNT = 100
const MAX_DONATION_AMOUNT = 10000000
const MAX_MESSAGE_LENGTH = 1000
const VALID_CONTEXT_TYPES = ['dm', 'feed', 'content', 'live']
const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

// Content moderation patterns
const BLOCKED_PATTERNS = {
  phoneNumber: /(\d{2,4}[-.\s]?\d{3,4}[-.\s]?\d{4}|\+\d{1,3}[-.\s]?\d{2,4}[-.\s]?\d{3,4}[-.\s]?\d{4})/g,
  email: /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/g,
  socialMedia: /(카카오톡?|카톡|인스타|인스타그램|트위터|텔레그램|라인|위챗|페이스북|fb|ig|twitter|telegram|line|wechat|discord)\s*(아이디|id|:)?\s*[:\s]?\s*[@]?[a-zA-Z0-9._-]+/gi,
  externalLink: /(https?:\/\/[^\s]+)/g,
  // Explicit content detection (basic - should use ML in production)
  explicit: /(섹스|야동|성관계|자위|음란|포르노|sex|porn|nude)/gi,
  threats: /(죽이|살해|폭행|협박|신상|털어|패버|kill|threat|attack)/gi,
}

interface ModerationResult {
  passed: boolean
  reason?: string
  blockedPatterns: string[]
}

function moderateContent(message: string | null): ModerationResult {
  if (!message || message.trim() === '') {
    return { passed: true, blockedPatterns: [] }
  }

  const blockedPatterns: string[] = []

  // Check each pattern
  if (BLOCKED_PATTERNS.phoneNumber.test(message)) {
    blockedPatterns.push('phoneNumber')
  }
  if (BLOCKED_PATTERNS.email.test(message)) {
    blockedPatterns.push('email')
  }
  if (BLOCKED_PATTERNS.socialMedia.test(message)) {
    blockedPatterns.push('socialMedia')
  }
  if (BLOCKED_PATTERNS.externalLink.test(message)) {
    blockedPatterns.push('externalLink')
  }
  if (BLOCKED_PATTERNS.explicit.test(message)) {
    blockedPatterns.push('explicit')
  }
  if (BLOCKED_PATTERNS.threats.test(message)) {
    blockedPatterns.push('threats')
  }

  if (blockedPatterns.length > 0) {
    return {
      passed: false,
      reason: getBlockReason(blockedPatterns),
      blockedPatterns,
    }
  }

  return { passed: true, blockedPatterns: [] }
}

function getBlockReason(patterns: string[]): string {
  const reasons: Record<string, string> = {
    phoneNumber: '전화번호가 포함되어 있습니다.',
    email: '이메일 주소가 포함되어 있습니다.',
    socialMedia: '외부 메신저 계정 정보가 포함되어 있습니다.',
    externalLink: '외부 링크가 포함되어 있습니다.',
    explicit: '부적절한 성인 콘텐츠가 포함되어 있습니다.',
    threats: '위협적인 내용이 포함되어 있습니다.',
  }

  return patterns.map(p => reasons[p] || '정책 위반').join(' ')
}

serve(async (req) => {
  const corsHeaders = getCorsHeaders(req)

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    const url = new URL(req.url)
    const path = url.pathname.split('/').pop()

    if (req.method === 'POST') {
      // Parse JSON with error handling
      let body: any
      try {
        body = await req.json()
      } catch {
        return new Response(JSON.stringify({ error: 'Invalid JSON body' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      switch (path) {
        case 'commit': {
          // Commit a donation
          const authHeader = req.headers.get('Authorization')
          if (!authHeader?.startsWith('Bearer ')) {
            return new Response(JSON.stringify({ error: 'Unauthorized' }), {
              status: 401,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            })
          }

          const { data: { user }, error: authError } = await supabase.auth.getUser(
            authHeader.substring(7)
          )

          if (authError || !user) {
            return new Response(JSON.stringify({ error: 'Invalid token' }), {
              status: 401,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            })
          }

          const {
            toCreatorId,
            contextType,
            contextId,
            message,
            isAnonymous = false,
            dtAmount,
          } = body

          // Validate required fields
          if (!toCreatorId || !contextType || !contextId || !dtAmount) {
            return new Response(JSON.stringify({ error: 'Missing required fields' }), {
              status: 400,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            })
          }

          // Validate UUID formats
          if (!UUID_REGEX.test(toCreatorId) || !UUID_REGEX.test(contextId)) {
            return new Response(JSON.stringify({ error: 'Invalid ID format' }), {
              status: 400,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            })
          }

          // Validate context type
          if (!VALID_CONTEXT_TYPES.includes(contextType)) {
            return new Response(JSON.stringify({ error: 'Invalid context type' }), {
              status: 400,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            })
          }

          // Validate amount
          if (typeof dtAmount !== 'number' || dtAmount < MIN_DONATION_AMOUNT || dtAmount > MAX_DONATION_AMOUNT) {
            return new Response(JSON.stringify({
              error: `Amount must be between ${MIN_DONATION_AMOUNT} and ${MAX_DONATION_AMOUNT.toLocaleString()} DT`
            }), {
              status: 400,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            })
          }

          // Validate message length
          if (message && message.length > MAX_MESSAGE_LENGTH) {
            return new Response(JSON.stringify({
              error: `Message too long (max ${MAX_MESSAGE_LENGTH} characters)`
            }), {
              status: 400,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            })
          }

          // Prevent self-donation
          if (user.id === toCreatorId) {
            return new Response(JSON.stringify({ error: 'Cannot donate to yourself' }), {
              status: 400,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            })
          }

          // Validate creator exists and has CAST role
          const { data: creator } = await supabase
            .from('profiles')
            .select('id, role')
            .eq('id', toCreatorId)
            .single()

          if (!creator) {
            return new Response(JSON.stringify({ error: 'Creator not found' }), {
              status: 404,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            })
          }

          // Verify the recipient is a creator
          if (creator.role !== 'CAST') {
            return new Response(JSON.stringify({ error: 'Recipient is not a creator' }), {
              status: 400,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            })
          }

          // Content moderation
          const moderation = moderateContent(message)
          if (!moderation.passed) {
            return new Response(JSON.stringify({
              error: 'Message blocked',
              reason: moderation.reason,
              blockedPatterns: moderation.blockedPatterns,
            }), {
              status: 400,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            })
          }

          // Process donation using database function
          const { data: result, error: donationError } = await supabase.rpc('dt_spend_donation', {
            p_from_user_id: user.id,
            p_to_creator_id: toCreatorId,
            p_context_type: contextType,
            p_context_id: contextId,
            p_message: message || null,
            p_is_anonymous: isAnonymous,
            p_dt_amount: dtAmount,
          })

          if (donationError) {
            console.error('Donation error:', donationError)
            return new Response(JSON.stringify({ error: 'Failed to process donation' }), {
              status: 500,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            })
          }

          const donationResult = result[0]
          if (!donationResult.success) {
            return new Response(JSON.stringify({ error: donationResult.error }), {
              status: 400,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            })
          }

          return new Response(JSON.stringify({
            success: true,
            donationId: donationResult.donation_id,
            spentPromo: donationResult.spent_promo,
            spentPurchased: donationResult.spent_purchased,
          }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          })
        }

        case 'moderate': {
          // Test content moderation (public endpoint)
          const { message } = body
          const result = moderateContent(message)

          return new Response(JSON.stringify(result), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          })
        }

        default:
          return new Response(JSON.stringify({ error: 'Not found' }), {
            status: 404,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          })
      }
    }

    if (req.method === 'GET') {
      switch (path) {
        case 'history': {
          // Get donation history
          const authHeader = req.headers.get('Authorization')
          if (!authHeader) {
            return new Response(JSON.stringify({ error: 'Unauthorized' }), {
              status: 401,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            })
          }

          const { data: { user } } = await supabase.auth.getUser(
            authHeader.replace('Bearer ', '')
          )

          if (!user) {
            return new Response(JSON.stringify({ error: 'Invalid token' }), {
              status: 401,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            })
          }

          const type = url.searchParams.get('type') || 'sent' // 'sent' or 'received'
          const limit = Math.min(parseInt(url.searchParams.get('limit') || '20') || 20, 100) // Max 100 items
          const offset = Math.min(parseInt(url.searchParams.get('offset') || '0') || 0, 10000) // Max offset 10000

          let query = supabase
            .from('dt_donations')
            .select(`
              *,
              from_user:profiles!from_user_id(id, nickname, profile_image),
              to_creator:profiles!to_creator_id(id, nickname, profile_image)
            `)
            .order('created_at', { ascending: false })
            .range(offset, offset + limit - 1)

          if (type === 'sent') {
            query = query.eq('from_user_id', user.id)
          } else {
            query = query.eq('to_creator_id', user.id)
          }

          const { data: donations, error } = await query

          if (error) {
            return new Response(JSON.stringify({ error: 'Failed to fetch donations' }), {
              status: 500,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            })
          }

          return new Response(JSON.stringify({ donations }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          })
        }

        default:
          return new Response(JSON.stringify({ error: 'Not found' }), {
            status: 404,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          })
      }
    }

    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (error) {
    console.error('Edge function error:', error)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
