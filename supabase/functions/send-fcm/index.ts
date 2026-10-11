// @ts-ignore
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
// @ts-ignore
import { JWT } from 'https://esm.sh/google-auth-library@8.7.0';
// @ts-ignore
import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// @ts-ignore
const serviceAccountKeyStr = Deno.env.get('FIREBASE_SERVICE_ACCOUNT') || Deno.env.get('FIREBASE_SERVICE_ACCOUNT_KEY');

async function getAccessToken(): Promise<{ token: string; projectId: string }> {
  if (!serviceAccountKeyStr) throw new Error('FIREBASE_SERVICE_ACCOUNT secret is not set');
  const sa = JSON.parse(serviceAccountKeyStr);
  const jwt = new JWT({
    email: sa.client_email,
    key: sa.private_key,
    scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
  });
  const tokens = await jwt.authorize();
  return { token: tokens.access_token!, projectId: sa.project_id };
}

function getSupabaseClient(): SupabaseClient | null {
  // @ts-ignore
  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
  // @ts-ignore
  const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
  if (supabaseUrl && supabaseKey) {
    return createClient(supabaseUrl, supabaseKey);
  }
  return null;
}

interface FcmPayload {
  targetTokens?: string[];
  title?: string;
  body?: string;
  imageUrl?: string;
  data?: Record<string, unknown>;
  sound?: string;
}

interface BroadcastResult {
  total: number;
  success: number;
  failed: number;
  staleRemoved: number;
  errors: string[];
}

function formatError(err: unknown): string {
  if (err instanceof Error) {
    return err.message;
  }
  if (typeof err === 'string') {
    return err;
  }
  return JSON.stringify(err);
}

function stringifyDataValue(v: unknown): string {
  if (typeof v === 'string') return v;
  if (typeof v === 'number' || typeof v === 'boolean') return `${v}`;
  if (v === null || v === undefined) return '';
  return JSON.stringify(v);
}

function resolveImageUrl(imageUrl?: string, dataObj?: Record<string, unknown>): string | undefined {
  if (imageUrl) return imageUrl;
  if (!dataObj) return undefined;
  if (typeof dataObj.image_url === 'string' && dataObj.image_url.trim() !== '') {
    return dataObj.image_url;
  }
  if (typeof dataObj.image === 'string' && dataObj.image.trim() !== '') {
    return dataObj.image;
  }
  return undefined;
}

function resolveChannelId(soundVal: string, dataObj?: Record<string, unknown>): string {
  if (dataObj && typeof dataObj.channel_id === 'string' && dataObj.channel_id.trim() !== '') {
    return dataObj.channel_id;
  }
  return soundVal.includes('match') ? 'match_alert_channel' : 'matrimony_alerts_channel';
}

function resolveSound(payloadSound?: string, dataObj?: Record<string, unknown>): string {
  if (typeof payloadSound === 'string' && payloadSound.trim() !== '') {
    return payloadSound;
  }
  if (dataObj) {
    if (typeof dataObj.sound === 'string' && dataObj.sound.trim() !== '') {
      return dataObj.sound;
    }
    if (typeof dataObj.sound_name === 'string' && dataObj.sound_name.trim() !== '') {
      return dataObj.sound_name;
    }
  }
  return 'default';
}

function buildDataEntries(dataObj: Record<string, unknown>): Record<string, string> {
  const entries: Record<string, string> = {};
  for (const [k, v] of Object.entries(dataObj)) {
    if (v !== undefined && v !== null) {
      entries[k] = stringifyDataValue(v);
    }
  }
  return entries;
}

