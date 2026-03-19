CREATE TABLE IF NOT EXISTS public.social_connections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pro_id UUID NOT NULL REFERENCES public.profiles_pro(id) ON DELETE CASCADE,
    platform TEXT NOT NULL CHECK (platform IN ('instagram', 'tiktok', 'youtube')),
    handle TEXT NOT NULL,
    followers_count INTEGER NOT NULL DEFAULT 0,
    access_token TEXT,
    refresh_token TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(pro_id, platform)
);

ALTER TABLE public.social_connections ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Pros can view their own social connections"
    ON public.social_connections FOR SELECT
    USING (auth.uid() = pro_id);

CREATE POLICY "Anyone can view social connections"
    ON public.social_connections FOR SELECT
    USING (true);

CREATE POLICY "Pros can manage their own social connections"
    ON public.social_connections FOR ALL
    USING (auth.uid() = pro_id);

CREATE TABLE IF NOT EXISTS public.follows (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    follower_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    following_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(follower_id, following_id)
);

ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view follows"
    ON public.follows FOR SELECT
    USING (true);

CREATE POLICY "Users can manage their own follows"
    ON public.follows FOR ALL
    USING (auth.uid() = follower_id);
