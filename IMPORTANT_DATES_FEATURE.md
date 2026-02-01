# Important Dates Feature Documentation

## Overview

The Important Dates feature allows couples to track meaningful dates in their relationship, starting with their anniversary. The system ensures data integrity and provides a smooth user experience.

## Features

### 1. Anniversary Tracking
- Couples can set their Relationship Anniversary date
- System ensures only ONE anniversary per couple
- Anniversary date is used to calculate:
  - Time together (months and days)
  - Countdown to next anniversary milestone (e.g., 1 year)

### 2. Empty State
When a couple hasn't set their anniversary:
- Beautiful empty state card is displayed
- "Enter Anniversary Date" prompt
- Tapping opens the anniversary modal

### 3. Anniversary Modal
Two-screen modal flow:

**Screen 1: Date Entry**
- Title: "Add your Anniversary"
- Subtitle explains the purpose
- Date picker with calendar icon
- Save button (disabled until date selected)
- Close button

**Screen 2: Success State**
- Large checkmark icon
- "Date saved!" message
- Encouraging message about celebrating together
- Close button

## Database Schema

### Tables

#### `milestone_types`
Predefined milestone categories:
- The Day We Met
- First Date
- Relationship Anniversary ← Used for anniversary
- Partner's Birthday
- First 'I Love You'
- Move-in Day

#### `important_dates`
Stores important dates for couples:

| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Primary key |
| couple_id | UUID | References couples table |
| date_title | TEXT | Title of the date (e.g., "Our Anniversary") |
| event_date | DATE | The actual date |
| is_recurring | BOOLEAN | Whether it repeats annually |
| remind_me | BOOLEAN | Whether to send reminders |
| milestone_type_id | UUID | Links to milestone_types |
| category | TEXT | Optional category |
| notes | TEXT | Optional notes |
| added_by | UUID | User who added the date |

### Business Rules

1. **One Anniversary Per Couple**: Database trigger prevents multiple anniversary dates
2. **Couple-Based Access**: Both partners can view and manage dates
3. **Automatic Defaults**: 
   - Anniversary is set as recurring (annual)
   - Reminders are enabled by default

## Implementation Details

### Frontend Components

#### `AddAnniversaryModal` Widget
Location: `lib/widgets/add_anniversary_modal.dart`

**Props:**
- `coupleId`: The couple's UUID
- `onSaved`: Callback when date is successfully saved

**Features:**
- Date picker with custom theme (purple)
- Loading state while saving
- Success state with animation
- Error handling for duplicate anniversaries

#### `OurBloomScreen` Updates
Location: `lib/screens/our_bloom_screen.dart`

**New State:**
- `_hasAnniversaryDate`: Boolean flag
- `_coupleId`: Stored for modal usage

**New Methods:**
- `_checkAnniversaryDate()`: Checks if anniversary exists
- `_buildAnniversaryEmptyState()`: Renders empty state card

### Backend Integration

#### Supabase Queries

**Check Anniversary:**
```dart
await SupabaseService.client
  .from('important_dates')
  .select('event_date, milestone_types!inner(name)')
  .eq('couple_id', coupleId)
  .eq('milestone_types.name', 'Relationship Anniversary')
  .maybeSingle();
```

**Save Anniversary:**
```dart
await SupabaseService.client.from('important_dates').insert({
  'couple_id': widget.coupleId,
  'date_title': 'Our Anniversary',
  'event_date': selectedDate.toIso8601String().split('T')[0],
  'is_recurring': true,
  'remind_me': true,
  'milestone_type_id': milestoneTypeId,
  'category': 'Anniversary',
  'added_by': user.id,
});
```

## UI/UX Flow

### Empty State Flow
```
Our Bloom Screen
    ↓
[Together For Section - Empty State]
    ↓ (User taps)
[Anniversary Modal - Date Entry]
    ↓ (User picks date & saves)
[Anniversary Modal - Success State]
    ↓ (User taps Close)
[Together For Section - Filled State]
```

### Filled State Display
```
Together For
━━━━━━━━━━━━━━━━━━━
   07        09
 Months     Days

4 months 22 days until
1 year Anniversary
```

## Error Handling

### Duplicate Anniversary
If a couple tries to add a second anniversary:
- Database trigger rejects the insert
- Error message: "You already have an anniversary date set"
- Red snackbar notification

### Network Errors
- Generic error message
- User can retry
- Modal remains open

## Future Enhancements

1. **More Important Dates**: 
   - Add support for all milestone types
   - General "Add Important Date" feature
   - List view of all dates

2. **Edit/Delete**:
   - Allow updating anniversary date
   - Delete important dates

3. **Reminders**:
   - Push notifications before anniversaries
   - Email reminders

4. **Shared Notes**:
   - Add memories/notes to dates
   - Photo attachments

## Testing Checklist

- [ ] Empty state displays when no anniversary set
- [ ] Modal opens when tapping empty state
- [ ] Date picker works correctly
- [ ] Save button disabled without date
- [ ] Success state appears after save
- [ ] Together For section updates after save
- [ ] Cannot add duplicate anniversary
- [ ] Both partners see the same anniversary
- [ ] Countdown calculations are correct
- [ ] Modal closes properly

## Migration

Run this SQL in Supabase:
```bash
# Option 1: Full schema (if starting fresh)
Run: supabase_schema.sql

# Option 2: Migration only (existing database)
Run: IMPORTANT_DATES_MIGRATION.sql
```

## Troubleshooting

### Issue: Empty state shows even after adding anniversary
**Solution**: Check that:
1. `couple_id` is correctly set in user profiles
2. The milestone type "Relationship Anniversary" exists
3. Query joins are working correctly

### Issue: "Already have anniversary" error when adding first time
**Solution**: 
1. Check for orphaned records in important_dates
2. Verify couple_id matches correctly
3. Run: `DELETE FROM important_dates WHERE couple_id = 'your-couple-id'`

## Related Files

- `/lib/widgets/add_anniversary_modal.dart` - Anniversary modal UI
- `/lib/screens/our_bloom_screen.dart` - Main screen with empty/filled states
- `/supabase_schema.sql` - Complete database schema
- `/IMPORTANT_DATES_MIGRATION.sql` - Migration SQL
