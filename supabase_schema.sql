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
  partner_pet_name TEXT,
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

  -- Add partner_pet_name column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_profiles' AND column_name = 'partner_pet_name'
  ) THEN
    ALTER TABLE user_profiles ADD COLUMN partner_pet_name TEXT;
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

-- Profile details table for edit/complete profile flow
CREATE TABLE IF NOT EXISTS user_profile_details (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  birthday_date DATE,
  short_note TEXT,
  interests TEXT,
  love_language TEXT,
  care_preferences TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION refresh_user_profile_details_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_user_profile_details_timestamp ON user_profile_details;
CREATE TRIGGER set_user_profile_details_timestamp
BEFORE UPDATE ON user_profile_details
FOR EACH ROW
EXECUTE FUNCTION refresh_user_profile_details_timestamp();

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

-- User Interests Table (Onboarding Goals)
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

-- Interests Master Table (Personal Interests/Hobbies)
CREATE TABLE IF NOT EXISTS interests (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  category TEXT NOT NULL,
  vibe_color TEXT NOT NULL,
  name TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(category, name)
);

-- User Selected Interests (Many-to-Many)
CREATE TABLE IF NOT EXISTS user_selected_interests (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  interest_id UUID REFERENCES interests(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, interest_id)
);

-- Seed data for interests
INSERT INTO interests (category, vibe_color, name) VALUES
('Food & Drink', 'Orange', 'Try Sushi'),
('Food & Drink', 'Orange', 'Fine Dining'),
('Food & Drink', 'Orange', 'Street Food Tours'),
('Food & Drink', 'Orange', 'Wine Tasting'),
('Food & Drink', 'Orange', 'Home Cooking'),
('Food & Drink', 'Orange', 'Coffee Date Spots'),
('Food & Drink', 'Orange', 'Baking Together'),
('Travel & Adventure', 'Blue', 'Beach Getaways'),
('Travel & Adventure', 'Blue', 'Hiking & Nature'),
('Travel & Adventure', 'Blue', 'Road Trips'),
('Travel & Adventure', 'Blue', 'Camping'),
('Travel & Adventure', 'Blue', 'City Breaks'),
('Travel & Adventure', 'Blue', 'Extreme Sports'),
('Travel & Adventure', 'Blue', 'Staycations'),
('Home & Lifestyle', 'Lavender', 'Interior Design'),
('Home & Lifestyle', 'Lavender', 'Gardening'),
('Home & Lifestyle', 'Lavender', 'DIY Projects'),
('Home & Lifestyle', 'Lavender', 'Movie Marathons'),
('Home & Lifestyle', 'Lavender', 'Board Game Nights'),
('Home & Lifestyle', 'Lavender', 'Hosting Dinners'),
('Home & Lifestyle', 'Lavender', 'Slow Mornings'),
('Creativity & Hobbies', 'Pink', 'Painting'),
('Creativity & Hobbies', 'Pink', 'Pottery'),
('Creativity & Hobbies', 'Pink', 'Photography'),
('Creativity & Hobbies', 'Pink', 'Live Music/Concerts'),
('Creativity & Hobbies', 'Pink', 'Museums & Galleries'),
('Creativity & Hobbies', 'Pink', 'Dancing'),
('Creativity & Hobbies', 'Pink', 'Learning a Language'),
('Wellness & Connection', 'Green', 'Spa Days'),
('Wellness & Connection', 'Green', 'Meditation'),
('Wellness & Connection', 'Green', 'Couple''s Yoga'),
('Wellness & Connection', 'Green', 'Deep Conversations'),
('Wellness & Connection', 'Green', 'Stargazing'),
('Wellness & Connection', 'Green', 'Reading Together'),
('Wellness & Connection', 'Green', 'Volunteer Work'),
('Entertainment', 'Deep Purple', 'Binge-watching TV'),
('Entertainment', 'Deep Purple', 'Trivia Nights'),
('Entertainment', 'Deep Purple', 'E-Sports'),
('Entertainment', 'Deep Purple', 'Theatre & Musicals'),
('Entertainment', 'Deep Purple', 'Outdoor Cinemas'),
('Entertainment', 'Deep Purple', 'Comedy Clubs'),
('Entertainment', 'Deep Purple', 'Karaoke')
ON CONFLICT (category, name) DO NOTHING;

-- Love Languages Master Table
CREATE TABLE IF NOT EXISTS love_languages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  type TEXT NOT NULL UNIQUE,
  description TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Seed data for love_languages
INSERT INTO love_languages (type, description) VALUES
('Acts of Service', 'Feeling loved when your partner helps with responsibilities or goes out of their way to make your life easier.'),
('Quality Time', 'Feeling most connected through undivided attention, shared activities, and meaningful conversations.'),
('Words of Affirmation', 'Feeling valued through spoken or written words of affection, praise, appreciation, and encouragement.'),
('Receiving Gifts', 'Feeling loved by the thoughtfulness and effort behind a tangible gift, regardless of its cost.'),
('Physical Touch', 'Feeling secure and connected through physical closeness, such as holding hands, hugs, or sitting near each other.')
ON CONFLICT (type) DO NOTHING;

-- RLS for love_languages
ALTER TABLE love_languages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Love languages are viewable by everyone" ON love_languages;
CREATE POLICY "Love languages are viewable by everyone"
  ON love_languages FOR SELECT
  USING (true);

-- Receive Care Options Master Table
CREATE TABLE IF NOT EXISTS receive_care_options (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  type TEXT NOT NULL UNIQUE,
  description TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Seed data for receive_care_options
INSERT INTO receive_care_options (type, description) VALUES
('Emotional Space', 'Holding space for my feelings without immediate solutions.'),
('Practical Help', 'Taking the lead on chores or planning to lighten my load.'),
('Physical Presence', 'Being near me in comfortable silence.'),
('Encouragement', 'Using words and notes to lift my spirit.'),
('Comfort & Coziness', 'Providing physical comforts like snacks or warmth.'),
('Quality Time', 'Organizing a distraction-free activity for us.')
ON CONFLICT (type) DO NOTHING;

-- RLS for receive_care_options
ALTER TABLE receive_care_options ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Receive care options are viewable by everyone" ON receive_care_options;
CREATE POLICY "Receive care options are viewable by everyone"
  ON receive_care_options FOR SELECT
  USING (true);

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
CREATE INDEX IF NOT EXISTS idx_user_selected_interests_user_id ON user_selected_interests(user_id);
CREATE INDEX IF NOT EXISTS idx_user_selected_interests_interest_id ON user_selected_interests(interest_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_couple_id ON user_profiles(couple_id);
CREATE INDEX IF NOT EXISTS idx_couples_user_a_id ON couples(user_a_id);
CREATE INDEX IF NOT EXISTS idx_couples_user_b_id ON couples(user_b_id);

-- Indexes for plans
CREATE INDEX IF NOT EXISTS idx_plans_user_id ON plans(user_id);
CREATE INDEX IF NOT EXISTS idx_plans_plan_date_time ON plans(plan_date_time);

-- Enable Row Level Security
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_interests ENABLE ROW LEVEL SECURITY;
ALTER TABLE interests ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_selected_interests ENABLE ROW LEVEL SECURITY;
ALTER TABLE plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE couples ENABLE ROW LEVEL SECURITY;

-- RLS Policies for interests (master list)
DROP POLICY IF EXISTS "Interests are viewable by everyone" ON interests;
CREATE POLICY "Interests are viewable by everyone"
  ON interests FOR SELECT
  USING (true);

-- RLS Policies for user_selected_interests
DROP POLICY IF EXISTS "Users can view own selected interests" ON user_selected_interests;
DROP POLICY IF EXISTS "Users can view partner selected interests" ON user_selected_interests;
DROP POLICY IF EXISTS "Users can insert own selected interests" ON user_selected_interests;
DROP POLICY IF EXISTS "Users can delete own selected interests" ON user_selected_interests;

CREATE POLICY "Users can view own selected interests"
  ON user_selected_interests FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view partner selected interests"
  ON user_selected_interests FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles up 
      WHERE up.id = user_selected_interests.user_id 
      AND up.partner_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert own selected interests"
  ON user_selected_interests FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own selected interests"
  ON user_selected_interests FOR DELETE
  USING (auth.uid() = user_id);

-- RLS Policies for user_profile_details
ALTER TABLE user_profile_details ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own profile details" ON user_profile_details;
DROP POLICY IF EXISTS "Users can view partner profile details" ON user_profile_details;
DROP POLICY IF EXISTS "Users can insert own profile details" ON user_profile_details;
DROP POLICY IF EXISTS "Users can update own profile details" ON user_profile_details;

CREATE POLICY "Users can view own profile details"
  ON user_profile_details FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view partner profile details"
  ON user_profile_details FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles up 
      WHERE up.id = user_profile_details.user_id 
      AND up.partner_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert own profile details"
  ON user_profile_details FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own profile details"
  ON user_profile_details FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

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

-- Bucket List Categories Table
CREATE TABLE IF NOT EXISTS bucket_list_categories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Seed bucket list categories
INSERT INTO bucket_list_categories (name) VALUES
('Travel & Adventure'),
('Food & Drink'),
('Home & Cozy'),
('Creativity & Hobbies'),
('Wellness & Care'),
('Entertainment & Fun')
ON CONFLICT (name) DO NOTHING;

-- Bucket List Items Table
CREATE TABLE IF NOT EXISTS bucket_list_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  target_date TIMESTAMP WITH TIME ZONE,
  category_id UUID REFERENCES bucket_list_categories(id) ON DELETE SET NULL,
  collection TEXT,
  notes TEXT,
  links TEXT,
  theme_color TEXT,
  is_private BOOLEAN DEFAULT FALSE,
  is_completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS for bucket_list_categories
ALTER TABLE bucket_list_categories ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Bucket list categories are viewable by everyone" ON bucket_list_categories;
CREATE POLICY "Bucket list categories are viewable by everyone"
  ON bucket_list_categories FOR SELECT
  USING (true);

-- RLS for bucket_list_items
ALTER TABLE bucket_list_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own bucket list items" ON bucket_list_items;
DROP POLICY IF EXISTS "Users can view partner shared bucket list items" ON bucket_list_items;
DROP POLICY IF EXISTS "Users can insert own bucket list items" ON bucket_list_items;
DROP POLICY IF EXISTS "Users can update own bucket list items" ON bucket_list_items;
DROP POLICY IF EXISTS "Users can delete own bucket list items" ON bucket_list_items;

CREATE POLICY "Users can view own bucket list items"
  ON bucket_list_items FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view partner shared bucket list items"
  ON bucket_list_items FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles up 
      WHERE up.id = bucket_list_items.user_id 
      AND up.partner_id = auth.uid()
      AND bucket_list_items.is_private = FALSE
    )
  );

CREATE POLICY "Users can insert own bucket list items"
  ON bucket_list_items FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own bucket list items"
  ON bucket_list_items FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own bucket list items"
  ON bucket_list_items FOR DELETE
  USING (auth.uid() = user_id);

-- Trigger for bucket_list_items updated_at
DROP TRIGGER IF EXISTS update_bucket_list_items_updated_at ON bucket_list_items;
CREATE TRIGGER update_bucket_list_items_updated_at
  BEFORE UPDATE ON bucket_list_items
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Wish List Items Table
CREATE TABLE IF NOT EXISTS wish_list_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  category_id UUID REFERENCES bucket_list_categories(id) ON DELETE SET NULL,
  notes TEXT,
  links TEXT,
  theme_color TEXT,
  is_surprise BOOLEAN DEFAULT FALSE, -- Hide specifics from partner
  wish_for TEXT CHECK (wish_for IN ('Me', 'Partner')) DEFAULT 'Me',
  is_private BOOLEAN DEFAULT FALSE, -- Keep hidden until ready
  is_completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS for wish_list_items
ALTER TABLE wish_list_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own wish list items" ON wish_list_items;
CREATE POLICY "Users can view own wish list items"
  ON wish_list_items FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view partner shared wish list items" ON wish_list_items;
CREATE POLICY "Users can view partner shared wish list items"
  ON wish_list_items FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles up 
      WHERE up.id = wish_list_items.user_id 
      AND up.partner_id = auth.uid()
      AND wish_list_items.is_private = FALSE
    )
  );

