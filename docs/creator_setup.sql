-- Run this in Supabase SQL Editor once, replacing the email address below
-- with the creator account's exact login email.

update public.profiles
set is_owner = true, is_primary = true, status = 'approved'
where lower(email) = lower('randypl2026@gmail.com');

-- Verify that exactly the intended creator account now has full authority.
select email, name, is_owner, is_primary, status
from public.profiles
where is_owner = true;