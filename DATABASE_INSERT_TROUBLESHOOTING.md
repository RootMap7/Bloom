# Database Insert Troubleshooting Guide

## Quick Check: Are Items Being Saved?

### 1. Check Supabase Dashboard
1. Go to your Supabase project dashboard
2. Navigate to **Table Editor**
3. Select `wish_list_items` table
4. Check if any rows exist
5. Select `bucket_list_items` table
6. Check if any rows exist

### 2. Check Authentication
Run this in your Flutter app to verify the user is logged in:

```dart
final user = SupabaseService.currentUser;
print('Current User ID: ${user?.id}');
print('Is Logged In: ${SupabaseService.isLoggedIn}');
```

### 3. Test Insert Directly
Add this temporary code to test if inserts work:

```dart
// Test direct insert
try {
  final user = SupabaseService.currentUser;
  print('Testing insert for user: ${user?.id}');
  
  final result = await SupabaseService.client
    .from('wish_list_items')
    .insert({
      'user_id': user!.id,
      'title': 'Test Item',
      'theme_color': '#FFB7C3',
      'is_surprise': false,
      'wish_for': 'Me',
      'is_private': false,
    })
    .select();
    
  print('Insert successful: $result');
} catch (e, stackTrace) {
  print('Insert failed: $e');
  print('Stack trace: $stackTrace');
}
```

## Common Issues

### Issue 1: User Not Authenticated
**Symptom:** `user == null` in the service
**Solution:** Ensure user is logged in before adding items

### Issue 2: RLS Policy Blocking Insert
**Symptom:** Silent failure or "new row violates row-level security policy"
**Solution:** Check RLS policies in Supabase

**Required Policy:**
```sql
CREATE POLICY "Users can insert own wish list items"
  ON wish_list_items FOR INSERT
  WITH CHECK (auth.uid() = user_id);
```

### Issue 3: Missing Required Fields
**Symptom:** "null value in column violates not-null constraint"
**Solution:** Ensure all required fields are provided

**Required fields:**
- `user_id` (UUID)
- `title` (TEXT)

### Issue 4: Category ID Invalid
**Symptom:** "foreign key constraint fails"
**Solution:** Either:
- Pass `null` for category_id
- Use a valid category ID from `bucket_list_categories` table

## Debugging Steps

### Step 1: Enable Detailed Logging
Add this to your service methods:

```dart
static Future<void> addWishListItem({...}) async {
  final user = SupabaseService.currentUser;
  
  print('DEBUG: Starting addWishListItem');
  print('DEBUG: User ID: ${user?.id}');
  print('DEBUG: Title: $title');
  print('DEBUG: Category ID: $categoryId');
  
  if (user == null) {
    print('ERROR: User not authenticated!');
    throw Exception('User not authenticated');
  }

  try {
    print('DEBUG: Attempting insert...');
    
    final data = {
      'user_id': user.id,
      'title': title,
      'category_id': categoryId,
      'notes': notes,
      'links': links,
      'theme_color': themeColor,
      'is_surprise': isSurprise,
      'wish_for': wishFor,
      'is_private': isPrivate,
    };
    
    print('DEBUG: Insert data: $data');
    
    await SupabaseService.client.from('wish_list_items').insert(data);
    
    print('DEBUG: Insert successful!');
    _recentItemsCache = null;
  } catch (e, stackTrace) {
    print('ERROR: Failed to add wish list item');
    print('ERROR: Exception: $e');
    print('ERROR: Stack trace: $stackTrace');
    rethrow;
  }
}
```

### Step 2: Check Database Directly
1. Open Supabase SQL Editor
2. Run this query:

```sql
-- Check if table exists and has data
SELECT COUNT(*) FROM wish_list_items;

-- Check RLS policies
SELECT * FROM pg_policies WHERE tablename = 'wish_list_items';

-- Try to insert directly (replace with your user ID)
INSERT INTO wish_list_items (user_id, title, theme_color, is_surprise, wish_for, is_private)
VALUES ('YOUR_USER_ID_HERE', 'Test Item', '#FFB7C3', false, 'Me', false);
```

### Step 3: Verify Network Requests
1. Open Flutter DevTools
2. Navigate to Network tab
3. Add an item
4. Look for POST request to `/rest/v1/wish_list_items`
5. Check response status code:
   - **201**: Success
   - **400**: Bad request (check request body)
   - **403**: Permission denied (RLS issue)
   - **500**: Server error (database constraint issue)

## Quick Fix Checklist

- [ ] User is authenticated (`SupabaseService.currentUser` is not null)
- [ ] RLS policies are enabled on tables
- [ ] INSERT policy exists for authenticated users
- [ ] Required fields (user_id, title) are provided
- [ ] Category ID is either null or valid UUID
- [ ] No console errors showing up
- [ ] Supabase project is active (not paused)
- [ ] Internet connection is working

## Still Not Working?

If items still aren't being saved after checking all above:

1. **Check Supabase Project Status:** Ensure your project isn't paused
2. **Check API Keys:** Verify your anon key is correct
3. **Check Table Permissions:** Ensure RLS is properly configured
4. **Check Logs:** Look at Supabase logs in dashboard under "Logs" section

## Getting Help

Include this information when asking for help:
1. Flutter app console output (especially ERROR and DEBUG lines)
2. Supabase logs from dashboard
3. Network request/response from DevTools
4. Current RLS policies (from SQL query above)