DROP POLICY IF EXISTS "Users can insert own wish list items" ON wish_list_items;
CREATE POLICY "Users can insert own wish list items"
  ON wish_list_items FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own wish list items" ON wish_list_items;
CREATE POLICY "Users can update own wish list items"
  ON wish_list_items FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own wish list items" ON wish_list_items;
CREATE POLICY "Users can delete own wish list items"
  ON wish_list_items FOR DELETE
  USING (auth.uid() = user_id);

-- Trigger for wish_list_items updated_at
DROP TRIGGER IF EXISTS update_wish_list_items_updated_at ON wish_list_items;
CREATE TRIGGER update_wish_list_items_updated_at
  BEFORE UPDATE ON wish_list_items
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Bucket List Collections Table
CREATE TABLE IF NOT EXISTS bucket_list_collections (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, name)
);

-- RLS for bucket_list_collections
ALTER TABLE bucket_list_collections ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own collections" ON bucket_list_collections;
CREATE POLICY "Users can view own collections"
  ON bucket_list_collections FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view partner collections" ON bucket_list_collections;
CREATE POLICY "Users can view partner collections"
  ON bucket_list_collections FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles up 
      WHERE up.id = bucket_list_collections.user_id 
      AND up.partner_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Users can insert own collections" ON bucket_list_collections;
