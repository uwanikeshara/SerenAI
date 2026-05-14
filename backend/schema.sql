-- ============================================================
-- SerenAI — Supabase Schema
-- Run this entire file in the Supabase SQL Editor
-- ============================================================

-- ── Profiles ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.profiles (
  id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username      TEXT,
  avatar_url    TEXT,
  streak_count  INTEGER DEFAULT 0,
  total_points  INTEGER DEFAULT 0,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Auto-create profile on sign-up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, username)
  VALUES (NEW.id, SPLIT_PART(NEW.email, '@', 1));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ── Stress Scans ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.stress_scans (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id              UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  stress_score         FLOAT NOT NULL,
  stress_level         TEXT CHECK (stress_level IN ('low', 'medium', 'high')),
  dominant_emotion     TEXT,
  emotion_probabilities JSONB,
  scanned_at           TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.stress_scans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own scans"
  ON public.stress_scans FOR ALL
  USING (auth.uid() = user_id);

-- ── Audio Tracks ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.audio_tracks (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title            TEXT NOT NULL,
  artist           TEXT DEFAULT 'SerenAI',
  category         TEXT CHECK (category IN ('nature', 'binaural', 'guided', 'breathing')),
  duration_seconds INTEGER,
  stream_url       TEXT NOT NULL,
  thumbnail_url    TEXT,
  description      TEXT,
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

-- Public read — no auth required for audio catalogue
ALTER TABLE public.audio_tracks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public audio catalogue"
  ON public.audio_tracks FOR SELECT TO anon, authenticated
  USING (true);

-- ── Recommendations ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.recommendations (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title            TEXT NOT NULL,
  description      TEXT,
  type             TEXT CHECK (type IN ('breathing', 'audio', 'stretch', 'journal', 'activity')),
  stress_level_tag TEXT CHECK (stress_level_tag IN ('low', 'medium', 'high', 'all')),
  icon_name        TEXT,
  duration_minutes INTEGER,
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.recommendations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public recommendations"
  ON public.recommendations FOR SELECT TO anon, authenticated
  USING (true);

-- ── Journal Entries ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.journal_entries (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  content    TEXT,
  mood_tag   TEXT,
  stress_ref UUID REFERENCES public.stress_scans(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.journal_entries ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own journals"
  ON public.journal_entries FOR ALL
  USING (auth.uid() = user_id);

-- ── Gamification Events ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.gamification_events (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  points     INTEGER DEFAULT 0,
  earned_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.gamification_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own gamification"
  ON public.gamification_events FOR ALL
  USING (auth.uid() = user_id);

-- ── Seed: Audio Tracks (Royalty-Free CDN URLs) ────────────────
INSERT INTO public.audio_tracks (title, artist, category, duration_seconds, stream_url, thumbnail_url, description) VALUES
  ('Forest Morning Rain', 'Nature Sounds', 'nature', 3600,
   'https://upload.wikimedia.org/wikipedia/commons/6/65/Rain-on-leaves-1.ogg',
   'https://images.unsplash.com/photo-1448375240586-882707db888b?w=400',
   'Gentle rain falling in a lush forest. Perfect for deep relaxation.'),
  ('Ocean Waves', 'Nature Sounds', 'nature', 3600,
   'https://upload.wikimedia.org/wikipedia/commons/7/7b/Ocean_waves_hitting_the_beach.ogg',
   'https://images.unsplash.com/photo-1505118380757-91f5f5632de0?w=400',
   'Calming ocean waves on a peaceful beach.'),
  ('Peaceful Stream', 'Nature Sounds', 'nature', 1800,
   'https://upload.wikimedia.org/wikipedia/commons/f/ff/River_flowing_in_the_forest.ogg',
   'https://images.unsplash.com/photo-1586348943529-beaae6c28db9?w=400',
   'A gentle babbling brook flowing through meadows.'),
  ('Alpha Binaural Beats 10Hz', 'SerenAI', 'binaural', 1800,
   'https://upload.wikimedia.org/wikipedia/commons/6/6a/10_Hz_alpha_binaural_beat.ogg',
   'https://images.unsplash.com/photo-1579546929518-9e396f3cc809?w=400',
   '10Hz Alpha frequencies to promote wakeful relaxation.'),
  ('Theta Deep Sleep 4Hz', 'SerenAI', 'binaural', 3600,
   'https://upload.wikimedia.org/wikipedia/commons/a/a2/4_Hz_theta_binaural_beat.ogg',
   'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=400',
   'Deep 4Hz Theta waves for restorative sleep and meditation.'),
  ('Guided Body Scan', 'SerenAI Guides', 'meditation', 900,
   'https://upload.wikimedia.org/wikipedia/commons/7/7d/Tibetan_singing_bowl.ogg',
   'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=400',
   'A 15-minute guided meditation releasing tension from head to toe.')
ON CONFLICT DO NOTHING;

-- ── Seed: Recommendations ─────────────────────────────────────
INSERT INTO public.recommendations (title, description, type, stress_level_tag, icon_name, duration_minutes) VALUES
  ('Box Breathing', 'Inhale 4s, hold 4s, exhale 4s, hold 4s. Repeat 4 times.', 'breathing', 'high', 'air', 5),
  ('Cold Water Splash', 'Splash cold water on your face to activate the dive reflex and calm your nervous system.', 'activity', 'high', 'water_drop', 2),
  ('Progressive Muscle Relax', 'Tense and relax each muscle group from toes to head.', 'stretch', 'high', 'self_improvement', 10),
  ('Write It Out', 'Journal what you are feeling right now without judgment.', 'journal', 'high', 'edit_note', 5),
  ('Nature Soundscape', 'Listen to calming rain or ocean sounds.', 'audio', 'medium', 'headphones', 15),
  ('5-4-3-2-1 Grounding', 'Name 5 things you see, 4 you hear, 3 you feel, 2 you smell, 1 you taste.', 'activity', 'medium', 'psychology', 3),
  ('Neck Stretches', 'Gentle side-to-side neck rolls to release tension.', 'stretch', 'medium', 'accessibility_new', 5),
  ('Gratitude Moment', 'Write 3 things you are grateful for today.', 'journal', 'low', 'favorite', 5),
  ('Celebration Breath', 'Take one long deep breath and exhale slowly, celebrating this moment.', 'breathing', 'low', 'celebration', 1),
  ('Alpha Binaural', 'Listen to 10Hz alpha binaural beats for calm focus.', 'audio', 'low', 'graphic_eq', 20)
ON CONFLICT DO NOTHING;
