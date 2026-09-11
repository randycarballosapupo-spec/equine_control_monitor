import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type' };

const base64Url = (value: Uint8Array | string) => {
  const text = typeof value === 'string' ? btoa(value) : btoa(String.fromCharCode(...value));
  return text.replaceAll('+', '-').replaceAll('/', '_').replaceAll('=', '');
};

async function firebaseAccessToken(credentials: Record<string, string>) {
  const now = Math.floor(Date.now() / 1000);
  const header = base64Url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const payload = base64Url(JSON.stringify({ iss: credentials.client_email, scope: 'https://www.googleapis.com/auth/firebase.messaging', aud: credentials.token_uri, iat: now, exp: now + 3600 }));
  const pem = credentials.private_key.replace(/-----[^-]+-----|\s/g, '');
  const keyBytes = Uint8Array.from(atob(pem), (character) => character.charCodeAt(0));
  const key = await crypto.subtle.importKey('pkcs8', keyBytes, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign']);
  const signature = new Uint8Array(await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(`${header}.${payload}`)));
  const response = await fetch(credentials.token_uri, { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${header}.${payload}.${base64Url(signature)}` });
  const data = await response.json();
  if (!response.ok) throw new Error(data.error_description ?? 'Firebase authorization failed');
  return data.access_token as string;
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  try {
    const authorization = request.headers.get('Authorization');
    if (!authorization) throw new Error('Unauthorized');
    const url = Deno.env.get('SUPABASE_URL')!;
    const userClient = createClient(url, Deno.env.get('SUPABASE_ANON_KEY')!, { global: { headers: { Authorization: authorization } } });
    const { data: { user } } = await userClient.auth.getUser();
    if (!user) throw new Error('Unauthorized');
    const { taskId } = await request.json();
    const adminClient = createClient(url, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
    const { data: task, error: taskError } = await adminClient.from('shared_care_tasks').select().eq('id', taskId).single();
    if (taskError || !task || task.caregiver_id !== user.id || task.completed_by !== user.id) throw new Error('Forbidden');
    const { data: tokens } = await adminClient.from('device_tokens').select('token').eq('user_id', task.owner_id);
    if (!tokens?.length) return Response.json({ sent: 0 }, { headers: corsHeaders });
    const { data: owner } = await adminClient.from('profiles').select('preferred_language').eq('id', task.owner_id).single();
    const credentials = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON')!);
    const accessToken = await firebaseAccessToken(credentials);
    const language = owner?.preferred_language ?? 'pl';
    const messages: Record<string, { title: string; body: string }> = {
      pl: { title: 'Equi Harmony Monitor', body: `${task.horse_name}: ${task.item_name} wykonano.` },
      es: { title: 'Equi Harmony Monitor', body: `${task.horse_name}: ${task.item_name} completado.` },
      de: { title: 'Equi Harmony Monitor', body: `${task.horse_name}: ${task.item_name} erledigt.` },
      nl: { title: 'Equi Harmony Monitor', body: `${task.horse_name}: ${task.item_name} voltooid.` },
      fr: { title: 'Equi Harmony Monitor', body: `${task.horse_name}: ${task.item_name} terminé.` },
      en: { title: 'Equi Harmony Monitor', body: `${task.horse_name}: ${task.item_name} completed.` },
      pt: { title: 'Equi Harmony Monitor', body: `${task.horse_name}: ${task.item_name} concluído.` },
    };
    const { title, body } = messages[language] ?? messages.pl;
    let sent = 0;
    for (const { token } of tokens) {
      const response = await fetch(`https://fcm.googleapis.com/v1/projects/${credentials.project_id}/messages:send`, { method: 'POST', headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' }, body: JSON.stringify({ message: { token, notification: { title, body }, android: { priority: 'high', notification: { channel_id: 'equiharmony_alerts_v2', sound: 'default' } } } }) });
      if (response.ok) sent++;
    }
    return Response.json({ sent }, { headers: corsHeaders });
  } catch (error) {
    return Response.json({ error: error instanceof Error ? error.message : 'Notification failed' }, { status: 400, headers: corsHeaders });
  }
});