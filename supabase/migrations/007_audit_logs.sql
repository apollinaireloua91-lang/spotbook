create extension if not exists pgsodium;

create table if not exists audit_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id),
  action text not null,
  resource_type text,
  resource_id uuid,
  metadata jsonb,
  ip_address text,
  created_at timestamptz default now()
);

alter table audit_logs enable row level security;

drop policy if exists "audit_logs_select_own" on audit_logs;
create policy "audit_logs_select_own" on audit_logs
for select using (auth.uid() = user_id);

drop policy if exists "audit_logs_insert_owner_or_service" on audit_logs;
create policy "audit_logs_insert_owner_or_service" on audit_logs
for insert with check (
  auth.role() = 'service_role' or auth.uid() = user_id
);

create or replace function public.insert_audit_log(
  p_user_id uuid,
  p_action text,
  p_resource_type text default null,
  p_resource_id uuid default null,
  p_metadata jsonb default '{}'::jsonb,
  p_ip_address text default null
) returns void
language plpgsql
security definer
as $$
begin
  insert into public.audit_logs (
    user_id, action, resource_type, resource_id, metadata, ip_address
  ) values (
    p_user_id, p_action, p_resource_type, p_resource_id, p_metadata, p_ip_address
  );
end;
$$;

create or replace function public.encrypt_social_token(p_token text)
returns text
language plpgsql
security definer
as $$
declare
  v_key bytea;
  v_nonce bytea;
  v_cipher bytea;
begin
  v_key := pgsodium.crypto_generichash(
    convert_to(coalesce(current_setting('app.settings.oauth_crypto_key', true), 'spotbook-default-key'), 'utf8'),
    32
  );
  v_nonce := pgsodium.randombytes_buf(24);
  v_cipher := pgsodium.crypto_secretbox(convert_to(p_token, 'utf8'), v_nonce, v_key);
  return encode(v_nonce, 'hex') || ':' || encode(v_cipher, 'hex');
end;
$$;

create or replace function public.decrypt_social_token(p_ciphertext text)
returns text
language plpgsql
security definer
as $$
declare
  v_key bytea;
  v_parts text[];
  v_nonce bytea;
  v_cipher bytea;
  v_plain bytea;
begin
  v_parts := string_to_array(p_ciphertext, ':');
  if array_length(v_parts, 1) != 2 then
    return null;
  end if;
  v_key := pgsodium.crypto_generichash(
    convert_to(coalesce(current_setting('app.settings.oauth_crypto_key', true), 'spotbook-default-key'), 'utf8'),
    32
  );
  v_nonce := decode(v_parts[1], 'hex');
  v_cipher := decode(v_parts[2], 'hex');
  v_plain := pgsodium.crypto_secretbox_open(v_cipher, v_nonce, v_key);
  return convert_from(v_plain, 'utf8');
exception when others then
  return null;
end;
$$;
