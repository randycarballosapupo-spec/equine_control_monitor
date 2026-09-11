import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type' };

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  try {
    const authorization = request.headers.get('Authorization');
    if (!authorization) throw new Error('Unauthorized');
    const url = Deno.env.get('SUPABASE_URL')!;
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const userClient = createClient(url, Deno.env.get('SUPABASE_ANON_KEY')!, { global: { headers: { Authorization: authorization } } });
    const { data: { user: caller } } = await userClient.auth.getUser();
    if (!caller) throw new Error('Unauthorized');
    const { data: callerProfile } = await userClient.from('profiles').select('is_owner,is_primary').eq('id', caller.id).single();
    if (callerProfile?.is_owner != true) throw new Error('Forbidden');

    const body = await request.json();
    const email = String(body.email ?? '').trim().toLowerCase();
    const password = String(body.password ?? '');
    const name = String(body.name ?? '').trim();
    const roles = Array.isArray(body.roles) ? body.roles.map(String) : [];
    if (!email.includes('@') || password.length < 6 || !name || roles.length === 0) throw new Error('Invalid user data');

    const adminClient = createClient(url, serviceRoleKey);
    const { data, error } = await adminClient.auth.admin.createUser({ email, password, email_confirm: true });
    if (error || !data.user) throw error ?? new Error('User creation failed');
    const { error: profileError } = await adminClient.from('profiles').insert({ id: data.user.id, email, name, roles, stable_name: String(body.stableName ?? ''), status: 'approved', preferred_language: 'pl' });
    if (profileError) {
      await adminClient.auth.admin.deleteUser(data.user.id);
      throw profileError;
    }
    return Response.json({ id: data.user.id }, { headers: corsHeaders });
  } catch (error) {
    return Response.json({ error: error instanceof Error ? error.message : 'Creation failed' }, { status: 400, headers: corsHeaders });
  }
});