-- Bloom Onboarding Database Schema
-- Run this SQL in your Supabase SQL Editor

-- User Profiles Table
-- Extends Supabase auth.users with onboarding data
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT,
  username TEXT UNIQUE,
  profile_image_url TEXT,
  invite_code TEXT,
  partner_invite_code TEXT, -- Code of the partner they connected with
  partner_id UUID REFERENCES auth.users(id) ON DELETE SET NULL, -- Connected partner's user ID
  couple_id UUID, -- Shared couple profile id
  age_range TEXT CHECK (age_range IN ('18-24', '25-34', '35-44', '45+')),
  experience_level TEXT CHECK (experience_level IN ('First time using something like this', 'I''ve tried similar apps')),
  onboarding_completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Couples Table (shared profile for two users)
CREATE TABLE IF NOT EXISTS couples (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_a_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  user_b_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE (user_a_id, user_b_id),
  CHECK (user_a_id <> user_b_id)
);

-- Add missing columns if they don't exist (for existing tables)
DO $$ 
BEGIN
  -- Add username column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_profiles' AND column_name = 'username'
  ) THEN
    ALTER TABLE user_profiles ADD COLUMN username TEXT UNIQUE;
  END IF;
  
  -- Add profile_image_url column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_profiles' AND column_name = 'profile_image_url'
  ) THEN
    ALTER TABLE user_profiles ADD COLUMN profile_image_url TEXT;
  END IF;
  
  -- Add email column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_profiles' AND column_name = 'email'
  ) THEN
    ALTER TABLE user_profiles ADD COLUMN email TEXT;
  END IF;
  
  -- Add invite_code column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_profiles' AND column_name = 'invite_code'
  ) THEN
    ALTER TABLE user_profiles ADD COLUMN invite_code TEXT;
  END IF;
  
  -- Add partner_invite_code column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_profiles' AND column_name = 'partner_invite_code'
  ) THEN
    ALTER TABLE user_profiles ADD COLUMN partner_invite_code TEXT;
  END IF;
  
  -- Add partner_id column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_profiles' AND column_name = 'partner_id'
  ) THEN
    ALTER TABLE user_profiles ADD COLUMN partner_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;
  END IF;

  -- Add couple_id column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_profiles' AND column_name = 'couple_id'
  ) THEN
    ALTER TABLE user_profiles ADD COLUMN couple_id UUID REFERENCES couples(id) ON DELETE SET NULL;
  END IF;
  
  -- Add age_range column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_profiles' AND column_name = 'age_range'
  ) THEN
    ALTER TABLE user_profiles ADD COLUMN age_range TEXT CHECK (age_range IN ('18-24', '25-34', '35-44', '45+'));
  END IF;
  
  -- Add experience_level column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_profiles' AND column_name = 'experience_level'
  ) THEN
    ALTER TABLE user_profiles ADD COLUMN experience_level TEXT CHECK (experience_level IN ('First time using something like this', 'I''ve tried similar apps'));
  END IF;
  
  -- Add onboarding_completed column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_profiles' AND column_name = 'onboarding_completed'
  ) THEN
    ALTER TABLE user_profiles ADD COLUMN onboarding_completed BOOLEAN DEFAULT FALSE;
  END IF;
  
  -- Add created_at column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_profiles' AND column_name = 'created_at'
  ) THEN
    ALTER TABLE user_profiles ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
  END IF;
  
  -- Add updated_at column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_profiles' AND column_name = 'updated_at'
  ) THEN
    ALTER TABLE user_profiles ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
  END IF;
END $$;

-- Add unique constraints if they don't exist
DO $$
BEGIN
  -- Add unique constraint on username if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'user_profiles_username_key'
  ) THEN
    ALTER TABLE user_profiles ADD CONSTRAINT user_profiles_username_key UNIQUE (username);
  END IF;
  
  -- Add unique constraint on invite_code if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'user_profiles_invite_code_key'
  ) THEN
    ALTER TABLE user_profiles ADD CONSTRAINT user_profiles_invite_code_key UNIQUE (invite_code);
  END IF;
END $$;

