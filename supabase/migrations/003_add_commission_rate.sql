ALTER TABLE profiles_pro
  ADD COLUMN IF NOT EXISTS commission_rate decimal DEFAULT 0.12,
  ADD COLUMN IF NOT EXISTS is_top_pro bool DEFAULT false,
  ADD COLUMN IF NOT EXISTS average_rating decimal DEFAULT 0,
  ADD COLUMN IF NOT EXISTS review_count int DEFAULT 0,
  ADD COLUMN IF NOT EXISTS kyc_status text DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS stripe_account_id text,
  ADD COLUMN IF NOT EXISTS stripe_onboarded bool DEFAULT false;

-- Politique RLS : seul le service peut modifier commission_rate
CREATE POLICY "block_commission_update" ON profiles_pro
  FOR UPDATE USING (auth.uid() = id)
  WITH CHECK (commission_rate = (SELECT commission_rate FROM profiles_pro WHERE id = auth.uid()));
