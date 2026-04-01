-- Autorise le scope `upload` pour le rate limiting Edge (vidéos / direct upload).
CREATE OR REPLACE FUNCTION "public"."rate_limit_consume"(
  "p_scope" "text",
  "p_rate_key" "text",
  "p_bucket" bigint,
  "p_max" integer,
  "p_window_ms" bigint
) RETURNS TABLE("allowed" boolean, "retry_in_minutes" integer, "remaining" integer)
  LANGUAGE "plpgsql"
  SECURITY DEFINER
  SET "search_path" TO 'public'
  AS $$
DECLARE
  v_now_ms bigint := (extract(epoch from clock_timestamp()) * 1000)::bigint;
  v_count int;
  v_expires timestamptz := to_timestamp(((p_bucket + 1) * p_window_ms) / 1000.0);
  v_mod bigint;
  v_retry numeric;
BEGIN
  IF p_scope NOT IN ('login', 'otp', 'payment', 'upload') THEN
    allowed := false;
    retry_in_minutes := 0;
    remaining := 0;
    RETURN NEXT;
    RETURN;
  END IF;

  PERFORM pg_advisory_xact_lock(
    (hashtext(p_scope || chr(1) || p_rate_key || chr(1) || p_bucket::text))::bigint
  );

  SELECT c.hit_count INTO v_count
  FROM public.rate_limit_counters AS c
  WHERE c.scope = p_scope
    AND c.rate_key = p_rate_key
    AND c.bucket = p_bucket;

  IF FOUND THEN
    IF v_count >= p_max THEN
      v_mod := v_now_ms % p_window_ms;
      v_retry := ceil((p_window_ms - v_mod)::numeric / 60000);
      allowed := false;
      retry_in_minutes := GREATEST(1, v_retry::int);
      remaining := 0;
      RETURN NEXT;
      RETURN;
    END IF;

    UPDATE public.rate_limit_counters
    SET hit_count = hit_count + 1
    WHERE scope = p_scope
      AND rate_key = p_rate_key
      AND bucket = p_bucket;

    allowed := true;
    retry_in_minutes := 0;
    remaining := GREATEST(0, p_max - (v_count + 1));
    RETURN NEXT;
    RETURN;
  END IF;

  INSERT INTO public.rate_limit_counters (scope, rate_key, bucket, hit_count, expires_at)
  VALUES (p_scope, p_rate_key, p_bucket, 1, v_expires);

  allowed := true;
  retry_in_minutes := 0;
  remaining := GREATEST(0, p_max - 1);
  RETURN NEXT;
END;
$$;