-- Add NOT NULL constraint on invite_code (only if column is empty, we'll populate it)
-- We'll handle this in the trigger function

-- Storage bucket for profile images
INSERT INTO storage.buckets (id, name, public) 
VALUES ('profile-images', 'profile-images', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policy for profile images
DROP POLICY IF EXISTS "Users can upload own profile images" ON storage.objects;
CREATE POLICY "Users can upload own profile images"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'profile-images' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

DROP POLICY IF EXISTS "Users can view all profile images" ON storage.objects;
CREATE POLICY "Users can view all profile images"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'profile-images');

DROP POLICY IF EXISTS "Users can update own profile images" ON storage.objects;
CREATE POLICY "Users can update own profile images"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'profile-images' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

DROP POLICY IF EXISTS "Users can delete own profile images" ON storage.objects;
CREATE POLICY "Users can delete own profile images"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'profile-images' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- User Interests Table (Many-to-Many relationship)
CREATE TABLE IF NOT EXISTS user_interests (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  interest TEXT NOT NULL CHECK (interest IN (
    'Stay connected',
    'Plan things together',
    'Track shared goals',
    'Share Bucket-lists and wish-lists',
    'Navigate a long-distance relationship'
  )),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, interest)
);

-- Plans Table
CREATE TABLE IF NOT EXISTS plans (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  plan_title TEXT NOT NULL,
  location TEXT,
  checklist TEXT[],
  notes TEXT,
  links TEXT,
  theme_color TEXT,
  plan_date_time TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for better query performance
-- Only create indexes if the columns exist
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_profiles' AND column_name = 'invite_code'
  ) THEN
    CREATE INDEX IF NOT EXISTS idx_user_profiles_invite_code ON user_profiles(invite_code);
  END IF;
  
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_profiles' AND column_name = 'partner_id'
  ) THEN
    CREATE INDEX IF NOT EXISTS idx_user_profiles_partner_id ON user_profiles(partner_id);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_user_interests_user_id ON user_interests(user_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_couple_id ON user_profiles(couple_id);
CREATE INDEX IF NOT EXISTS idx_couples_user_a_id ON couples(user_a_id);
CREATE INDEX IF NOT EXISTS idx_couples_user_b_id ON couples(user_b_id);

-- Indexes for plans
CREATE INDEX IF NOT EXISTS idx_plans_user_id ON plans(user_id);
CREATE INDEX IF NOT EXISTS idx_plans_plan_date_time ON plans(plan_date_time);

-- Enable Row Level Security
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_interests ENABLE ROW LEVEL SECURITY;
ALTER TABLE plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE couples ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_profiles
-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can view partner profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;

-- Users can view their own profile
CREATE POLICY "Users can view own profile"
  ON user_profiles FOR SELECT
  USING (auth.uid() = id);

-- Users can view their partner's profile
-- Note: This policy allows viewing partner profiles by checking if the current user's partner_id matches this profile's id
CREATE POLICY "Users can view partner profile"
  ON user_profiles FOR SELECT
  USING (
    -- User can view profiles where they are listed as the partner
    auth.uid() = partner_id
  );

-- Users can insert their own profile
CREATE POLICY "Users can insert own profile"
  ON user_profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- RLS Policies for couples
DROP POLICY IF EXISTS "Users can view own couple" ON couples;

CREATE POLICY "Users can view own couple"
  ON couples FOR SELECT
  USING (
    auth.uid() = user_a_id OR auth.uid() = user_b_id
  );

-- RLS Policies for user_interests
-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own interests" ON user_interests;
DROP POLICY IF EXISTS "Users can view partner interests" ON user_interests;
DROP POLICY IF EXISTS "Users can insert own interests" ON user_interests;
DROP POLICY IF EXISTS "Users can delete own interests" ON user_interests;

-- Users can view their own interests
CREATE POLICY "Users can view own interests"
  ON user_interests FOR SELECT
  USING (auth.uid() = user_id);

-- Users can view their partner's interests
-- Check if the interest's user_id has the current user as their partner
CREATE POLICY "Users can view partner interests"
  ON user_interests FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles up 
      WHERE up.id = user_interests.user_id 
      AND up.partner_id = auth.uid()
    )
  );

-- Users can insert their own interests
CREATE POLICY "Users can insert own interests"
  ON user_interests FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own interests
CREATE POLICY "Users can delete own interests"
  ON user_interests FOR DELETE
  USING (auth.uid() = user_id);

-- RLS Policies for plans
DROP POLICY IF EXISTS "Users can view own plans" ON plans;
DROP POLICY IF EXISTS "Users can view partner plans" ON plans;
DROP POLICY IF EXISTS "Users can insert own plans" ON plans;
DROP POLICY IF EXISTS "Users can update own plans" ON plans;
DROP POLICY IF EXISTS "Users can delete own plans" ON plans;

-- Users can view their own plans
CREATE POLICY "Users can view own plans"
  ON plans FOR SELECT
  USING (auth.uid() = user_id);

