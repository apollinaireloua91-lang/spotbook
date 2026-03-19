-- OAuth token hardening with pgsodium helpers

-- Ensure plaintext tokens are never selected by default policies.
-- Keep encrypted token in social_connections.access_token only.
comment on column public.social_connections.access_token is
  'Encrypted token only (pgsodium). Never return to Flutter clients.';

-- Optional key rotation helper: decrypt with current key then re-encrypt.
create or replace function public.rotate_social_token_cipher(p_ciphertext text)
returns text
language plpgsql
security definer
as $$
declare
  v_plain text;
begin
  v_plain := public.decrypt_social_token(p_ciphertext);
  if v_plain is null then
    return p_ciphertext;
  end if;
  return public.encrypt_social_token(v_plain);
end;
$$;
