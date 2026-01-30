// DreamTime Top-up Edge Function
// Handles: create order, start payment, webhook processing

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Payment provider interface
interface PaymentProvider {
  name: string
  createPayment(order: TopupOrder): Promise<PaymentResult>
  verifyWebhook(payload: any, signature?: string): Promise<WebhookResult>
  processRefund(order: TopupOrder): Promise<RefundResult>
}

interface TopupOrder {
  id: string
  userId: string
  channel: string
  dtAmount: number
  priceKrw: number
  provider: string
  idempotencyKey: string
}

interface PaymentResult {
  success: boolean
  paymentId?: string
  checkoutUrl?: string
  error?: string
}

interface WebhookResult {
  valid: boolean
  orderId?: string
  status?: 'paid' | 'failed' | 'canceled'
  paymentId?: string
  error?: string
}

interface RefundResult {
  success: boolean
  refundId?: string
  error?: string
}

// Mock Payment Provider (fully implemented)
class MockPaymentProvider implements PaymentProvider {
  name = 'mock'

  async createPayment(order: TopupOrder): Promise<PaymentResult> {
    // Simulate payment creation
    const paymentId = `mock_pay_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`

    return {
      success: true,
      paymentId,
      checkoutUrl: `https://mock-payment.example.com/checkout/${paymentId}?amount=${order.priceKrw}&orderId=${order.id}`,
    }
  }

  async verifyWebhook(payload: any, _signature?: string): Promise<WebhookResult> {
    // Mock webhook verification - always valid for testing
    const { orderId, status, paymentId } = payload

    if (!orderId || !status) {
      return { valid: false, error: 'Missing required fields' }
    }

    return {
      valid: true,
      orderId,
      status,
      paymentId: paymentId || `mock_pay_${Date.now()}`,
    }
  }

  async processRefund(order: TopupOrder): Promise<RefundResult> {
    // Simulate refund
    return {
      success: true,
      refundId: `mock_refund_${Date.now()}`,
    }
  }
}

// PortOne Provider (placeholder)
class PortOneProvider implements PaymentProvider {
  name = 'portone'

  async createPayment(_order: TopupOrder): Promise<PaymentResult> {
    // TODO: Implement with PortOne SDK
    return { success: false, error: 'PortOne integration not configured' }
  }

  async verifyWebhook(_payload: any, _signature?: string): Promise<WebhookResult> {
    // TODO: Implement webhook verification
    return { valid: false, error: 'PortOne integration not configured' }
  }

  async processRefund(_order: TopupOrder): Promise<RefundResult> {
    return { success: false, error: 'PortOne integration not configured' }
  }
}

// Toss Provider (placeholder)
class TossProvider implements PaymentProvider {
  name = 'toss'

  async createPayment(_order: TopupOrder): Promise<PaymentResult> {
    return { success: false, error: 'Toss integration not configured' }
  }

  async verifyWebhook(_payload: any, _signature?: string): Promise<WebhookResult> {
    return { valid: false, error: 'Toss integration not configured' }
  }

  async processRefund(_order: TopupOrder): Promise<RefundResult> {
    return { success: false, error: 'Toss integration not configured' }
  }
}

// Provider factory
function getProvider(name: string): PaymentProvider {
  switch (name) {
    case 'mock':
      return new MockPaymentProvider()
    case 'portone':
      return new PortOneProvider()
    case 'toss':
      return new TossProvider()
    default:
      return new MockPaymentProvider()
  }
}

