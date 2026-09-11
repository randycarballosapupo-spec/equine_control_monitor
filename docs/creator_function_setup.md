# Creator Account Setup

The creator account is the only account allowed to create users and administrators.

1. In Supabase Dashboard, open SQL Editor and run [creator_setup.sql](creator_setup.sql) after replacing the placeholder with the creator's login email.
2. Open Edge Functions, create a function named `create-user`, and replace its code with [../supabase/functions/create-user/index.ts](../supabase/functions/create-user/index.ts).
3. Deploy the function. Supabase provides `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY` to deployed Edge Functions automatically.
4. Sign out and back in to the creator account. Open User management: the add-user and add-administrator controls should be visible only there.

The function checks `profiles.is_owner` using the caller's access token and creates the account with the server-side Admin API. It keeps the creator signed in and creates new accounts as approved.