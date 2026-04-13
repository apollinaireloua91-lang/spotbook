create extension if not exists "pg_net" with schema "extensions";

create extension if not exists "postgis" with schema "extensions";

drop policy "notifications_own" on "public"."notifications";

drop policy "pro_categories_select_all" on "public"."pro_categories";

drop policy "profiles_pro_anon_read" on "public"."profiles_pro";

drop policy "profiles_pro_own_update" on "public"."profiles_pro";

drop policy "users_own_read" on "public"."users";

drop policy "events_public_read" on "public"."events";

drop policy "notifications_service_insert" on "public"."notifications";

drop policy "reviews_update_as_client" on "public"."reviews";

drop policy "time_slots_public_read" on "public"."time_slots";

drop policy "users_own_update" on "public"."users";

revoke delete on table "public"."spatial_ref_sys" from "anon";

revoke insert on table "public"."spatial_ref_sys" from "anon";

revoke references on table "public"."spatial_ref_sys" from "anon";

revoke select on table "public"."spatial_ref_sys" from "anon";

revoke trigger on table "public"."spatial_ref_sys" from "anon";

revoke truncate on table "public"."spatial_ref_sys" from "anon";

revoke update on table "public"."spatial_ref_sys" from "anon";

revoke delete on table "public"."spatial_ref_sys" from "authenticated";

revoke insert on table "public"."spatial_ref_sys" from "authenticated";

revoke references on table "public"."spatial_ref_sys" from "authenticated";

revoke select on table "public"."spatial_ref_sys" from "authenticated";

revoke trigger on table "public"."spatial_ref_sys" from "authenticated";

revoke truncate on table "public"."spatial_ref_sys" from "authenticated";

revoke update on table "public"."spatial_ref_sys" from "authenticated";

revoke delete on table "public"."spatial_ref_sys" from "postgres";

revoke insert on table "public"."spatial_ref_sys" from "postgres";

revoke references on table "public"."spatial_ref_sys" from "postgres";

revoke select on table "public"."spatial_ref_sys" from "postgres";

revoke trigger on table "public"."spatial_ref_sys" from "postgres";

revoke truncate on table "public"."spatial_ref_sys" from "postgres";

revoke update on table "public"."spatial_ref_sys" from "postgres";

revoke delete on table "public"."spatial_ref_sys" from "service_role";

revoke insert on table "public"."spatial_ref_sys" from "service_role";

revoke references on table "public"."spatial_ref_sys" from "service_role";

revoke select on table "public"."spatial_ref_sys" from "service_role";

revoke trigger on table "public"."spatial_ref_sys" from "service_role";

revoke truncate on table "public"."spatial_ref_sys" from "service_role";

revoke update on table "public"."spatial_ref_sys" from "service_role";

alter table "public"."rate_limit_counters" drop constraint "rate_limit_counters_scope_check";

alter table "public"."videos" drop constraint "videos_status_check";

alter table "public"."audit_logs" drop constraint "audit_logs_user_id_fkey";

drop type "public"."geometry_dump";

drop type "public"."valid_detail";

drop index if exists "public"."idx_bookings_client";

drop index if exists "public"."idx_bookings_pro";

drop index if exists "public"."idx_notifications_idempotency_key";

drop index if exists "public"."idx_notifications_unread";

drop index if exists "public"."idx_notifications_user_type_created";