function buildFcmMessage(fcmToken: string, payload: FcmPayload): Record<string, unknown> {
  const dataObj = payload.data ?? {};
  const soundVal = resolveSound(payload.sound, dataObj);
  const channelId = resolveChannelId(soundVal, dataObj);
  const iconVal = typeof dataObj.icon === 'string' && dataObj.icon ? dataObj.icon : 'ic_launcher';
  const imgUrl = resolveImageUrl(payload.imageUrl, dataObj);
  const titleVal = typeof payload.title === 'string' && payload.title ? payload.title : 'Kurichiyar Matrimony';
  const bodyVal = typeof payload.body === 'string' ? payload.body : '';
  const dataEntries = buildDataEntries(dataObj);
  const apsSound = soundVal.endsWith('.mp3') || soundVal.endsWith('.wav') ? soundVal : `${soundVal}.mp3`;

  return {
    message: {
      token: fcmToken,
      notification: {
        title: titleVal,
        body: bodyVal,
        ...(imgUrl ? { image: imgUrl } : {}),
      },
      data: dataEntries,
      android: {
        priority: 'high',
        notification: {
          title: titleVal,
          body: bodyVal,
          sound: soundVal,
          default_sound: soundVal === 'default',
          default_vibrate_timings: true,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
          channel_id: channelId,
          icon: iconVal,
          notification_priority: 'PRIORITY_MAX',
          ...(imgUrl ? { image: imgUrl } : {}),
        },
      },
      apns: {
        payload: {
          aps: {
            sound: apsSound,
            'content-available': 1,
            alert: {
              title: titleVal,
              body: bodyVal,
            },
          },
        },
      },
    },
  };
}

async function sendSingleFcm(
  fcmToken: string,
  projectId: string,
  accessToken: string,
  payload: FcmPayload
): Promise<{ success: boolean; isStale: boolean; error?: string }> {
  const message = buildFcmMessage(fcmToken, payload);

  try {
    const res = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify(message),
    });

    const result = await res.json();

    if (res.ok) {
      return { success: true, isStale: false };
    }

    const code = result?.error?.status || result?.error?.code || 'UNKNOWN';
    const detail = typeof result?.error?.message === 'string' ? result.error.message : '';
    const isStale =
      code === 'UNREGISTERED' ||
      code === 'NOT_FOUND' ||
      String(code).includes('UNREGISTERED') ||
      detail.includes('not a registered FCM');

    return { success: false, isStale, error: String(code) };
  } catch (err: unknown) {
    return { success: false, isStale: false, error: formatError(err) };
  }
}

async function removeStaleTokens(supabase: SupabaseClient | null, tokens: string[]): Promise<void> {
  if (!supabase || tokens.length === 0) return;
  console.log(`🧹 Removing ${tokens.length} stale token(s).`);
  for (const t of tokens) {
    await supabase.from('kurichiyar_profiles').update({ fcm_token: null }).eq('fcm_token', t);
  }
}

async function broadcastFcm(
  tokens: string[],
  projectId: string,
  accessToken: string,
  payload: FcmPayload,
  supabase: SupabaseClient | null
): Promise<BroadcastResult> {
  let successCount = 0;
  let failCount = 0;
  const invalidTokens: string[] = [];
  const errors: string[] = [];

  for (const fcmToken of tokens) {
    if (typeof fcmToken !== 'string' || fcmToken.trim() === '') {
      failCount++;
      continue;
    }

    const res = await sendSingleFcm(fcmToken, projectId, accessToken, payload);
    const tokenSuffix = fcmToken.slice(-8);

    if (res.success) {
      successCount++;
      console.log(`✅ Delivered to ...${tokenSuffix}`);
    } else {
      failCount++;
      console.error(`❌ FCM error for ...${tokenSuffix}: ${res.error}`);
      errors.push(`...${tokenSuffix}: ${res.error}`);
      if (res.isStale) {
        invalidTokens.push(fcmToken);
      }
    }
  }

  await removeStaleTokens(supabase, invalidTokens);

  return {
    total: tokens.length,
    success: successCount,
    failed: failCount,
    staleRemoved: invalidTokens.length,
    errors,
  };
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const payload: FcmPayload = await req.json();
    const { targetTokens, title } = payload;

    console.log(`📢 send-fcm invoked | tokens=${targetTokens?.length ?? 0} | title="${title ?? ''}"`);

    if (!targetTokens || targetTokens.length === 0) {
      return new Response(JSON.stringify({ error: 'No target tokens provided' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      });
    }

    const { token: accessToken, projectId } = await getAccessToken();
    const supabase = getSupabaseClient();

    const summary = await broadcastFcm(targetTokens, projectId, accessToken, payload, supabase);
    console.log('📊 Broadcast summary:', summary);

    return new Response(JSON.stringify(summary), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });
  } catch (err: unknown) {
    const message = formatError(err);
    console.error('send-fcm function error:', message);
    return new Response(JSON.stringify({ error: message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    });
  }
});
