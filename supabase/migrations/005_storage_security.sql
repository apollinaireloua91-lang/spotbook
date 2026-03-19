-- Storage hardening policies for Spotbook

-- Public read buckets
drop policy if exists "avatars_public_read" on storage.objects;
create policy "avatars_public_read"
on storage.objects for select
using (bucket_id = 'avatars');

drop policy if exists "covers_public_read" on storage.objects;
create policy "covers_public_read"
on storage.objects for select
using (bucket_id = 'covers');

drop policy if exists "event_covers_public_read" on storage.objects;
create policy "event_covers_public_read"
on storage.objects for select
using (bucket_id = 'event-covers');

-- Owner write only for avatars/covers (path format: <uid>/...)
drop policy if exists "avatars_owner_write" on storage.objects;
create policy "avatars_owner_write"
on storage.objects for all
using (
  bucket_id = 'avatars'
  and auth.uid()::text = (storage.foldername(name))[1]
)
with check (
  bucket_id = 'avatars'
  and auth.uid()::text = (storage.foldername(name))[1]
);

drop policy if exists "covers_owner_write" on storage.objects;
create policy "covers_owner_write"
on storage.objects for all
using (
  bucket_id = 'covers'
  and auth.uid()::text = (storage.foldername(name))[1]
)
with check (
  bucket_id = 'covers'
  and auth.uid()::text = (storage.foldername(name))[1]
);

-- Event covers: pro owner only
drop policy if exists "event_covers_pro_owner_write" on storage.objects;
create policy "event_covers_pro_owner_write"
on storage.objects for all
using (
  bucket_id = 'event-covers'
  and auth.uid()::text = (storage.foldername(name))[1]
  and exists (
    select 1 from public.profiles_pro p where p.id = auth.uid()
  )
)
with check (
  bucket_id = 'event-covers'
  and auth.uid()::text = (storage.foldername(name))[1]
  and exists (
    select 1 from public.profiles_pro p where p.id = auth.uid()
  )
);

-- KYC documents: private, write owner only, read admin only
drop policy if exists "kyc_documents_admin_read_only" on storage.objects;
create policy "kyc_documents_admin_read_only"
on storage.objects for select
using (
  bucket_id = 'kyc-documents'
  and exists (
    select 1 from public.users u
    where u.id = auth.uid() and u.role = 'admin'
  )
);

drop policy if exists "kyc_documents_user_write_only" on storage.objects;
create policy "kyc_documents_user_write_only"
on storage.objects for insert
with check (
  bucket_id = 'kyc-documents'
  and auth.uid()::text = (storage.foldername(name))[1]
);

drop policy if exists "kyc_documents_user_delete_own" on storage.objects;
create policy "kyc_documents_user_delete_own"
on storage.objects for delete
using (
  bucket_id = 'kyc-documents'
  and auth.uid()::text = (storage.foldername(name))[1]
);

-- Chat images: only participants of conversation can read/write.
-- Path format: <conversation_id>/<user_id>/<filename>
drop policy if exists "chat_images_participants_read" on storage.objects;
create policy "chat_images_participants_read"
on storage.objects for select
using (
  bucket_id = 'chat-images'
  and exists (
    select 1
    from public.conversations c
    where c.id::text = (storage.foldername(name))[1]
      and (c.client_id = auth.uid() or c.pro_id = auth.uid())
  )
);

drop policy if exists "chat_images_participants_write" on storage.objects;
create policy "chat_images_participants_write"
on storage.objects for insert
with check (
  bucket_id = 'chat-images'
  and auth.uid()::text = (storage.foldername(name))[2]
  and exists (
    select 1
    from public.conversations c
    where c.id::text = (storage.foldername(name))[1]
      and (c.client_id = auth.uid() or c.pro_id = auth.uid())
  )
);