CREATE POLICY "Users can insert own collections"
  ON bucket_list_collections FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own collections" ON bucket_list_collections;
CREATE POLICY "Users can delete own collections"
  ON bucket_list_collections FOR DELETE
  USING (auth.uid() = user_id);

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

-- Daily Activities Table for Streak Tracking
CREATE TABLE IF NOT EXISTS daily_activities (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  couple_id UUID REFERENCES couples(id) ON DELETE CASCADE NOT NULL,
  activity_date DATE NOT NULL DEFAULT CURRENT_DATE,
  activity_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(couple_id, activity_date)
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_daily_activities_couple_date ON daily_activities(couple_id, activity_date DESC);

-- RLS for daily_activities
ALTER TABLE daily_activities ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their couple's daily activities" ON daily_activities;
CREATE POLICY "Users can view their couple's daily activities"
  ON daily_activities FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles up
      WHERE up.couple_id = daily_activities.couple_id
      AND up.id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "System can insert daily activities" ON daily_activities;
CREATE POLICY "System can insert daily activities"
  ON daily_activities FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles up
      WHERE up.couple_id = daily_activities.couple_id
      AND up.id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "System can update daily activities" ON daily_activities;
CREATE POLICY "System can update daily activities"
  ON daily_activities FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles up
      WHERE up.couple_id = daily_activities.couple_id
      AND up.id = auth.uid()
    )
  );

