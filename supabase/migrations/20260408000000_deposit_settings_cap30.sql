-- Cap deposit percentage at 30% max (was 50%).

-- ─── services: tighten deposit_value cap from 50% to 30% ─────────────────────

ALTER TABLE services
  DROP CONSTRAINT IF EXISTS services_deposit_value_cap;

ALTER TABLE services
  ADD CONSTRAINT services_deposit_value_cap
    CHECK (
      deposit_type != 'percentage'
      OR deposit_value IS NULL
      OR deposit_value BETWEEN 10 AND 30
    );

-- Clamp any existing percentage deposits that exceed 30%.
UPDATE services
SET deposit_value = 30
WHERE deposit_type = 'percentage'
  AND deposit_value > 30;
