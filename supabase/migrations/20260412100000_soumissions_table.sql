-- ═══════════════════════════════════════════════════════════════════════════════
-- SOUMISSIONS (Quotes) — Pro-initiated service quotes shared with clients
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS soumissions (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pro_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  client_id     UUID REFERENCES users(id) ON DELETE SET NULL,

  -- Quote details
  title         TEXT NOT NULL CHECK (char_length(title) >= 3),
  description   TEXT,
  service_id    UUID REFERENCES services(id) ON DELETE SET NULL,

  -- Line items stored as JSONB array: [{label, qty, unit_price_cents}]
  line_items    JSONB NOT NULL DEFAULT '[]'::jsonb,
  subtotal_cents  INTEGER NOT NULL DEFAULT 0 CHECK (subtotal_cents >= 0),
  tax_cents       INTEGER NOT NULL DEFAULT 0 CHECK (tax_cents >= 0),
  total_cents     INTEGER NOT NULL DEFAULT 0 CHECK (total_cents >= 0),

  -- Sharing
  share_token   TEXT UNIQUE NOT NULL DEFAULT encode(gen_random_bytes(16), 'hex'),
  client_email  TEXT,
  client_phone  TEXT,
  client_name   TEXT,

  -- Status workflow: draft → sent → viewed → accepted → paid | expired | cancelled
  status        TEXT NOT NULL DEFAULT 'draft'
                CHECK (status IN ('draft','sent','viewed','accepted','paid','expired','cancelled')),

  -- Payment
  payment_intent_id TEXT,
  paid_at       TIMESTAMPTZ,

  -- Validity
  valid_until   TIMESTAMPTZ,
  notes         TEXT,

  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_soumissions_pro_id ON soumissions(pro_id);
CREATE INDEX IF NOT EXISTS idx_soumissions_client_id ON soumissions(client_id);
CREATE INDEX IF NOT EXISTS idx_soumissions_share_token ON soumissions(share_token);
CREATE INDEX IF NOT EXISTS idx_soumissions_status ON soumissions(status);

-- Updated_at trigger
CREATE OR REPLACE FUNCTION update_soumissions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_soumissions_updated_at ON soumissions;
CREATE TRIGGER trg_soumissions_updated_at
  BEFORE UPDATE ON soumissions
  FOR EACH ROW EXECUTE FUNCTION update_soumissions_updated_at();

-- ═══════════════════════════════════════════════════════════════════════════════
-- RLS
-- ═══════════════════════════════════════════════════════════════════════════════
ALTER TABLE soumissions ENABLE ROW LEVEL SECURITY;

-- Pro can CRUD their own soumissions
CREATE POLICY soumissions_pro_select ON soumissions
  FOR SELECT TO authenticated
  USING (auth.uid() = pro_id);

CREATE POLICY soumissions_pro_insert ON soumissions
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = pro_id);

CREATE POLICY soumissions_pro_update ON soumissions
  FOR UPDATE TO authenticated
  USING (auth.uid() = pro_id);

CREATE POLICY soumissions_pro_delete ON soumissions
  FOR DELETE TO authenticated
  USING (auth.uid() = pro_id AND status = 'draft');

-- Client can view soumissions addressed to them
CREATE POLICY soumissions_client_select ON soumissions
  FOR SELECT TO authenticated
  USING (auth.uid() = client_id);

-- Client can update status (viewed, accepted)
CREATE POLICY soumissions_client_update ON soumissions
  FOR UPDATE TO authenticated
  USING (auth.uid() = client_id)
  WITH CHECK (status IN ('viewed', 'accepted'));

-- Anyone with a share_token can read (for anonymous link sharing)
CREATE POLICY soumissions_share_token_select ON soumissions
  FOR SELECT TO anon
  USING (share_token IS NOT NULL);
