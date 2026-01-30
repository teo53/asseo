// DreamTime Refund Edge Function
// Handles: refund request, eligibility check, admin processing

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
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
      const body = await req.json()

      switch (path) {
        case 'check-eligibility': {
          // Check if a topup order is eligible for refund
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

          const { topupOrderId } = body

          // Verify user owns the order
          const { data: order } = await supabase
            .from('dt_topup_orders')
            .select('user_id')
            .eq('id', topupOrderId)
            .single()

          if (!order || order.user_id !== user.id) {
            return new Response(JSON.stringify({ error: 'Order not found' }), {
              status: 404,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            })
          }

          // Check eligibility using database function
          const { data: result } = await supabase.rpc('dt_check_refund_eligibility', {
            p_topup_order_id: topupOrderId,
          })

          const eligibility = result[0]

          return new Response(JSON.stringify({
            eligible: eligibility.eligible,
            reason: eligibility.reason,
          }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          })
        }

        case 'request': {
          // Request a refund
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

          const { topupOrderId, reason } = body

          // Verify user owns the order
          const { data: order } = await supabase
            .from('dt_topup_orders')
            .select('*')
            .eq('id', topupOrderId)
            .eq('user_id', user.id)
            .single()

          if (!order) {
            return new Response(JSON.stringify({ error: 'Order not found' }), {
              status: 404,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            })
          }

          // Check eligibility
          const { data: eligResult } = await supabase.rpc('dt_check_refund_eligibility', {
            p_topup_order_id: topupOrderId,
          })

          const eligibility = eligResult[0]
          if (!eligibility.eligible) {
            return new Response(JSON.stringify({
              error: 'Not eligible for refund',
              reason: eligibility.reason,
            }), {
              status: 400,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            })
          }

          // Create refund request
          const { data: refundRequest, error: insertError } = await supabase
            .from('dt_refund_requests')
            .insert({
              user_id: user.id,
              topup_order_id: topupOrderId,
              reason,
            })
            .select()
            .single()

          if (insertError) {
            if (insertError.code === '23505') { // Unique violation
              return new Response(JSON.stringify({ error: 'Refund already requested for this order' }), {
                status: 400,
                headers: { ...corsHeaders, 'Content-Type': 'application/json' },
              })
            }
            throw insertError
          }

          return new Response(JSON.stringify({
            success: true,
            refundRequest,
          }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          })
        }

        case 'process': {
          // Admin: Process a refund request
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

          // Check admin role
          const { data: profile } = await supabase
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .single()

          if (!profile || profile.role !== 'admin') {
            return new Response(JSON.stringify({ error: 'Admin access required' }), {
              status: 403,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            })
          }

          const { refundRequestId } = body

          // Process refund using database function
          const { data: result, error: processError } = await supabase.rpc('dt_process_refund', {
            p_refund_request_id: refundRequestId,
            p_admin_id: user.id,
          })

          if (processError) {
            console.error('Refund process error:', processError)
            return new Response(JSON.stringify({ error: 'Failed to process refund' }), {
              status: 500,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            })
          }

          const processResult = result[0]
          if (!processResult.success) {
            return new Response(JSON.stringify({ error: processResult.error }), {
              status: 400,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            })
          }

          // TODO: Call actual payment provider refund API here
          // For now, mock refund is considered complete

          return new Response(JSON.stringify({ success: true }), {
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
        case 'requests': {
          // Get refund requests (user's own or admin's list)
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

          // Check if admin
          const { data: profile } = await supabase
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .single()

          const isAdmin = profile?.role === 'admin'
          const statusFilter = url.searchParams.get('status')

          let query = supabase
            .from('dt_refund_requests')
            .select(`
              *,
              topup_order:dt_topup_orders(*)
            `)
            .order('created_at', { ascending: false })

          if (!isAdmin) {
            query = query.eq('user_id', user.id)
          }

          if (statusFilter) {
            query = query.eq('status', statusFilter)
          }

          const { data: requests, error } = await query

          if (error) {
            return new Response(JSON.stringify({ error: 'Failed to fetch requests' }), {
              status: 500,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            })
          }

          return new Response(JSON.stringify({ requests }), {
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
