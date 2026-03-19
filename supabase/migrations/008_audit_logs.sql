-- ============================================================
-- SPOTBOOK — 005_audit_logs.sql
-- Audit logs table with RLS
-- ============================================================

CREATE TABLE audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id),
  action text NOT NULL,
  resource_type text,
  resource_id uuid,
  metadata jsonb,
  ip_address text,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_own_logs" ON audit_logs
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "service_insert_logs" ON audit_logs
  FOR INSERT WITH CHECK (true);

CREATE INDEX idx_audit_logs_user ON audit_logs(user_id, created_at DESC);
CREATE INDEX idx_audit_logs_action ON audit_logs(action, created_at DESC);