-- Function to record daily activity for COUPLES
-- This tracks activity for the entire couple - if EITHER partner performs an action,
-- it counts toward the shared couple streak.
CREATE OR REPLACE FUNCTION record_daily_activity()
RETURNS TRIGGER AS $$
DECLARE
  v_couple_id UUID;
  v_user_id UUID;
BEGIN
  -- Determine the user_id from the operation (could be either partner)
  IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    v_user_id := NEW.user_id;
  ELSIF TG_OP = 'DELETE' THEN
    v_user_id := OLD.user_id;
  END IF;

  -- Get the couple_id for this user
  -- Both partners share the same couple_id, so activity from either partner
  -- will update the SAME daily_activities record for the couple
  SELECT couple_id INTO v_couple_id
  FROM user_profiles
  WHERE id = v_user_id;

  -- Only record if user is in a couple
  IF v_couple_id IS NOT NULL THEN
    -- Insert or update the daily activity count for the COUPLE
    -- This means if Partner A adds an item in the morning and Partner B adds 
    -- an item in the evening, both activities count toward the same day's streak
    INSERT INTO daily_activities (couple_id, activity_date, activity_count)
    VALUES (v_couple_id, CURRENT_DATE, 1)
    ON CONFLICT (couple_id, activity_date)
    DO UPDATE SET 
      activity_count = daily_activities.activity_count + 1,
      updated_at = NOW();
  END IF;

  RETURN NEW;