// Pricing calculation
function calculatePrice(dtAmount: number, channel: string, vatIncluded: boolean = true): { priceKrw: number; vatAmount: number } {
  const basePrice = dtAmount // 1 DT = 1 KRW face value
  const vatRate = 0.1

  // Channel-specific multipliers (iOS/Android may have different rates due to store fees)
  let multiplier = 1.0
  if (channel === 'ios') {
    multiplier = 1.3 // Apple's 30% cut
  } else if (channel === 'android') {
    multiplier = 1.15 // Google's 15% cut (reduced rate)
  }

  const priceBeforeVat = Math.ceil(basePrice * multiplier)

  if (vatIncluded) {
    // Price already includes VAT
    const vatAmount = Math.floor(priceBeforeVat * vatRate / (1 + vatRate))
    return { priceKrw: priceBeforeVat, vatAmount }
  } else {
    // Add VAT on top
    const vatAmount = Math.ceil(priceBeforeVat * vatRate)
    return { priceKrw: priceBeforeVat + vatAmount, vatAmount }
  }
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    const url = new URL(req.url)
    const path = url.pathname.split('/').pop()

    // Route handling
    if (req.method === 'POST') {
      const body = await req.json()

      switch (path) {
        case 'quote': {
          // Get price quote without creating order
          const { dtAmount, channel = 'web' } = body
          const { priceKrw, vatAmount } = calculatePrice(dtAmount, channel)

          return new Response(
            JSON.stringify({
              dtAmount,
              priceKrw,
              vatAmount,
              vatIncluded: true,
              channel,
              channelDisclosure: channel === 'ios'
                ? '앱스토어 수수료가 포함된 가격입니다.'
                : channel === 'android'
                  ? '플레이스토어 수수료가 포함된 가격입니다.'
                  : null,
            }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          )
        }

        case 'create': {
          // Create top-up order
          const authHeader = req.headers.get('Authorization')
          if (!authHeader) {
            return new Response(JSON.stringify({ error: 'Unauthorized' }), {
              status: 401,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            })
          }

          // Verify user
          const { data: { user }, error: authError } = await supabase.auth.getUser(
            authHeader.replace('Bearer ', '')
          )

          if (authError || !user) {
            return new Response(JSON.stringify({ error: 'Invalid token' }), {
              status: 401,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            })
          }

          const { dtAmount, channel = 'web', provider = 'mock' } = body

          // Validate amount
          if (!dtAmount || dtAmount <= 0) {
            return new Response(JSON.stringify({ error: 'Invalid amount' }), {
              status: 400,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            })
          }

          // Check daily limit
          const { data: limitCheck } = await supabase.rpc('dt_check_daily_limit', {
            p_user_id: user.id,
            p_new_amount: dtAmount,
          })

          if (!limitCheck) {
            return new Response(JSON.stringify({ error: 'Daily top-up limit exceeded' }), {
              status: 400,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            })
          }

          // Calculate price
          const { priceKrw } = calculatePrice(dtAmount, channel)

          // Generate idempotency key
          const idempotencyKey = `${user.id}_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`

          // Create order
          const { data: order, error: orderError } = await supabase
            .from('dt_topup_orders')
            .insert({
              user_id: user.id,
              channel,
              dt_amount: dtAmount,
              price_krw: priceKrw,
              vat_included: true,
              provider,
              idempotency_key: idempotencyKey,
            })
            .select()
            .single()

          if (orderError) {
            console.error('Order creation error:', orderError)
            return new Response(JSON.stringify({ error: 'Failed to create order' }), {
              status: 500,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            })
          }

          return new Response(JSON.stringify({ order }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          })
        }

        case 'start': {
          // Start payment process
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

          const { orderId } = body

          // Get order
          const { data: order, error: orderError } = await supabase
            .from('dt_topup_orders')
            .select('*')
            .eq('id', orderId)
            .eq('user_id', user.id)
            .single()

          if (orderError || !order) {
            return new Response(JSON.stringify({ error: 'Order not found' }), {
              status: 404,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            })
          }

          if (order.status !== 'pending') {
            return new Response(JSON.stringify({ error: 'Order already processed' }), {
              status: 400,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            })
          }

          // Get provider and create payment
          const provider = getProvider(order.provider)
          const paymentResult = await provider.createPayment({
            id: order.id,
            userId: order.user_id,
            channel: order.channel,
            dtAmount: order.dt_amount,
            priceKrw: order.price_krw,
            provider: order.provider,
            idempotencyKey: order.idempotency_key,
          })

          if (!paymentResult.success) {
            return new Response(JSON.stringify({ error: paymentResult.error }), {
              status: 500,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            })
          }

          // Update order with payment ID
          await supabase
            .from('dt_topup_orders')
            .update({ provider_payment_id: paymentResult.paymentId })
            .eq('id', orderId)

          return new Response(
            JSON.stringify({
              paymentId: paymentResult.paymentId,
              checkoutUrl: paymentResult.checkoutUrl,
            }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          )
        }

        case 'webhook': {
          // Handle payment webhook
          const providerName = url.searchParams.get('provider') || 'mock'
          const signature = req.headers.get('x-signature') || undefined

          const provider = getProvider(providerName)
          const webhookResult = await provider.verifyWebhook(body, signature)

          if (!webhookResult.valid) {
            console.error('Webhook verification failed:', webhookResult.error)
            return new Response(JSON.stringify({ error: webhookResult.error }), {
              status: 400,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            })
          }

          // Process based on status
          if (webhookResult.status === 'paid') {
            // Credit the top-up (idempotent)
            const { data: result, error } = await supabase.rpc('dt_credit_topup', {
              p_order_id: webhookResult.orderId,
            })

            if (error) {
              console.error('Credit topup error:', error)
              return new Response(JSON.stringify({ error: 'Failed to process payment' }), {
                status: 500,
                headers: { ...corsHeaders, 'Content-Type': 'application/json' },
              })
            }

            const creditResult = result[0]
            if (!creditResult.success) {
              // Could be already processed (idempotent) or actual error
              if (creditResult.error?.includes('already processed')) {
                return new Response(JSON.stringify({ success: true, message: 'Already processed' }), {
                  headers: { ...corsHeaders, 'Content-Type': 'application/json' },
                })
              }
              return new Response(JSON.stringify({ error: creditResult.error }), {
                status: 400,
                headers: { ...corsHeaders, 'Content-Type': 'application/json' },
              })
            }

            return new Response(JSON.stringify({ success: true, lotId: creditResult.lot_id }), {
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            })
          } else if (webhookResult.status === 'failed' || webhookResult.status === 'canceled') {
            // Update order status
            await supabase
              .from('dt_topup_orders')
              .update({ status: webhookResult.status })
              .eq('id', webhookResult.orderId)

            return new Response(JSON.stringify({ success: true }), {
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            })
          }

          return new Response(JSON.stringify({ success: true }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          })
        }

        case 'mock-complete': {
          // For testing: simulate successful payment webhook
          const { orderId } = body

          const { data: result } = await supabase.rpc('dt_credit_topup', {
            p_order_id: orderId,
          })

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
