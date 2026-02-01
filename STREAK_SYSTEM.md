# Streak System Documentation

## Overview

The Bloom streak system tracks daily **couple activity** based on meaningful interactions with the app. 

**🔑 Key Point: This is a SHARED COUPLE STREAK**
- If **EITHER partner** performs any tracked action, it counts toward the couple's streak
- Both partners contribute to the same streak counter
- The streak belongs to the couple, not individual users

A streak day is counted when **either partner** performs any of the following actions:

## Tracked Activities

1. **Bucket List Items**
   - Adding a new bucket list item
   - Editing/updating an existing bucket list item
   - Marking a bucket list item as complete

2. **Wish List Items**
   - Adding a new wish list item
   - Editing/updating an existing wish list item
   - Marking a wish list item as complete

3. **Plans**
   - Creating a new plan
   - Editing/updating an existing plan
   - Marking a plan as complete

4. **Bloom Notes** (Future Feature)
   - Sharing a note with partner

## How It Works (Architecture)

```
┌─────────────┐         ┌─────────────┐
│  Partner A  │         │  Partner B  │
│  (User ID)  │         │  (User ID)  │
└──────┬──────┘         └──────┬──────┘
       │                       │
       │  Both reference       │
       │  same couple_id       │
       └──────┬────────────────┘
              │
              ▼
    ┌─────────────────────┐
    │   Couple Record     │
    │   (couple_id: ABC)  │
    └─────────┬───────────┘
              │
              │ Tracks activity for
              ▼
    ┌─────────────────────────────┐
    │   Daily Activities Table    │
    ├─────────────────────────────┤
    │ couple_id | date  | count   │
    │   ABC     | Mon   |   3     │ ← Partner A: 2 actions, Partner B: 1 action
    │   ABC     | Tue   |   1     │ ← Partner B: 1 action
    │   ABC     | Wed   |   2     │ ← Partner A: 2 actions
    └─────────────────────────────┘
    
Result: 3-day streak (Mon, Tue, Wed active)
```

### Database Tables

#### `daily_activities`
Tracks activity for each couple by date:
- `couple_id`: Links to the couple
- `activity_date`: The date of activity (DATE type)
- `activity_count`: Number of activities on that date
- Unique constraint on `(couple_id, activity_date)`

### Automatic Tracking

Database triggers automatically record activity when:
- Items are **inserted** into bucket_list_items, wish_list_items, or plans
- Items are **updated** in any of these tables

The triggers call the `record_daily_activity()` function which:
1. Gets the user's `couple_id`
2. Inserts or updates today's activity count
3. Silently fails if the user is not in a couple (solo users don't have streaks)

### Streak Calculation

The `StreakService` calculates streaks by:

1. **Current Streak**: Counts consecutive days with activity, starting from today or yesterday
   - Streak continues if there was activity today OR yesterday
   - Streak breaks if more than 1 day has passed since last activity
   - Counts backwards through all consecutive days with activity

2. **Weekly Streak**: Shows activity for the current week (Monday-Sunday)
   - Each day shows a checkmark if any activity occurred
   - Helps visualize engagement patterns

## Implementation Details

### Database Triggers

```sql
-- Triggers are set up on all three tables
CREATE TRIGGER track_bucket_list_activity
  AFTER INSERT OR UPDATE ON bucket_list_items
  FOR EACH ROW
  EXECUTE FUNCTION record_daily_activity();
```

### Flutter Service

The `StreakService` provides:

```dart
// Calculate streak for a couple
Future<StreakData> calculateStreak(String coupleId)

// Manually record activity (optional, triggers handle it automatically)
Future<void> recordActivity()
```

### Benefits

1. **Automatic**: No need to manually call recording functions
2. **Reliable**: Database-level tracking ensures no activities are missed
3. **Efficient**: Single daily record per couple (not per activity)
4. **Grace Period**: Streak continues if you were active yesterday
5. **Couple-Based**: Both partners' activities count toward the shared streak

## Testing & Verification

### How to Verify Both Partners Are Tracked

After running the migration, you can test that both partners' activities count:

1. **Partner A**: Add a bucket list item
2. **Check Database**:
```sql
SELECT * FROM daily_activities 
WHERE couple_id = 'your-couple-id' 
ORDER BY activity_date DESC;
```
   Should show 1 record for today with `activity_count = 1`

3. **Partner B**: Add a wish list item  
4. **Check Database Again**:
```sql
SELECT * FROM daily_activities 
WHERE couple_id = 'your-couple-id' 
ORDER BY activity_date DESC;
```
   Should show the SAME record with `activity_count = 2`

5. **View in App**: Both partners should see the same streak number in "Our Bloom"

### Quick Verification Query

```sql
-- See all activities for a couple
SELECT 
  da.activity_date,
  da.activity_count,
  c.user_a_id,
  c.user_b_id,
  up1.username as partner_a_name,
  up2.username as partner_b_name
FROM daily_activities da
JOIN couples c ON c.id = da.couple_id
JOIN user_profiles up1 ON up1.id = c.user_a_id
JOIN user_profiles up2 ON up2.id = c.user_b_id
WHERE da.couple_id = 'your-couple-id'
ORDER BY da.activity_date DESC;
```

## Extending the System

To add streak tracking for new features:

1. Ensure the table has a `user_id` column
2. Add a trigger:
```sql
CREATE TRIGGER track_[table]_activity
  AFTER INSERT OR UPDATE ON [table_name]
  FOR EACH ROW
  EXECUTE FUNCTION record_daily_activity();
```

That's it! The existing function handles the rest.

## Example Streak Scenarios

### Example 1: Both Partners Active
**Monday**: Partner A adds 3 bucket list items → ✅ 1 streak day recorded
**Tuesday**: Partner B edits a plan → ✅ 1 streak day recorded  
**Wednesday**: Partner A adds wish list item, Partner B marks plan complete → ✅ 1 streak day recorded
**Thursday**: No activity from either partner → streak continues (grace period)
**Friday**: No activity from either partner → ❌ streak broken (>1 day since last activity)

Current streak: **3 days** (Mon-Wed)

### Example 2: Only One Partner Active
**Monday**: Partner A adds bucket list item → ✅ 1 streak day recorded
**Tuesday**: Partner A edits wish list item → ✅ 1 streak day recorded  
**Wednesday**: Partner A marks plan complete → ✅ 1 streak day recorded
**Thursday**: Partner B adds bucket list item → ✅ 1 streak day recorded

Current streak: **4 days** (Mon-Thu)

*Note: It doesn't matter which partner is active - the streak continues as long as SOMEONE does something!*

### Example 3: How Activity Count Works
**Monday 9am**: Partner A adds bucket list item → activity_count = 1
**Monday 2pm**: Partner B adds wish list item → activity_count = 2
**Monday 8pm**: Partner A marks plan complete → activity_count = 3

Result: Still just **1 streak day** recorded (Monday), but with 3 total activities.
The streak counts DAYS, not individual actions.
