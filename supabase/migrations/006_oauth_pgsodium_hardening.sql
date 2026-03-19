-- OAuth token hardening with pgsodium helpers

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'social_connections'
      and column_name = 'access_token'
  ) then
    execute $sql$
      comment on column public.social_connections.access_token is
      'Encrypted token only (pgsodium). Never return to Flutter clients.'
    $sql$;
  end if;
end;
$$;

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