drop index if exists "public"."idx_video_comments_video";


  create table "public"."app_config" (
    "key" text not null,
    "value" text not null,
    "description" text,
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."app_config" enable row level security;


  create table "public"."catering_deposits" (
    "id" uuid not null default gen_random_uuid(),
    "submission_id" uuid not null,
    "amount" numeric(10,2) not null,
    "stripe_payment_intent_id" text,
    "status" text default 'pending'::text,
    "paid_at" timestamp with time zone,
    "refunded_at" timestamp with time zone,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."catering_deposits" enable row level security;


  create table "public"."catering_forfaits" (
    "id" uuid not null default gen_random_uuid(),
    "pro_id" uuid not null,
    "name" text not null,
    "price_per_person" numeric(10,2) not null,
    "description" text,
    "inclusions" text[] default '{}'::text[],
    "min_guests" integer default 10,
    "max_guests" integer default 200,
    "is_popular" boolean default false,
    "is_active" boolean default true,
    "sort_order" integer default 0,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."catering_forfaits" enable row level security;


  create table "public"."catering_gallery" (
    "id" uuid not null default gen_random_uuid(),
    "pro_id" uuid not null,
    "image_url" text not null,
    "caption" text,
    "sort_order" integer default 0,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."catering_gallery" enable row level security;


  create table "public"."catering_menu_items" (
    "id" uuid not null default gen_random_uuid(),
    "pro_id" uuid not null,
    "name" text not null,
    "description" text,
    "price_per_person" numeric(10,2) not null,
    "emoji" text default '🍽️'::text,
    "image_url" text,
    "is_bestseller" boolean default false,
    "is_active" boolean default true,
    "sort_order" integer default 0,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."catering_menu_items" enable row level security;


  create table "public"."catering_submissions" (
    "id" uuid not null default gen_random_uuid(),
    "client_id" uuid not null,
    "pro_id" uuid not null,
    "event_type" text not null,
    "guest_count" integer not null,
    "event_date" date not null,
    "event_time" time without time zone,
    "location" text,
    "forfait_id" uuid,
    "budget" text,
    "dietary_prefs" text[] default '{}'::text[],
    "notes" text,
    "status" text default 'pending'::text,
    "total_estimate" numeric(10,2),
    "deposit_amount" numeric(10,2),
    "deposit_percentage" numeric(5,2) default 30.00,
    "pro_quote_amount" numeric(10,2),
    "pro_quote_notes" text,
    "quoted_at" timestamp with time zone,
    "accepted_at" timestamp with time zone,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "commission_rate" numeric(5,4) default 0.18
      );


alter table "public"."catering_submissions" enable row level security;


  create table "public"."event_tickets" (
    "id" uuid not null default gen_random_uuid(),
    "event_id" uuid not null,
    "ticket_type_id" uuid not null,
    "client_id" uuid not null,
    "pro_id" uuid not null,
    "ticket_number" text not null,
    "quantity" integer not null default 1,
    "unit_price" numeric not null,
    "total_price" numeric not null,
    "currency" text default 'CAD'::text,
    "qr_code_token" uuid not null default gen_random_uuid(),
    "qr_code_data" text not null,
    "stripe_payment_intent_id" text,
    "payment_status" text default 'pending'::text,
    "commission_rate" numeric default 0.12,
    "commission_amount" numeric default 0,
    "service_fee" numeric default 2.50,
    "is_validated" boolean default false,
    "validated_at" timestamp with time zone,
    "validated_by" uuid,
    "validation_location" text,
    "status" text not null default 'valid'::text,
    "email_sent" boolean default false,
    "email_sent_at" timestamp with time zone,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."event_tickets" enable row level security;


  create table "public"."payments" (
    "id" uuid not null default gen_random_uuid(),
    "booking_id" uuid,
    "event_ticket_id" uuid,
    "user_id" uuid,
    "payment_type" text not null,
    "amount" numeric not null,
    "currency" text default 'CAD'::text,
    "stripe_payment_intent_id" text,
    "stripe_charge_id" text,
    "status" text not null default 'pending'::text,
    "metadata" jsonb default '{}'::jsonb,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."payments" enable row level security;

alter table "public"."bookings" add column "commission_amount" numeric(10,2) default 0;

alter table "public"."bookings" add column "commission_rate" numeric(5,4) default 0.18;

alter table "public"."bookings" add column "deposit_paid" boolean default false;

alter table "public"."bookings" add column "deposit_paid_at" timestamp with time zone;

alter table "public"."bookings" add column "deposit_percentage" numeric default 0.30;

alter table "public"."bookings" add column "deposit_stripe_payment_intent_id" text;

alter table "public"."bookings" add column "payment_type" text default 'deposit'::text;

alter table "public"."bookings" add column "remaining_paid" boolean default false;

alter table "public"."bookings" add column "remaining_paid_at" timestamp with time zone;

alter table "public"."bookings" add column "remaining_stripe_payment_intent_id" text;

alter table "public"."bookings" add column "service_fee" numeric(10,2) default 2.50;

alter table "public"."bookings" alter column "remaining_amount" drop not null;

alter table "public"."bookings" alter column "remaining_amount" set data type numeric using "remaining_amount"::numeric;

alter table "public"."events" add column "commission_rate" numeric(5,4) default 0.12;

alter table "public"."notifications" drop column "idempotency_key";

alter table "public"."pro_categories" add column "gradient_end" text not null default '#A78BFA'::text;

alter table "public"."pro_categories" add column "gradient_start" text not null default '#6C63FF'::text;

alter table "public"."pro_categories" alter column "created_at" drop not null;

alter table "public"."pro_categories" alter column "emoji" drop default;

alter table "public"."pro_categories" alter column "group_name" drop default;

alter table "public"."pro_categories" alter column "id" set default gen_random_uuid();

alter table "public"."pro_categories" alter column "id" drop identity;

alter table "public"."pro_categories" alter column "id" set data type uuid using "id"::uuid;

alter table "public"."pro_categories" alter column "is_active" drop not null;

alter table "public"."pro_categories" alter column "sort_order" drop not null;

alter table "public"."profiles_pro" add column "deposit_enabled" boolean default true;

alter table "public"."profiles_pro" add column "deposit_percentage" numeric(5,2) default 30.00;

alter table "public"."profiles_pro" add column "min_deposit_amount" numeric(10,2) default 10.00;

alter table "public"."tickets" add column "attendee_email" text;

alter table "public"."tickets" add column "attendee_name" text;

alter table "public"."tickets" add column "email_sent" boolean default false;

alter table "public"."tickets" add column "email_sent_at" timestamp with time zone;

alter table "public"."tickets" add column "qr_code" text;

alter table "public"."tickets" add column "qr_secret" text;

alter table "public"."tickets" add column "scanned_by" uuid;

alter table "public"."tickets" add column "ticket_number" text;

alter table "public"."tickets" alter column "status" drop not null;

alter table "public"."videos" add column "cloudflare_playback_url" text;

alter table "public"."videos" add column "cloudflare_thumbnail_url" text;

alter table "public"."videos" add column "file_size_bytes" bigint;

alter table "public"."videos" add column "has_audio" boolean default true;

alter table "public"."videos" add column "upload_status" text default 'pending'::text;

alter table "public"."videos" alter column "status" set default 'approved'::text;

alter table "public"."videos" alter column "visibility" set default 'public'::text;

drop extension if exists "pg_net";

drop extension if exists "postgis";

CREATE UNIQUE INDEX app_config_pkey ON public.app_config USING btree (key);

CREATE UNIQUE INDEX catering_deposits_pkey ON public.catering_deposits USING btree (id);

CREATE UNIQUE INDEX catering_forfaits_pkey ON public.catering_forfaits USING btree (id);

CREATE UNIQUE INDEX catering_gallery_pkey ON public.catering_gallery USING btree (id);

CREATE UNIQUE INDEX catering_menu_items_pkey ON public.catering_menu_items USING btree (id);

CREATE UNIQUE INDEX catering_submissions_pkey ON public.catering_submissions USING btree (id);

CREATE UNIQUE INDEX event_tickets_pkey1 ON public.event_tickets USING btree (id);

CREATE UNIQUE INDEX event_tickets_ticket_number_key ON public.event_tickets USING btree (ticket_number);

CREATE INDEX idx_catering_deposits_submission ON public.catering_deposits USING btree (submission_id);

CREATE INDEX idx_catering_forfaits_pro ON public.catering_forfaits USING btree (pro_id) WHERE (is_active = true);

CREATE INDEX idx_catering_gallery_pro ON public.catering_gallery USING btree (pro_id);

CREATE INDEX idx_catering_menu_pro ON public.catering_menu_items USING btree (pro_id) WHERE (is_active = true);

CREATE INDEX idx_catering_submissions_client ON public.catering_submissions USING btree (client_id, status);

CREATE INDEX idx_catering_submissions_pro ON public.catering_submissions USING btree (pro_id, status);

CREATE INDEX idx_event_tickets_client ON public.event_tickets USING btree (client_id);

CREATE INDEX idx_event_tickets_event ON public.event_tickets USING btree (event_id);

CREATE INDEX idx_event_tickets_qr ON public.event_tickets USING btree (id, qr_code_token);

CREATE INDEX idx_pro_categories_group ON public.pro_categories USING btree (group_name, sort_order) WHERE (is_active = true);

CREATE INDEX idx_videos_feed ON public.videos USING btree (visibility, status, created_at DESC) WHERE ((visibility = 'public'::text) AND (status = 'approved'::text));

CREATE INDEX idx_videos_pro ON public.videos USING btree (pro_id, created_at DESC);

CREATE UNIQUE INDEX payments_pkey ON public.payments USING btree (id);

CREATE UNIQUE INDEX tickets_qr_code_key ON public.tickets USING btree (qr_code);

alter table "public"."app_config" add constraint "app_config_pkey" PRIMARY KEY using index "app_config_pkey";

alter table "public"."catering_deposits" add constraint "catering_deposits_pkey" PRIMARY KEY using index "catering_deposits_pkey";

alter table "public"."catering_forfaits" add constraint "catering_forfaits_pkey" PRIMARY KEY using index "catering_forfaits_pkey";

alter table "public"."catering_gallery" add constraint "catering_gallery_pkey" PRIMARY KEY using index "catering_gallery_pkey";

alter table "public"."catering_menu_items" add constraint "catering_menu_items_pkey" PRIMARY KEY using index "catering_menu_items_pkey";

alter table "public"."catering_submissions" add constraint "catering_submissions_pkey" PRIMARY KEY using index "catering_submissions_pkey";

alter table "public"."event_tickets" add constraint "event_tickets_pkey1" PRIMARY KEY using index "event_tickets_pkey1";

alter table "public"."payments" add constraint "payments_pkey" PRIMARY KEY using index "payments_pkey";

alter table "public"."catering_deposits" add constraint "catering_deposits_status_check" CHECK ((status = ANY (ARRAY['pending'::text, 'paid'::text, 'refunded'::text, 'failed'::text]))) not valid;

alter table "public"."catering_deposits" validate constraint "catering_deposits_status_check";

alter table "public"."catering_deposits" add constraint "catering_deposits_submission_id_fkey" FOREIGN KEY (submission_id) REFERENCES public.catering_submissions(id) ON DELETE CASCADE not valid;

alter table "public"."catering_deposits" validate constraint "catering_deposits_submission_id_fkey";

alter table "public"."catering_forfaits" add constraint "catering_forfaits_pro_id_fkey" FOREIGN KEY (pro_id) REFERENCES public.profiles_pro(id) ON DELETE CASCADE not valid;

alter table "public"."catering_forfaits" validate constraint "catering_forfaits_pro_id_fkey";

alter table "public"."catering_gallery" add constraint "catering_gallery_pro_id_fkey" FOREIGN KEY (pro_id) REFERENCES public.profiles_pro(id) ON DELETE CASCADE not valid;

alter table "public"."catering_gallery" validate constraint "catering_gallery_pro_id_fkey";

alter table "public"."catering_menu_items" add constraint "catering_menu_items_pro_id_fkey" FOREIGN KEY (pro_id) REFERENCES public.profiles_pro(id) ON DELETE CASCADE not valid;

alter table "public"."catering_menu_items" validate constraint "catering_menu_items_pro_id_fkey";

alter table "public"."catering_submissions" add constraint "catering_submissions_client_id_fkey" FOREIGN KEY (client_id) REFERENCES public.users(id) ON DELETE CASCADE not valid;

alter table "public"."catering_submissions" validate constraint "catering_submissions_client_id_fkey";

alter table "public"."catering_submissions" add constraint "catering_submissions_forfait_id_fkey" FOREIGN KEY (forfait_id) REFERENCES public.catering_forfaits(id) not valid;

alter table "public"."catering_submissions" validate constraint "catering_submissions_forfait_id_fkey";

alter table "public"."catering_submissions" add constraint "catering_submissions_pro_id_fkey" FOREIGN KEY (pro_id) REFERENCES public.profiles_pro(id) ON DELETE CASCADE not valid;

alter table "public"."catering_submissions" validate constraint "catering_submissions_pro_id_fkey";

alter table "public"."catering_submissions" add constraint "catering_submissions_status_check" CHECK ((status = ANY (ARRAY['pending'::text, 'quoted'::text, 'accepted'::text, 'deposit_paid'::text, 'completed'::text, 'cancelled'::text]))) not valid;

alter table "public"."catering_submissions" validate constraint "catering_submissions_status_check";

alter table "public"."event_tickets" add constraint "event_tickets_client_id_fkey" FOREIGN KEY (client_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."event_tickets" validate constraint "event_tickets_client_id_fkey";

alter table "public"."event_tickets" add constraint "event_tickets_event_id_fkey1" FOREIGN KEY (event_id) REFERENCES public.events(id) ON DELETE CASCADE not valid;

alter table "public"."event_tickets" validate constraint "event_tickets_event_id_fkey1";

alter table "public"."event_tickets" add constraint "event_tickets_pro_id_fkey" FOREIGN KEY (pro_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."event_tickets" validate constraint "event_tickets_pro_id_fkey";

alter table "public"."event_tickets" add constraint "event_tickets_ticket_number_key" UNIQUE using index "event_tickets_ticket_number_key";

alter table "public"."event_tickets" add constraint "event_tickets_ticket_type_id_fkey" FOREIGN KEY (ticket_type_id) REFERENCES public.ticket_types(id) ON DELETE CASCADE not valid;

alter table "public"."event_tickets" validate constraint "event_tickets_ticket_type_id_fkey";

alter table "public"."event_tickets" add constraint "event_tickets_validated_by_fkey" FOREIGN KEY (validated_by) REFERENCES auth.users(id) not valid;

alter table "public"."event_tickets" validate constraint "event_tickets_validated_by_fkey";

alter table "public"."payments" add constraint "payments_booking_id_fkey" FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE CASCADE not valid;

alter table "public"."payments" validate constraint "payments_booking_id_fkey";

alter table "public"."payments" add constraint "payments_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL not valid;

alter table "public"."payments" validate constraint "payments_user_id_fkey";

alter table "public"."profiles_pro" add constraint "profiles_pro_deposit_percentage_check" CHECK (((deposit_percentage >= (10)::numeric) AND (deposit_percentage <= (30)::numeric))) not valid;

alter table "public"."profiles_pro" validate constraint "profiles_pro_deposit_percentage_check";

alter table "public"."tickets" add constraint "tickets_qr_code_key" UNIQUE using index "tickets_qr_code_key";

alter table "public"."tickets" add constraint "tickets_scanned_by_fkey" FOREIGN KEY (scanned_by) REFERENCES auth.users(id) not valid;

alter table "public"."tickets" validate constraint "tickets_scanned_by_fkey";

alter table "public"."audit_logs" add constraint "audit_logs_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL not valid;

alter table "public"."audit_logs" validate constraint "audit_logs_user_id_fkey";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.calculate_booking_payment(p_total_price numeric, p_deposit_pct numeric DEFAULT 0.30, p_service_fee numeric DEFAULT 2.50, p_commission_rate numeric DEFAULT 0.18)
 RETURNS TABLE(deposit_amount numeric, remaining_amount numeric, commission_amount numeric, service_fee numeric, client_total_now numeric, client_total_day_of numeric, pro_receives numeric)
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_deposit NUMERIC;
  v_remaining NUMERIC;
  v_commission NUMERIC;
BEGIN
  -- Calculate deposit (30% of total price, minimum $10)
  v_deposit := GREATEST(ROUND(p_total_price * p_deposit_pct, 2), 10.00);
  
  -- Remaining = total - deposit
  v_remaining := p_total_price - v_deposit;
  
  -- Commission on total price
  v_commission := ROUND(p_total_price * p_commission_rate, 2);
  
  RETURN QUERY SELECT
    v_deposit,                              -- deposit_amount
    v_remaining,                            -- remaining_amount
    v_commission,                           -- commission_amount
    p_service_fee,                          -- service_fee
    v_deposit + p_service_fee,              -- client pays NOW (deposit + service fee)
    v_remaining,                            -- client pays DAY OF (remaining)
    p_total_price - v_commission;           -- pro receives (total - commission)
END;
$function$
;

CREATE OR REPLACE FUNCTION public.generate_ticket_number()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_seq INTEGER;
BEGIN
  -- Get next sequence number
  SELECT COALESCE(MAX(CAST(SUBSTRING(ticket_number FROM 'SPB-EVT-(\d+)-') AS INTEGER)), 0) + 1 
  INTO v_seq FROM event_tickets;
  
  -- Format: SPB-EVT-0001-A3F2
  NEW.ticket_number := 'SPB-EVT-' || LPAD(v_seq::TEXT, 4, '0') || '-' || UPPER(SUBSTRING(NEW.qr_code_token::TEXT FROM 1 FOR 4));
  
  -- Generate QR data
  NEW.qr_code_data := jsonb_build_object(
    'ticket_id', NEW.id,
    'token', NEW.qr_code_token,
    'event_id', NEW.event_id,
    'ticket_number', NEW.ticket_number,
    'type', 'spotbook_event_ticket',
    'version', 1
  )::TEXT;
  
  -- Calculate commission
  NEW.commission_amount := ROUND(NEW.total_price * NEW.commission_rate, 2);
  
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.generate_ticket_qr()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_ticket_number TEXT;
  v_qr_code TEXT;
  v_qr_secret TEXT;
BEGIN
  -- Generate ticket number: SPB-YYYYMMDD-XXXXX
  v_ticket_number := 'SPB-' || to_char(NOW(), 'YYYYMMDD') || '-' || upper(substr(md5(random()::text), 1, 5));
  
  -- Generate unique QR code: ticket_id + secret hash
  v_qr_secret := encode(gen_random_bytes(16), 'hex');
  v_qr_code := NEW.id::text || ':' || v_qr_secret;
  
  NEW.ticket_number := v_ticket_number;
  NEW.qr_code := v_qr_code;
  NEW.qr_secret := v_qr_secret;
  NEW.qr_hash := encode(sha256(v_qr_code::bytea), 'hex');
  
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
  INSERT INTO public.users (id, email, full_name, display_name, avatar_url, role, created_at, updated_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', ''),
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'avatar_url', NEW.raw_user_meta_data->>'picture', ''),
    'client',
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    full_name = COALESCE(NULLIF(EXCLUDED.full_name, ''), public.users.full_name),
    avatar_url = COALESCE(NULLIF(EXCLUDED.avatar_url, ''), public.users.avatar_url),
    updated_at = NOW();
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_event_tickets_sold()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.payment_status = 'succeeded' THEN
    UPDATE events SET tickets_sold = tickets_sold + NEW.quantity WHERE id = NEW.event_id;
    UPDATE ticket_types SET sold_count = sold_count + NEW.quantity WHERE id = NEW.ticket_type_id;
  END IF;
  
  IF TG_OP = 'UPDATE' AND OLD.payment_status != 'succeeded' AND NEW.payment_status = 'succeeded' THEN
    UPDATE events SET tickets_sold = tickets_sold + NEW.quantity WHERE id = NEW.event_id;
    UPDATE ticket_types SET sold_count = sold_count + NEW.quantity WHERE id = NEW.ticket_type_id;
  END IF;
  
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.validate_event_ticket(p_ticket_id uuid, p_qr_token uuid, p_pro_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_ticket event_tickets%ROWTYPE;
  v_event events%ROWTYPE;
BEGIN
  -- Find ticket
  SELECT * INTO v_ticket FROM event_tickets 
  WHERE id = p_ticket_id AND qr_code_token = p_qr_token;
  
  IF v_ticket IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invalid ticket or QR code');
  END IF;
  
  -- Check if Pro owns the event
  IF v_ticket.pro_id != p_pro_id THEN
    RETURN jsonb_build_object('success', false, 'error', 'You are not the organizer of this event');
  END IF;
  
  -- Check payment
  IF v_ticket.payment_status != 'succeeded' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Ticket payment not confirmed');
  END IF;
  
  -- Check if already validated
  IF v_ticket.is_validated THEN
    RETURN jsonb_build_object(
      'success', false, 
      'error', 'Ticket already used',
      'validated_at', v_ticket.validated_at
    );
  END IF;
  
  -- Check if cancelled/expired
  IF v_ticket.status != 'active' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Ticket is ' || v_ticket.status);
  END IF;
  
  -- Get event info
  SELECT * INTO v_event FROM events WHERE id = v_ticket.event_id;
  
  -- Check event date (allow validation on event day and day before)
  IF v_event.event_date < CURRENT_DATE - INTERVAL '1 day' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Event has already passed');
  END IF;
  
  -- VALIDATE the ticket
  UPDATE event_tickets SET
    is_validated = true,
    validated_at = NOW(),
    validated_by = p_pro_id,
    status = 'used',
    updated_at = NOW()
  WHERE id = p_ticket_id;
  
  RETURN jsonb_build_object(
    'success', true,
    'ticket_number', v_ticket.ticket_number,
    'event_title', v_event.title,
    'event_date', v_event.event_date,
    'quantity', v_ticket.quantity,
    'ticket_type', (SELECT name FROM ticket_types WHERE id = v_ticket.ticket_type_id),
    'validated_at', NOW()
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.validate_ticket_qr(p_qr_code text, p_scanned_by uuid)
 RETURNS TABLE(valid boolean, ticket_id uuid, ticket_number text, event_name text, event_date date, attendee text, ticket_type text, already_scanned boolean, message text)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_ticket RECORD;
  v_event RECORD;
  v_ticket_type RECORD;
  v_parts TEXT[];
BEGIN
  -- Parse QR code (format: ticket_id:secret)
  v_parts := string_to_array(p_qr_code, ':');
  
  IF array_length(v_parts, 1) != 2 THEN
    RETURN QUERY SELECT false, NULL::UUID, NULL::TEXT, NULL::TEXT, NULL::DATE, NULL::TEXT, NULL::TEXT, false, 'Invalid QR code format'::TEXT;
    RETURN;
  END IF;
  
  -- Find the ticket
  SELECT t.* INTO v_ticket
  FROM tickets t
  WHERE t.id = v_parts[1]::UUID
    AND t.qr_secret = v_parts[2];
  
  IF v_ticket IS NULL THEN
    RETURN QUERY SELECT false, NULL::UUID, NULL::TEXT, NULL::TEXT, NULL::DATE, NULL::TEXT, NULL::TEXT, false, 'Ticket not found or invalid'::TEXT;
    RETURN;
  END IF;
  
  -- Check if already scanned
  IF v_ticket.qr_scanned THEN
    -- Get event info
    SELECT * INTO v_event FROM events WHERE id = v_ticket.event_id;
    RETURN QUERY SELECT false, v_ticket.id, v_ticket.ticket_number, 
      COALESCE(v_event.title, 'Unknown'), v_event.date,
      COALESCE(v_ticket.attendee_name, 'Unknown'),
      'Already used', true, 
      ('Ticket already scanned at ' || to_char(v_ticket.scanned_at, 'HH24:MI on DD/MM/YYYY'))::TEXT;
    RETURN;
  END IF;
  
  -- Check payment status
  IF v_ticket.payment_status != 'paid' AND v_ticket.payment_status != 'succeeded' THEN
    RETURN QUERY SELECT false, v_ticket.id, v_ticket.ticket_number, NULL::TEXT, NULL::DATE, NULL::TEXT, NULL::TEXT, false, 'Ticket not paid'::TEXT;
    RETURN;
  END IF;
  
  -- Check ticket status
  IF v_ticket.status != 'valid' THEN
    RETURN QUERY SELECT false, v_ticket.id, v_ticket.ticket_number, NULL::TEXT, NULL::DATE, NULL::TEXT, NULL::TEXT, false, ('Ticket status: ' || v_ticket.status)::TEXT;
    RETURN;
  END IF;
  
  -- VALID — Mark as scanned
  UPDATE tickets SET 
    qr_scanned = true, 
    scanned_at = NOW(), 
    scanned_by = p_scanned_by,
    status = 'used'
  WHERE id = v_ticket.id;
  
  -- Get event info
  SELECT * INTO v_event FROM events WHERE id = v_ticket.event_id;
  SELECT * INTO v_ticket_type FROM ticket_types WHERE id = v_ticket.ticket_type_id;
  
  RETURN QUERY SELECT true, v_ticket.id, v_ticket.ticket_number,
    COALESCE(v_event.title, 'Unknown'), v_event.date,
    COALESCE(v_ticket.attendee_name, 'Guest'),
    COALESCE(v_ticket_type.name, 'Standard'),
    false,
    'Ticket validated successfully!'::TEXT;
  RETURN;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_booking_atomic(p_client_id uuid, p_slot_id uuid, p_service_id uuid, p_promo_code_id uuid DEFAULT NULL::uuid, p_booking_code text DEFAULT 'SPT-00000000'::text)
 RETURNS json
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_slot time_slots%ROWTYPE;
    v_service services%ROWTYPE;
    v_discount DECIMAL DEFAULT 0;
    v_total DECIMAL;
    v_deposit DECIMAL;
    v_remaining DECIMAL;
    v_payment_mode TEXT;
    v_booking_id UUID;
BEGIN
    SELECT * INTO v_slot
    FROM time_slots
    WHERE id = p_slot_id
    FOR UPDATE NOWAIT;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'slot_unavailable';
    END IF;

    IF NOT v_slot.is_available THEN
        RAISE EXCEPTION 'slot_unavailable';
    END IF;

    SELECT * INTO v_service FROM services WHERE id = p_service_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'service_not_found';
    END IF;

    IF p_promo_code_id IS NOT NULL THEN
        SELECT COALESCE(
            CASE discount_type
                WHEN 'percentage' THEN v_service.price * discount_value / 100
                WHEN 'fixed' THEN discount_value
                ELSE 0
            END, 0
        ) INTO v_discount
        FROM promo_codes
        WHERE id = p_promo_code_id
          AND is_active = true
          AND (expires_at IS NULL OR expires_at > NOW())
          AND (max_uses IS NULL OR uses_count < max_uses);

        IF FOUND AND p_promo_code_id IS NOT NULL THEN
            UPDATE promo_codes SET uses_count = uses_count + 1 WHERE id = p_promo_code_id;
        END IF;
    END IF;

    v_total := GREATEST(v_service.price - v_discount, 0);
    v_payment_mode := COALESCE(v_service.payment_mode, 'full');

    IF v_payment_mode = 'full' THEN
        v_deposit := v_total;
        v_remaining := 0;
    ELSIF v_service.deposit_type = 'percentage' THEN
        v_deposit := ROUND(v_total * COALESCE(v_service.deposit_value, 30) / 100, 2);
        v_remaining := v_total - v_deposit;
    ELSIF v_service.deposit_type = 'fixed' THEN
        v_deposit := LEAST(COALESCE(v_service.deposit_value, v_total), v_total);
        v_remaining := v_total - v_deposit;
    ELSE
        v_deposit := ROUND(v_total * COALESCE(v_service.deposit_percentage, 0.30), 2);
        v_remaining := v_total - v_deposit;
        v_payment_mode := 'deposit';
    END IF;

    UPDATE time_slots
    SET is_available = false, locked_by = p_client_id
    WHERE id = p_slot_id;

    INSERT INTO bookings (
        client_id, pro_id, service_id, time_slot_id,
        status, total_amount, deposit_amount, remaining_amount,
        payment_mode, remaining_payment_status,
        currency, booking_code, promo_code_id
    ) VALUES (
        p_client_id, v_slot.pro_id, p_service_id, p_slot_id,
        'pending_payment', v_total, v_deposit, v_remaining,
        v_payment_mode, 'pending',
        'CAD', p_booking_code, p_promo_code_id
    )
    RETURNING id INTO v_booking_id;

    RETURN json_build_object(
        'booking_id', v_booking_id,
        'booking_code', p_booking_code,
        'total_amount', v_total,
        'deposit_amount', v_deposit,
        'remaining_amount', v_remaining,
        'payment_mode', v_payment_mode
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.rate_limit_consume(p_scope text, p_rate_key text, p_bucket bigint, p_max integer, p_window_ms bigint)
 RETURNS TABLE(allowed boolean, retry_in_minutes integer, remaining integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_now_ms bigint := (extract(epoch from clock_timestamp()) * 1000)::bigint;
    v_count int;
      v_expires timestamptz := to_timestamp(((p_bucket + 1) * p_window_ms) / 1000.0);
        v_mod bigint;
          v_retry numeric;
          BEGIN
            -- Validate scope is not empty
              IF p_scope IS NULL OR p_scope = '' THEN
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
                                                  WHERE c.scope = p_scope AND c.rate_key = p_rate_key AND c.bucket = p_bucket;

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
                                                                                                                  WHERE scope = p_scope AND rate_key = p_rate_key AND bucket = p_bucket;

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
                                                                                                                                                    $function$
;

grant delete on table "public"."app_config" to "anon";

grant insert on table "public"."app_config" to "anon";

grant references on table "public"."app_config" to "anon";

grant select on table "public"."app_config" to "anon";

grant trigger on table "public"."app_config" to "anon";

grant truncate on table "public"."app_config" to "anon";

grant update on table "public"."app_config" to "anon";

grant delete on table "public"."app_config" to "authenticated";

grant insert on table "public"."app_config" to "authenticated";

grant references on table "public"."app_config" to "authenticated";

grant select on table "public"."app_config" to "authenticated";

grant trigger on table "public"."app_config" to "authenticated";

grant truncate on table "public"."app_config" to "authenticated";

grant update on table "public"."app_config" to "authenticated";

grant delete on table "public"."app_config" to "service_role";

grant insert on table "public"."app_config" to "service_role";

grant references on table "public"."app_config" to "service_role";

grant select on table "public"."app_config" to "service_role";

grant trigger on table "public"."app_config" to "service_role";

grant truncate on table "public"."app_config" to "service_role";

grant update on table "public"."app_config" to "service_role";

grant delete on table "public"."audit_logs" to "anon";

grant insert on table "public"."audit_logs" to "anon";

grant references on table "public"."audit_logs" to "anon";

grant select on table "public"."audit_logs" to "anon";

grant trigger on table "public"."audit_logs" to "anon";

grant truncate on table "public"."audit_logs" to "anon";

grant update on table "public"."audit_logs" to "anon";

grant delete on table "public"."blocks" to "anon";

grant insert on table "public"."blocks" to "anon";

grant references on table "public"."blocks" to "anon";

grant select on table "public"."blocks" to "anon";

grant trigger on table "public"."blocks" to "anon";

grant truncate on table "public"."blocks" to "anon";

grant update on table "public"."blocks" to "anon";

grant delete on table "public"."bookings" to "anon";

grant insert on table "public"."bookings" to "anon";

grant references on table "public"."bookings" to "anon";

grant select on table "public"."bookings" to "anon";

grant trigger on table "public"."bookings" to "anon";

grant truncate on table "public"."bookings" to "anon";

grant update on table "public"."bookings" to "anon";

grant delete on table "public"."catering_deposits" to "anon";

grant insert on table "public"."catering_deposits" to "anon";

grant references on table "public"."catering_deposits" to "anon";

grant select on table "public"."catering_deposits" to "anon";

grant trigger on table "public"."catering_deposits" to "anon";

grant truncate on table "public"."catering_deposits" to "anon";

grant update on table "public"."catering_deposits" to "anon";

grant delete on table "public"."catering_deposits" to "authenticated";

grant insert on table "public"."catering_deposits" to "authenticated";

grant references on table "public"."catering_deposits" to "authenticated";

grant select on table "public"."catering_deposits" to "authenticated";

grant trigger on table "public"."catering_deposits" to "authenticated";

grant truncate on table "public"."catering_deposits" to "authenticated";

grant update on table "public"."catering_deposits" to "authenticated";

grant delete on table "public"."catering_deposits" to "service_role";

grant insert on table "public"."catering_deposits" to "service_role";

grant references on table "public"."catering_deposits" to "service_role";

grant select on table "public"."catering_deposits" to "service_role";

grant trigger on table "public"."catering_deposits" to "service_role";

grant truncate on table "public"."catering_deposits" to "service_role";

grant update on table "public"."catering_deposits" to "service_role";

grant delete on table "public"."catering_forfaits" to "anon";

grant insert on table "public"."catering_forfaits" to "anon";

grant references on table "public"."catering_forfaits" to "anon";

grant select on table "public"."catering_forfaits" to "anon";

grant trigger on table "public"."catering_forfaits" to "anon";

grant truncate on table "public"."catering_forfaits" to "anon";

grant update on table "public"."catering_forfaits" to "anon";

grant delete on table "public"."catering_forfaits" to "authenticated";

grant insert on table "public"."catering_forfaits" to "authenticated";

grant references on table "public"."catering_forfaits" to "authenticated";

grant select on table "public"."catering_forfaits" to "authenticated";

grant trigger on table "public"."catering_forfaits" to "authenticated";

grant truncate on table "public"."catering_forfaits" to "authenticated";

grant update on table "public"."catering_forfaits" to "authenticated";

grant delete on table "public"."catering_forfaits" to "service_role";

grant insert on table "public"."catering_forfaits" to "service_role";

grant references on table "public"."catering_forfaits" to "service_role";

grant select on table "public"."catering_forfaits" to "service_role";

grant trigger on table "public"."catering_forfaits" to "service_role";

grant truncate on table "public"."catering_forfaits" to "service_role";

grant update on table "public"."catering_forfaits" to "service_role";

grant delete on table "public"."catering_gallery" to "anon";

grant insert on table "public"."catering_gallery" to "anon";

grant references on table "public"."catering_gallery" to "anon";

grant select on table "public"."catering_gallery" to "anon";

grant trigger on table "public"."catering_gallery" to "anon";

grant truncate on table "public"."catering_gallery" to "anon";

grant update on table "public"."catering_gallery" to "anon";

grant delete on table "public"."catering_gallery" to "authenticated";

grant insert on table "public"."catering_gallery" to "authenticated";

grant references on table "public"."catering_gallery" to "authenticated";

grant select on table "public"."catering_gallery" to "authenticated";

grant trigger on table "public"."catering_gallery" to "authenticated";

grant truncate on table "public"."catering_gallery" to "authenticated";

grant update on table "public"."catering_gallery" to "authenticated";

grant delete on table "public"."catering_gallery" to "service_role";

grant insert on table "public"."catering_gallery" to "service_role";

grant references on table "public"."catering_gallery" to "service_role";

grant select on table "public"."catering_gallery" to "service_role";

grant trigger on table "public"."catering_gallery" to "service_role";

grant truncate on table "public"."catering_gallery" to "service_role";

grant update on table "public"."catering_gallery" to "service_role";

grant delete on table "public"."catering_menu_items" to "anon";

grant insert on table "public"."catering_menu_items" to "anon";

grant references on table "public"."catering_menu_items" to "anon";

grant select on table "public"."catering_menu_items" to "anon";

grant trigger on table "public"."catering_menu_items" to "anon";

grant truncate on table "public"."catering_menu_items" to "anon";

grant update on table "public"."catering_menu_items" to "anon";

grant delete on table "public"."catering_menu_items" to "authenticated";

grant insert on table "public"."catering_menu_items" to "authenticated";

grant references on table "public"."catering_menu_items" to "authenticated";

grant select on table "public"."catering_menu_items" to "authenticated";

grant trigger on table "public"."catering_menu_items" to "authenticated";

grant truncate on table "public"."catering_menu_items" to "authenticated";

grant update on table "public"."catering_menu_items" to "authenticated";

grant delete on table "public"."catering_menu_items" to "service_role";

grant insert on table "public"."catering_menu_items" to "service_role";

grant references on table "public"."catering_menu_items" to "service_role";

grant select on table "public"."catering_menu_items" to "service_role";

grant trigger on table "public"."catering_menu_items" to "service_role";

grant truncate on table "public"."catering_menu_items" to "service_role";

grant update on table "public"."catering_menu_items" to "service_role";

grant delete on table "public"."catering_submissions" to "anon";

grant insert on table "public"."catering_submissions" to "anon";

grant references on table "public"."catering_submissions" to "anon";

grant select on table "public"."catering_submissions" to "anon";

grant trigger on table "public"."catering_submissions" to "anon";

grant truncate on table "public"."catering_submissions" to "anon";

grant update on table "public"."catering_submissions" to "anon";

grant delete on table "public"."catering_submissions" to "authenticated";

grant insert on table "public"."catering_submissions" to "authenticated";

grant references on table "public"."catering_submissions" to "authenticated";

grant select on table "public"."catering_submissions" to "authenticated";

grant trigger on table "public"."catering_submissions" to "authenticated";

grant truncate on table "public"."catering_submissions" to "authenticated";

grant update on table "public"."catering_submissions" to "authenticated";

grant delete on table "public"."catering_submissions" to "service_role";

grant insert on table "public"."catering_submissions" to "service_role";

grant references on table "public"."catering_submissions" to "service_role";

grant select on table "public"."catering_submissions" to "service_role";

grant trigger on table "public"."catering_submissions" to "service_role";

grant truncate on table "public"."catering_submissions" to "service_role";

grant update on table "public"."catering_submissions" to "service_role";

grant delete on table "public"."conversations" to "anon";

grant insert on table "public"."conversations" to "anon";

grant references on table "public"."conversations" to "anon";

grant select on table "public"."conversations" to "anon";

grant trigger on table "public"."conversations" to "anon";

grant truncate on table "public"."conversations" to "anon";

grant update on table "public"."conversations" to "anon";

grant delete on table "public"."event_tickets" to "anon";

grant insert on table "public"."event_tickets" to "anon";

grant references on table "public"."event_tickets" to "anon";

grant select on table "public"."event_tickets" to "anon";

grant trigger on table "public"."event_tickets" to "anon";

grant truncate on table "public"."event_tickets" to "anon";

grant update on table "public"."event_tickets" to "anon";

grant delete on table "public"."event_tickets" to "authenticated";

grant insert on table "public"."event_tickets" to "authenticated";

grant references on table "public"."event_tickets" to "authenticated";

grant select on table "public"."event_tickets" to "authenticated";

grant trigger on table "public"."event_tickets" to "authenticated";

grant truncate on table "public"."event_tickets" to "authenticated";

grant update on table "public"."event_tickets" to "authenticated";

grant delete on table "public"."event_tickets" to "service_role";

grant insert on table "public"."event_tickets" to "service_role";

grant references on table "public"."event_tickets" to "service_role";

grant select on table "public"."event_tickets" to "service_role";

grant trigger on table "public"."event_tickets" to "service_role";

grant truncate on table "public"."event_tickets" to "service_role";

grant update on table "public"."event_tickets" to "service_role";

grant delete on table "public"."favorites" to "anon";

grant insert on table "public"."favorites" to "anon";

grant references on table "public"."favorites" to "anon";

grant select on table "public"."favorites" to "anon";

grant trigger on table "public"."favorites" to "anon";

grant truncate on table "public"."favorites" to "anon";

grant update on table "public"."favorites" to "anon";

grant delete on table "public"."messages" to "anon";

grant insert on table "public"."messages" to "anon";

grant references on table "public"."messages" to "anon";

grant select on table "public"."messages" to "anon";

grant trigger on table "public"."messages" to "anon";

grant truncate on table "public"."messages" to "anon";

grant update on table "public"."messages" to "anon";

grant delete on table "public"."notification_preferences" to "anon";

grant insert on table "public"."notification_preferences" to "anon";

grant references on table "public"."notification_preferences" to "anon";

grant select on table "public"."notification_preferences" to "anon";

grant trigger on table "public"."notification_preferences" to "anon";

grant truncate on table "public"."notification_preferences" to "anon";

grant update on table "public"."notification_preferences" to "anon";

grant delete on table "public"."notifications" to "anon";

grant insert on table "public"."notifications" to "anon";

grant references on table "public"."notifications" to "anon";

grant select on table "public"."notifications" to "anon";

grant trigger on table "public"."notifications" to "anon";

grant truncate on table "public"."notifications" to "anon";

grant update on table "public"."notifications" to "anon";

grant delete on table "public"."payments" to "anon";

grant insert on table "public"."payments" to "anon";

grant references on table "public"."payments" to "anon";

grant select on table "public"."payments" to "anon";

grant trigger on table "public"."payments" to "anon";

grant truncate on table "public"."payments" to "anon";

grant update on table "public"."payments" to "anon";

grant delete on table "public"."payments" to "authenticated";

grant insert on table "public"."payments" to "authenticated";

grant references on table "public"."payments" to "authenticated";

grant select on table "public"."payments" to "authenticated";

grant trigger on table "public"."payments" to "authenticated";

grant truncate on table "public"."payments" to "authenticated";

grant update on table "public"."payments" to "authenticated";

grant delete on table "public"."payments" to "service_role";

grant insert on table "public"."payments" to "service_role";

grant references on table "public"."payments" to "service_role";

grant select on table "public"."payments" to "service_role";

grant trigger on table "public"."payments" to "service_role";

grant truncate on table "public"."payments" to "service_role";

grant update on table "public"."payments" to "service_role";

grant delete on table "public"."pro_subscriptions" to "anon";

grant insert on table "public"."pro_subscriptions" to "anon";

grant references on table "public"."pro_subscriptions" to "anon";

grant select on table "public"."pro_subscriptions" to "anon";

grant trigger on table "public"."pro_subscriptions" to "anon";

grant truncate on table "public"."pro_subscriptions" to "anon";

grant update on table "public"."pro_subscriptions" to "anon";

grant delete on table "public"."profiles_pro" to "anon";

grant insert on table "public"."profiles_pro" to "anon";

grant references on table "public"."profiles_pro" to "anon";

grant select on table "public"."profiles_pro" to "anon";

grant trigger on table "public"."profiles_pro" to "anon";

grant truncate on table "public"."profiles_pro" to "anon";

grant update on table "public"."profiles_pro" to "anon";

grant delete on table "public"."rate_limit_counters" to "anon";

grant insert on table "public"."rate_limit_counters" to "anon";

grant references on table "public"."rate_limit_counters" to "anon";

grant select on table "public"."rate_limit_counters" to "anon";

grant trigger on table "public"."rate_limit_counters" to "anon";

grant truncate on table "public"."rate_limit_counters" to "anon";

grant update on table "public"."rate_limit_counters" to "anon";

grant delete on table "public"."rate_limit_counters" to "authenticated";

grant insert on table "public"."rate_limit_counters" to "authenticated";

grant references on table "public"."rate_limit_counters" to "authenticated";

grant select on table "public"."rate_limit_counters" to "authenticated";

grant trigger on table "public"."rate_limit_counters" to "authenticated";

grant truncate on table "public"."rate_limit_counters" to "authenticated";

grant update on table "public"."rate_limit_counters" to "authenticated";

grant delete on table "public"."referrals" to "anon";

grant insert on table "public"."referrals" to "anon";

grant references on table "public"."referrals" to "anon";

grant select on table "public"."referrals" to "anon";

grant trigger on table "public"."referrals" to "anon";

grant truncate on table "public"."referrals" to "anon";

grant update on table "public"."referrals" to "anon";

grant delete on table "public"."reports" to "anon";

grant insert on table "public"."reports" to "anon";

grant references on table "public"."reports" to "anon";

grant select on table "public"."reports" to "anon";

grant trigger on table "public"."reports" to "anon";

grant truncate on table "public"."reports" to "anon";

grant update on table "public"."reports" to "anon";

grant delete on table "public"."reviews" to "anon";

grant insert on table "public"."reviews" to "anon";

grant references on table "public"."reviews" to "anon";

grant select on table "public"."reviews" to "anon";

grant trigger on table "public"."reviews" to "anon";

grant truncate on table "public"."reviews" to "anon";

grant update on table "public"."reviews" to "anon";

grant references on table "public"."social_connections" to "authenticated";

grant select on table "public"."social_connections" to "authenticated";

grant trigger on table "public"."social_connections" to "authenticated";

grant truncate on table "public"."social_connections" to "authenticated";

grant select on table "public"."users" to "anon";

grant select on table "public"."users" to "authenticated";


  create policy "Anyone can read config"
  on "public"."app_config"
  as permissive
  for select
  to public
using (true);



  create policy "Only service role can update config"
  on "public"."app_config"
  as permissive
  for all
  to public
using ((auth.role() = 'service_role'::text));



  create policy "Service role inserts audit logs"
  on "public"."audit_logs"
  as permissive
  for insert
  to public
with check ((auth.role() = 'service_role'::text));



  create policy "Users can view own audit logs"
  on "public"."audit_logs"
  as permissive
  for select
  to public
using ((auth.uid() = user_id));



  create policy "Client can view own deposits"
  on "public"."catering_deposits"
  as permissive
  for select
  to public
using ((EXISTS ( SELECT 1
   FROM public.catering_submissions cs
  WHERE ((cs.id = catering_deposits.submission_id) AND (cs.client_id = auth.uid())))));



  create policy "Pro can view deposits for their submissions"
  on "public"."catering_deposits"
  as permissive
  for select
  to public
using ((EXISTS ( SELECT 1
   FROM public.catering_submissions cs
  WHERE ((cs.id = catering_deposits.submission_id) AND (cs.pro_id = auth.uid())))));



  create policy "Anyone can view active forfaits"
  on "public"."catering_forfaits"
  as permissive
  for select
  to public
using ((is_active = true));



  create policy "Pro can manage own forfaits"
  on "public"."catering_forfaits"
  as permissive
  for all
  to public
using ((auth.uid() = pro_id));



  create policy "Anyone can view gallery"
  on "public"."catering_gallery"
  as permissive
  for select
  to public
using (true);



  create policy "Pro can manage own gallery"
  on "public"."catering_gallery"
  as permissive
  for all
  to public
using ((auth.uid() = pro_id));



  create policy "Anyone can view active menu items"
  on "public"."catering_menu_items"
  as permissive
  for select
  to public
using ((is_active = true));



  create policy "Pro can manage own menu items"
  on "public"."catering_menu_items"
  as permissive
  for all
  to public
using ((auth.uid() = pro_id));



  create policy "Client can create submissions"
  on "public"."catering_submissions"
  as permissive
  for insert
  to public
with check ((auth.uid() = client_id));



  create policy "Client can view own submissions"
  on "public"."catering_submissions"
  as permissive
  for select
  to public
using ((auth.uid() = client_id));



  create policy "Pro can update submission status"
  on "public"."catering_submissions"
  as permissive
  for update
  to public
using ((auth.uid() = pro_id));



  create policy "Pro can view submissions sent to them"
  on "public"."catering_submissions"
  as permissive
  for select
  to public
using ((auth.uid() = pro_id));



  create policy "Users can create conversations"
  on "public"."conversations"
  as permissive
  for insert
  to public
with check ((auth.uid() = client_id));



  create policy "Users can update own conversations"
  on "public"."conversations"
  as permissive
  for update
  to public
using (((auth.uid() = client_id) OR (auth.uid() = pro_id)));



  create policy "Users can view own conversations"
  on "public"."conversations"
  as permissive
  for select
  to public
using (((auth.uid() = client_id) OR (auth.uid() = pro_id)));



  create policy "Clients can purchase tickets"
  on "public"."event_tickets"
  as permissive
  for insert
  to public
with check ((auth.uid() = client_id));



  create policy "Clients can view own tickets"
  on "public"."event_tickets"
  as permissive
  for select
  to public
using ((auth.uid() = client_id));



  create policy "Pros can view tickets for own events"
  on "public"."event_tickets"
  as permissive
  for select
  to public
using ((auth.uid() = pro_id));



  create policy "Service can update tickets"
  on "public"."event_tickets"
  as permissive
  for update
  to public
using (true);



  create policy "Events: lecture"
  on "public"."events"
  as permissive
  for select
  to public
using (((is_active = true) OR (auth.uid() = pro_id)));



  create policy "Users can send messages in own conversations"
  on "public"."messages"
  as permissive
  for insert
  to public
with check (((auth.uid() = sender_id) AND (conversation_id IN ( SELECT conversations.id
   FROM public.conversations
  WHERE ((conversations.client_id = auth.uid()) OR (conversations.pro_id = auth.uid()))))));



  create policy "Users can view messages in own conversations"
  on "public"."messages"
  as permissive
  for select
  to public
using ((conversation_id IN ( SELECT conversations.id
   FROM public.conversations
  WHERE ((conversations.client_id = auth.uid()) OR (conversations.pro_id = auth.uid())))));



  create policy "Service can insert notifications"
  on "public"."notifications"
  as permissive
  for insert
  to public
with check (true);



  create policy "Users can update own notifications"
  on "public"."notifications"
  as permissive
  for update
  to public
using ((auth.uid() = user_id));



  create policy "Users can view own notifications"
  on "public"."notifications"
  as permissive
  for select
  to public
using ((auth.uid() = user_id));



  create policy "Users can insert own payments"
  on "public"."payments"
  as permissive
  for insert
  to public
with check ((auth.uid() = user_id));



  create policy "Users can view own payments"
  on "public"."payments"
  as permissive
  for select
  to public
using ((auth.uid() = user_id));



  create policy "Anyone can read categories"
  on "public"."pro_categories"
  as permissive
  for select
  to public
using ((is_active = true));



  create policy "block_commission_update"
  on "public"."profiles_pro"
  as permissive
  for update
  to public
using ((auth.uid() = id))
with check ((commission_rate = ( SELECT profiles_pro_1.commission_rate
   FROM public.profiles_pro profiles_pro_1
  WHERE (profiles_pro_1.id = auth.uid()))));



  create policy "service_role_all"
  on "public"."rate_limit_counters"
  as permissive
  for all
  to service_role
using (true)
with check (true);



  create policy "social_connections_public_read"
  on "public"."social_connections"
  as permissive
  for select
  to public
using (true);



  create policy "Clients insert tickets"
  on "public"."tickets"
  as permissive
  for insert
  to public
with check ((auth.uid() = user_id));



  create policy "Clients view own tickets"
  on "public"."tickets"
  as permissive
  for select
  to public
using (((auth.uid() = user_id) OR (EXISTS ( SELECT 1
   FROM public.events
  WHERE ((events.id = tickets.event_id) AND (events.pro_id = auth.uid()))))));



  create policy "Pros update tickets for their events"
  on "public"."tickets"
  as permissive
  for update
  to public
using ((EXISTS ( SELECT 1
   FROM public.events
  WHERE ((events.id = tickets.event_id) AND (events.pro_id = auth.uid())))));



  create policy "users_public_read"
  on "public"."users"
  as permissive
  for select
  to public
using (true);



  create policy "Anyone can view public videos"
  on "public"."videos"
  as permissive
  for select
  to public
using ((((visibility = 'public'::text) AND (status = 'approved'::text)) OR (pro_id = auth.uid())));



  create policy "Only pros can insert videos"
  on "public"."videos"
  as permissive
  for insert
  to public
with check (((auth.uid() = pro_id) AND (EXISTS ( SELECT 1
   FROM public.profiles_pro
  WHERE (profiles_pro.id = auth.uid())))));



  create policy "Pro can delete own videos"
  on "public"."videos"
  as permissive
  for delete
  to public
using ((auth.uid() = pro_id));



  create policy "Pro can update own videos"
  on "public"."videos"
  as permissive
  for update
  to public
using ((auth.uid() = pro_id));



  create policy "events_public_read"
  on "public"."events"
  as permissive
  for select
  to public
using (true);



  create policy "notifications_service_insert"
  on "public"."notifications"
  as permissive
  for insert
  to public
with check (((auth.role() = 'service_role'::text) OR (auth.uid() IS NOT NULL)));



  create policy "reviews_update_as_client"
  on "public"."reviews"
  as permissive
  for update
  to authenticated
using ((auth.uid() = client_id));



  create policy "time_slots_public_read"
  on "public"."time_slots"
  as permissive
  for select
  to public
using (true);



  create policy "users_own_update"
  on "public"."users"
  as permissive
  for update
  to public
using ((auth.uid() = id));


CREATE TRIGGER trg_generate_ticket_number BEFORE INSERT ON public.event_tickets FOR EACH ROW EXECUTE FUNCTION public.generate_ticket_number();

CREATE TRIGGER trg_update_tickets_sold AFTER INSERT OR UPDATE ON public.event_tickets FOR EACH ROW EXECUTE FUNCTION public.update_event_tickets_sold();

CREATE TRIGGER trg_generate_ticket_qr BEFORE INSERT ON public.tickets FOR EACH ROW EXECUTE FUNCTION public.generate_ticket_qr();

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_auth_user();

drop policy "event_covers_pro_owner_write" on "storage"."objects";

drop policy "event_covers_pro_write" on "storage"."objects";

drop policy "event_covers_pro_delete" on "storage"."objects";

drop policy "event_covers_pro_update" on "storage"."objects";


  create policy "Public read ticket QR codes"
  on "storage"."objects"
  as permissive
  for select
  to public
using ((bucket_id = 'ticket-qr-codes'::text));



  create policy "Service upload ticket QR"
  on "storage"."objects"
  as permissive
  for insert
  to public
with check ((bucket_id = 'ticket-qr-codes'::text));



  create policy "event_covers_pro_insert"
  on "storage"."objects"
  as permissive
  for insert
  to authenticated
with check (((bucket_id = 'event-covers'::text) AND ((auth.uid())::text = (storage.foldername(name))[1]) AND (EXISTS ( SELECT 1
   FROM public.profiles_pro
  WHERE (profiles_pro.id = auth.uid())))));



  create policy "event_covers_pro_delete"
  on "storage"."objects"
  as permissive
  for delete
  to authenticated
using (((bucket_id = 'event-covers'::text) AND ((auth.uid())::text = (storage.foldername(name))[1]) AND (EXISTS ( SELECT 1
   FROM public.profiles_pro
  WHERE (profiles_pro.id = auth.uid())))));



  create policy "event_covers_pro_update"
  on "storage"."objects"
  as permissive
  for update
  to authenticated
using (((bucket_id = 'event-covers'::text) AND ((auth.uid())::text = (storage.foldername(name))[1]) AND (EXISTS ( SELECT 1
   FROM public.profiles_pro
  WHERE (profiles_pro.id = auth.uid())))));



