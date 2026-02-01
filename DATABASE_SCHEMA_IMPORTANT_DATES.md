# Database Schema: Important Dates & Anniversary

## Table Relationships

```
┌─────────────────────────┐
│   milestone_types       │
│─────────────────────────│
│ id (PK)                 │
│ name (UNIQUE)           │
│ created_at              │
└─────────────────────────┘
           │
           │ Referenced by
           │ milestone_type_id
           ▼
┌─────────────────────────────────────┐
│   important_dates                   │
│─────────────────────────────────────│
│ id (PK)                             │
│ couple_id (FK) ─────────┐           │
│ date_title              │           │
│ event_date              │           │
│ is_recurring            │           │
│ remind_me               │           │
│ milestone_type_id (FK)  │           │
│ category                │           │
│ notes                   │           │
│ added_by (FK) ──────────┼─────┐     │
│ created_at              │     │     │
│ updated_at              │     │     │
└─────────────────────────┼─────┼─────┘
                          │     │
                          │     └────────────────┐
                          │                      │
                          ▼                      ▼
              ┌─────────────────────┐  ┌─────────────────┐
              │   couples           │  │  auth.users     │
              │─────────────────────│  │─────────────────│
              │ id (PK)             │  │ id (PK)         │
              │ user_a_id (FK)      │  │ email           │
              │ user_b_id (FK)      │  │ ...             │
              │ created_at          │  └─────────────────┘
              └─────────────────────┘
                        │
              Both user_a_id and
              user_b_id reference
              auth.users(id)
```

## Milestone Types (Seeded Data)

```sql
INSERT INTO milestone_types (name) VALUES
  ('The Day We Met'),
  ('First Date'),
  ('Relationship Anniversary'),  ← Used for anniversary feature
  ('Partner''s Birthday'),
  ('First ''I Love You'''),
  ('Move-in Day');
```

## Important Dates Schema

### Core Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | UUID | ✅ | Primary key |
| `couple_id` | UUID | ✅ | Links to couples table |
| `date_title` | TEXT | ✅ | E.g., "Our Anniversary" |
| `event_date` | DATE | ✅ | The actual date |

### Feature Flags

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `is_recurring` | BOOLEAN | false | Annual repeat |
| `remind_me` | BOOLEAN | true | Send reminders |

### Categorization

| Field | Type | Description |
|-------|------|-------------|
| `milestone_type_id` | UUID | Links to milestone_types |
| `category` | TEXT | Custom category (optional) |

### Metadata

| Field | Type | Description |
|-------|------|-------------|
| `notes` | TEXT | User notes/memories |
| `added_by` | UUID | User who created it |
| `created_at` | TIMESTAMP | Creation time |
| `updated_at` | TIMESTAMP | Last update time |

## Row Level Security (RLS)

### Policies for important_dates

1. **SELECT** - Users can view their couple's dates
```sql
EXISTS (
  SELECT 1 FROM user_profiles up
  WHERE up.couple_id = important_dates.couple_id
  AND up.id = auth.uid()
)
```

2. **INSERT** - Users can add dates for their couple
```sql
EXISTS (
  SELECT 1 FROM user_profiles up
  WHERE up.couple_id = important_dates.couple_id
  AND up.id = auth.uid()
)
```

3. **UPDATE** - Users can update their couple's dates
```sql
EXISTS (
  SELECT 1 FROM user_profiles up
  WHERE up.couple_id = important_dates.couple_id
  AND up.id = auth.uid()
)
```

4. **DELETE** - Users can delete their couple's dates
```sql
EXISTS (
  SELECT 1 FROM user_profiles up
  WHERE up.couple_id = important_dates.couple_id
  AND up.id = auth.uid()
)
```

### Policies for milestone_types

1. **SELECT** - Everyone can view milestone types
```sql
USING (true)
```

## Triggers & Functions

### 1. Updated At Trigger
```sql
CREATE TRIGGER update_important_dates_updated_at
  BEFORE UPDATE ON important_dates
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```
Auto-updates `updated_at` timestamp on changes.

### 2. Anniversary Validation Trigger
```sql
CREATE TRIGGER enforce_single_anniversary
  BEFORE INSERT OR UPDATE ON important_dates
  FOR EACH ROW
  EXECUTE FUNCTION check_anniversary_exists();
```
Enforces one anniversary per couple.

