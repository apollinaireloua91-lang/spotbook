-- Aligne la contrainte CHECK avec rate_limit_consume (scope `upload` pour Edge / vidéo).
ALTER TABLE public.rate_limit_counters
  DROP CONSTRAINT IF EXISTS rate_limit_counters_scope_check;

ALTER TABLE public.rate_limit_counters
  ADD CONSTRAINT rate_limit_counters_scope_check
  CHECK (
    scope = ANY (
      ARRAY[
        'login'::text,
        'otp'::text,
        'payment'::text,
        'upload'::text
      ]
    )
  );
