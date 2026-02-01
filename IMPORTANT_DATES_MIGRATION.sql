-- Important Dates Migration
-- Run this SQL in your Supabase SQL Editor to add anniversary and important dates feature

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