-- Users can view their partner's plans
CREATE POLICY "Users can view partner plans"
  ON plans FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles up
      WHERE up.id = plans.user_id
      AND (
        up.partner_id = auth.uid()
        OR up.couple_id = (
          SELECT couple_id FROM user_profiles WHERE id = auth.uid()
        )
      )
    )
  );

-- Users can insert their own plans
CREATE POLICY "Users can insert own plans"
  ON plans FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own plans
CREATE POLICY "Users can update own plans"
  ON plans FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own plans
CREATE POLICY "Users can delete own plans"
  ON plans FOR DELETE
  USING (auth.uid() = user_id);

-- Function to generate unique invite code
CREATE OR REPLACE FUNCTION generate_unique_invite_code()
RETURNS TEXT AS $$
DECLARE
  chars TEXT := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  code TEXT := '';
  i INTEGER;
  char_index INTEGER;
  exists_check BOOLEAN;
BEGIN
  LOOP
    code := '';
    FOR i IN 1..5 LOOP
      char_index := floor(random() * length(chars) + 1)::INTEGER;
      code := code || substr(chars, char_index, 1);
    END LOOP;
    
    -- Check if code already exists
    SELECT EXISTS(SELECT 1 FROM user_profiles WHERE invite_code = code) INTO exists_check;
    
    -- Exit loop if code is unique
    EXIT WHEN NOT exists_check;
  END LOOP;
  
  RETURN code;
END;
$$ LANGUAGE plpgsql;

-- Function to automatically create profile when user signs up
-- This function runs with SECURITY DEFINER to bypass RLS policies
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  new_invite_code TEXT;
BEGIN
  -- Generate unique invite code
  new_invite_code := generate_unique_invite_code();
  
  -- Insert profile with invite code
  -- SECURITY DEFINER allows this to bypass RLS policies
  INSERT INTO public.user_profiles (id, email, invite_code, onboarding_completed)
  VALUES (
    NEW.id,
    COALESCE(NEW.email, ''),
    new_invite_code,
    false
  )
  ON CONFLICT (id) DO UPDATE SET
    email = COALESCE(EXCLUDED.email, user_profiles.email),
    invite_code = COALESCE(user_profiles.invite_code, EXCLUDED.invite_code);
  
  RETURN NEW;
EXCEPTION
  WHEN others THEN
    -- Log error but don't fail the user creation
    -- This ensures user signup succeeds even if profile creation fails
    RAISE WARNING 'Error creating user profile for %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Trigger to create profile on user signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at on user_profiles
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON user_profiles;
CREATE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger to update updated_at on plans
DROP TRIGGER IF EXISTS update_plans_updated_at ON plans;
CREATE TRIGGER update_plans_updated_at
  BEFORE UPDATE ON plans
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to connect partners via invite code
CREATE OR REPLACE FUNCTION connect_partners(invite_code_param TEXT)
RETURNS JSON AS $$
DECLARE
  partner_user_id UUID;
  current_user_id UUID;
  v_couple_id UUID;
BEGIN
  current_user_id := auth.uid();
  
  -- Find partner by invite code
  SELECT id INTO partner_user_id
  FROM user_profiles
  WHERE invite_code = invite_code_param
    AND id != current_user_id
    AND partner_id IS NULL; -- Partner must not already be connected
  
  IF partner_user_id IS NULL THEN
    RETURN json_build_object('success', false, 'message', 'Invalid or already connected invite code');
  END IF;

  -- Create or reuse couple record
  WITH upsert_couple AS (
    INSERT INTO couples (user_a_id, user_b_id)
    VALUES (LEAST(current_user_id, partner_user_id), GREATEST(current_user_id, partner_user_id))
    ON CONFLICT (user_a_id, user_b_id)
    DO UPDATE SET user_a_id = EXCLUDED.user_a_id
    RETURNING id
  )
  SELECT id INTO v_couple_id FROM upsert_couple;

  -- Update both users to connect them
  UPDATE user_profiles
  SET partner_id = partner_user_id,
      partner_invite_code = invite_code_param,
      couple_id = v_couple_id,
      updated_at = NOW()
  WHERE id = current_user_id;
  
  UPDATE user_profiles
  SET partner_id = current_user_id,
      partner_invite_code = (SELECT invite_code FROM user_profiles WHERE id = current_user_id),
      couple_id = v_couple_id,
      updated_at = NOW()
  WHERE id = partner_user_id;
  
  RETURN json_build_object('success', true, 'partner_id', partner_user_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

