-- Streak System Migration
-- Run this SQL in your Supabase SQL Editor to add streak tracking

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