EXCEPTION
  WHEN others THEN
    -- Don't fail the main operation if activity tracking fails
    RAISE WARNING 'Failed to record daily activity: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Triggers for bucket list items
DROP TRIGGER IF EXISTS track_bucket_list_activity ON bucket_list_items;
CREATE TRIGGER track_bucket_list_activity
  AFTER INSERT OR UPDATE ON bucket_list_items
  FOR EACH ROW
  EXECUTE FUNCTION record_daily_activity();

-- Triggers for wish list items
DROP TRIGGER IF EXISTS track_wish_list_activity ON wish_list_items;
CREATE TRIGGER track_wish_list_activity
  AFTER INSERT OR UPDATE ON wish_list_items
  FOR EACH ROW
  EXECUTE FUNCTION record_daily_activity();

-- Triggers for plans
DROP TRIGGER IF EXISTS track_plans_activity ON plans;
CREATE TRIGGER track_plans_activity
  AFTER INSERT OR UPDATE ON plans
  FOR EACH ROW
  EXECUTE FUNCTION record_daily_activity();

-- Milestone Types Table
CREATE TABLE IF NOT EXISTS milestone_types (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Seed milestone types
INSERT INTO milestone_types (name) VALUES
('The Day We Met'),
('First Date'),
('Relationship Anniversary'),
('Partner''s Birthday'),
('First ''I Love You'''),
('Move-in Day')
ON CONFLICT (name) DO NOTHING;

-- RLS for milestone_types
ALTER TABLE milestone_types ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Milestone types are viewable by everyone" ON milestone_types;
CREATE POLICY "Milestone types are viewable by everyone"
  ON milestone_types FOR SELECT
  USING (true);

-- Important Dates Table
CREATE TABLE IF NOT EXISTS important_dates (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  couple_id UUID REFERENCES couples(id) ON DELETE CASCADE NOT NULL,
  date_title TEXT NOT NULL,
  event_date DATE NOT NULL,
  is_recurring BOOLEAN DEFAULT false,
  remind_me BOOLEAN DEFAULT true,
  milestone_type_id UUID REFERENCES milestone_types(id) ON DELETE SET NULL,
  category TEXT,
  notes TEXT,
  added_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_important_dates_couple_id ON important_dates(couple_id);
CREATE INDEX IF NOT EXISTS idx_important_dates_event_date ON important_dates(event_date);
CREATE INDEX IF NOT EXISTS idx_important_dates_milestone_type ON important_dates(milestone_type_id);

-- RLS for important_dates
ALTER TABLE important_dates ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their couple's important dates" ON important_dates;
CREATE POLICY "Users can view their couple's important dates"
  ON important_dates FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles up
      WHERE up.couple_id = important_dates.couple_id
      AND up.id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Users can insert important dates for their couple" ON important_dates;
CREATE POLICY "Users can insert important dates for their couple"
  ON important_dates FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles up
      WHERE up.couple_id = important_dates.couple_id
      AND up.id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Users can update their couple's important dates" ON important_dates;
CREATE POLICY "Users can update their couple's important dates"
  ON important_dates FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles up
      WHERE up.couple_id = important_dates.couple_id
      AND up.id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Users can delete their couple's important dates" ON important_dates;
CREATE POLICY "Users can delete their couple's important dates"
  ON important_dates FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles up
      WHERE up.couple_id = important_dates.couple_id
      AND up.id = auth.uid()
    )
  );

