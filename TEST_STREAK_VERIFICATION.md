# Streak System Verification Guide

## ✅ Confirm Both Partners' Activities Count Toward Shared Streak

### Step 1: Setup
1. Ensure you have two connected partners (Partner A and Partner B)
2. Run the streak migration SQL in Supabase
3. Note your `couple_id` (you can find it in Supabase dashboard under couples table)

### Step 2: Test Partner A Activity

**Action**: Partner A logs in and adds a bucket list item

**Expected Database State**:
```sql
-- Run this query in Supabase SQL Editor:
SELECT couple_id, activity_date, activity_count 
FROM daily_activities 
WHERE activity_date = CURRENT_DATE
ORDER BY activity_date DESC;
```

**Expected Result**:
```
couple_id                              | activity_date | activity_count
---------------------------------------|---------------|---------------
abc-123-xyz (your couple_id)           | 2026-01-25    | 1
```

### Step 3: Test Partner B Activity (Same Day)

**Action**: Partner B logs in and adds a wish list item

**Expected Database State**:
```sql
-- Run the same query again:
SELECT couple_id, activity_date, activity_count 
FROM daily_activities 
WHERE activity_date = CURRENT_DATE
ORDER BY activity_date DESC;
```

**Expected Result** (notice activity_count increased):
```
couple_id                              | activity_date | activity_count
---------------------------------------|---------------|---------------
abc-123-xyz (your couple_id)           | 2026-01-25    | 2
```

✅ **KEY OBSERVATION**: Same `couple_id`, same `activity_date`, but `activity_count` went from 1 to 2. This proves both partners update the SAME record!

### Step 4: Test Streak Calculation

**Action**: Both partners view "Our Bloom" screen

**Expected UI State**:
- Both partners see: "Streak: 1 Days"
- Monday indicator shows a checkmark (assuming today is Monday)
- The streak number is IDENTICAL for both partners

### Step 5: Test Multi-Day Streak

**Day 1**: Partner A adds bucket list item → Streak = 1
**Day 2**: Partner B adds wish list item → Streak = 2  
**Day 3**: Partner A marks plan complete → Streak = 3

**Expected Database State**:
```sql
SELECT activity_date, activity_count 
FROM daily_activities 
WHERE couple_id = 'your-couple-id'
ORDER BY activity_date DESC
LIMIT 7;
```

**Expected Result**:
```
activity_date | activity_count
--------------|---------------
2026-01-27    | 1             (Day 3: Partner A)
2026-01-26    | 1             (Day 2: Partner B)
2026-01-25    | 1             (Day 1: Partner A)
```

**Expected UI**: "Streak: 3 Days" for BOTH partners

### Step 6: Test Grace Period

**Day 1**: Partner A adds item → Streak = 1
**Day 2**: No activity from either partner → Streak continues (grace period)
**Day 3**: Partner B adds item → Streak = 2

**Database State**:
```
activity_date | activity_count
--------------|---------------
2026-01-27    | 1             (Day 3)
2026-01-25    | 1             (Day 1)
              (No Day 2 record)
```

✅ **Expected**: Streak still shows "2 Days" because of 1-day grace period

### Step 7: Test Streak Break

**Day 1**: Partner A adds item → Streak = 1
**Day 2**: No activity from either partner
**Day 3**: No activity from either partner
**Day 4**: Partner B adds item → Streak resets to 1

**Expected**: Streak shows "1 Days" (not 2) because >1 day gap breaks the streak

## Common Issues & Solutions

### Issue: Streak Not Updating
**Check**:
1. Are both partners in the same couple? Verify `couple_id` matches in `user_profiles`
2. Are triggers installed? Run `\df record_daily_activity` in Supabase SQL
3. Check for errors: Look in Supabase logs for "Failed to record daily activity" warnings

### Issue: Different Streaks for Each Partner
**Problem**: This shouldn't happen! Streaks are couple-based.
**Solution**: 
1. Verify both partners have the same `couple_id` in their user profiles
2. Check if `daily_activities` table has RLS policies enabled
3. Ensure you're querying with the correct `couple_id`

### Issue: Activity Count Not Incrementing
**Check**: 
1. Verify triggers are firing with:
```sql
SELECT * FROM pg_trigger WHERE tgname LIKE 'track_%';
```
2. Should see 3 triggers: `track_bucket_list_activity`, `track_wish_list_activity`, `track_plans_activity`

## Success Criteria ✅

- [ ] Partner A adds item → activity recorded
- [ ] Partner B adds item → SAME record updated (activity_count increases)
- [ ] Both partners see identical streak numbers
- [ ] Streak continues when either partner is active
- [ ] Streak breaks only after >1 day of inactivity from BOTH partners
- [ ] Weekly indicator shows checkmarks on days when either partner was active

## SQL Debugging Queries

```sql
-- Check couple relationship
SELECT 
  up.id, 
  up.username, 
  up.couple_id,
  c.user_a_id,
  c.user_b_id
FROM user_profiles up
LEFT JOIN couples c ON c.id = up.couple_id
WHERE up.id = 'your-user-id';

-- View all activities for your couple
SELECT * FROM daily_activities 
WHERE couple_id = 'your-couple-id'
ORDER BY activity_date DESC;

-- Count total activities
SELECT 
  activity_date,
  activity_count,
  created_at,
  updated_at
FROM daily_activities
WHERE couple_id = 'your-couple-id'
ORDER BY activity_date DESC;
```
