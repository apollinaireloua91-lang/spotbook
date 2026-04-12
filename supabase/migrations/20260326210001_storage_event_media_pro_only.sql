-- Restreint les uploads `event-media` au dossier `{auth.uid()}/...` (propriétaire).
-- Avant : tout utilisateur authentifié pouvait insérer dans le bucket.
DROP POLICY IF EXISTS "Event media: upload auth" ON storage.objects;

CREATE POLICY "Event media: upload own folder"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'event-media'
    AND (auth.uid())::text = (storage.foldername(name))[1]
  );