-- Trigger for important_dates updated_at
DROP TRIGGER IF EXISTS update_important_dates_updated_at ON important_dates;
CREATE TRIGGER update_important_dates_updated_at
  BEFORE UPDATE ON important_dates
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Function to check if anniversary already exists for a couple
CREATE OR REPLACE FUNCTION check_anniversary_exists()
RETURNS TRIGGER AS $$
DECLARE
  v_milestone_type_name TEXT;
BEGIN
  -- Get the milestone type name
  SELECT name INTO v_milestone_type_name
  FROM milestone_types
  WHERE id = NEW.milestone_type_id;

  -- Check if it's an anniversary type
  IF v_milestone_type_name = 'Relationship Anniversary' THEN
    -- Check if couple already has an anniversary
    IF EXISTS (
      SELECT 1 FROM important_dates id
      JOIN milestone_types mt ON mt.id = id.milestone_type_id
      WHERE id.couple_id = NEW.couple_id
      AND mt.name = 'Relationship Anniversary'
      AND id.id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::UUID)
    ) THEN
      RAISE EXCEPTION 'A couple can only have one Relationship Anniversary date';
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to enforce one anniversary per couple
DROP TRIGGER IF EXISTS enforce_single_anniversary ON important_dates;
CREATE TRIGGER enforce_single_anniversary
  BEFORE INSERT OR UPDATE ON important_dates
  FOR EACH ROW
  EXECUTE FUNCTION check_anniversary_exists();

-- Bloom Notes Table
-- Short notes that partners can send to each other, expire after 24 hours
CREATE TABLE IF NOT EXISTS bloom_notes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  couple_id UUID REFERENCES couples(id) ON DELETE CASCADE NOT NULL,
  sender_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  recipient_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  message TEXT NOT NULL,
  is_liked BOOLEAN DEFAULT FALSE,
  liked_at TIMESTAMP WITH TIME ZONE,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_bloom_notes_couple_id ON bloom_notes(couple_id);
CREATE INDEX IF NOT EXISTS idx_bloom_notes_recipient_id ON bloom_notes(recipient_id);
CREATE INDEX IF NOT EXISTS idx_bloom_notes_sender_id ON bloom_notes(sender_id);
CREATE INDEX IF NOT EXISTS idx_bloom_notes_expires_at ON bloom_notes(expires_at);

-- RLS for bloom_notes
ALTER TABLE bloom_notes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view notes sent to them" ON bloom_notes;
CREATE POLICY "Users can view notes sent to them"
  ON bloom_notes FOR SELECT
  USING (auth.uid() = recipient_id OR auth.uid() = sender_id);

DROP POLICY IF EXISTS "Users can insert notes to their partner" ON bloom_notes;
CREATE POLICY "Users can insert notes to their partner"
  ON bloom_notes FOR INSERT
  WITH CHECK (
    auth.uid() = sender_id
    AND EXISTS (
      SELECT 1 FROM user_profiles up
      WHERE up.id = auth.uid()
      AND up.partner_id = bloom_notes.recipient_id
      AND up.couple_id = bloom_notes.couple_id
    )
  );

DROP POLICY IF EXISTS "Users can update notes sent to them (like)" ON bloom_notes;
CREATE POLICY "Users can update notes sent to them (like)"
  ON bloom_notes FOR UPDATE
  USING (auth.uid() = recipient_id)
  WITH CHECK (auth.uid() = recipient_id);

-- Function to automatically delete expired notes
CREATE OR REPLACE FUNCTION delete_expired_bloom_notes()
RETURNS void AS $$
BEGIN
  DELETE FROM bloom_notes
  WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Note: To enable automatic deletion, you would set up a pg_cron job or call this function periodically
-- For now, the app can filter expired notes on the client side

