-- =============================================================================
-- Spotbook — correctif à exécuter UNE FOIS sur le projet Supabase (SQL Editor)
-- Corrige : PGRST204 (colonnes), premier upsert pro bloqué (RLS INSERT), geo users
-- =============================================================================

-- Colonnes attendues par l’app (KYC / édition profil)
ALTER TABLE profiles_pro
  ADD COLUMN IF NOT EXISTS tel text,
  ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

-- RLS : autoriser un pro à créer sa ligne (sans ça, l’upsert échoue au 1er enregistrement)
CREATE POLICY IF NOT EXISTS "profiles_pro_own_insert" ON profiles_pro
  FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Position (écran permission / requestLocationAndSave)
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS latitude double precision,
  ADD COLUMN IF NOT EXISTS longitude double precision;

-- Recharger le cache schéma PostgREST (optionnel mais utile après ALTER)
NOTIFY pgrst, 'reload schema';