### 3. Anniversary Check Function
```sql
CREATE FUNCTION check_anniversary_exists()
RETURNS TRIGGER AS $$
BEGIN
  IF milestone_type = 'Relationship Anniversary' THEN
    IF couple already has anniversary THEN
      RAISE EXCEPTION 'Only one anniversary allowed';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;
```

## Indexes

```sql
-- Faster couple-based queries
CREATE INDEX idx_important_dates_couple_id 
  ON important_dates(couple_id);

-- Date range queries
CREATE INDEX idx_important_dates_event_date 
  ON important_dates(event_date);

-- Milestone type filtering
CREATE INDEX idx_important_dates_milestone_type 
  ON important_dates(milestone_type_id);
```

## Example Queries

### Get Anniversary for a Couple
```sql
SELECT 
  id.event_date,
  id.date_title,
  id.notes,
  mt.name as milestone_type
FROM important_dates id
JOIN milestone_types mt ON mt.id = id.milestone_type_id
WHERE id.couple_id = 'couple-uuid'
AND mt.name = 'Relationship Anniversary';
```

### Get All Important Dates for a Couple
```sql
SELECT 
  id.*,
  mt.name as milestone_type
FROM important_dates id
LEFT JOIN milestone_types mt ON mt.id = id.milestone_type_id
WHERE id.couple_id = 'couple-uuid'
ORDER BY id.event_date ASC;
```

### Get Upcoming Dates (Next 30 Days)
```sql
SELECT 
  id.*,
  mt.name as milestone_type
FROM important_dates id
LEFT JOIN milestone_types mt ON mt.id = id.milestone_type_id
WHERE id.couple_id = 'couple-uuid'
AND id.event_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days'
ORDER BY id.event_date ASC;
```

## Data Access Pattern

### From Flutter App

1. **User Profile** → Get `couple_id`
```dart
SELECT couple_id FROM user_profiles WHERE id = auth.uid()
```

2. **Check Anniversary** → Query by milestone type
```dart
SELECT event_date 
FROM important_dates id
JOIN milestone_types mt ON mt.id = id.milestone_type_id
WHERE id.couple_id = ? AND mt.name = 'Relationship Anniversary'
```

3. **Add Anniversary** → Insert with validation
```dart
INSERT INTO important_dates (
  couple_id, date_title, event_date, 
  is_recurring, milestone_type_id, added_by
) VALUES (?, 'Our Anniversary', ?, true, ?, auth.uid())
```

## Storage Estimates

### Small Couple (Minimal Data)
- 1 anniversary = ~200 bytes
- 5 other dates = ~1 KB
- **Total: ~1.2 KB per couple**

### Active Couple (Rich Data)
- 1 anniversary with notes = ~500 bytes
- 20 important dates with notes = ~10 KB
- **Total: ~10.5 KB per couple**

### System Scale (10,000 couples)
- Minimal usage: ~12 MB
- Active usage: ~105 MB
- **Very efficient storage**

## Performance Considerations

### Query Performance
- ✅ Indexed on couple_id (most common filter)
- ✅ Indexed on event_date (for date range queries)
- ✅ Small table size (average ~10 rows per couple)
- ⚡ Sub-millisecond query times expected

### Write Performance
- ✅ Triggers are lightweight (simple validation)
- ✅ No cascading updates
- ✅ Minimal foreign key checks
- ⚡ Fast inserts/updates

## Migration Safety

### Rollback Plan
If issues occur, rollback is safe:

```sql
-- Remove trigger
DROP TRIGGER IF EXISTS enforce_single_anniversary ON important_dates;

-- Remove function
DROP FUNCTION IF EXISTS check_anniversary_exists();

-- Remove table (careful - loses data!)
DROP TABLE IF EXISTS important_dates;

-- Remove milestone types
DROP TABLE IF EXISTS milestone_types;
```

### Data Preservation
Before rollback, export data:
```sql
COPY important_dates TO '/tmp/important_dates_backup.csv' CSV HEADER;
```

## Future Expansions

The schema is designed to accommodate:

1. **More Milestone Types** - Just add to milestone_types
2. **Attachments** - Add `attachment_url` column
3. **Shared by Both** - Add `shared_by_partner` boolean
4. **Notification Settings** - Add `notification_days_before` integer
5. **Anniversary History** - Create `important_dates_history` table

## Schema Version

**Version:** 1.0.0
**Created:** 2026-01-25
**Last Updated:** 2026-01-25
**Status:** ✅ Production Ready
