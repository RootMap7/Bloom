# Lists View Feature

## Overview
A comprehensive viewing page for both Wish Lists and Bucket Lists with toggle switching, filtering, and sorting capabilities.

## Features Implemented

### 1. Toggle Between Lists
- **Wish List** and **Bucket List** toggle buttons at the top
- Purple highlight on selected list
- Icon + text for each option
- Switches data and resets filters when toggled

### 2. Filter Options
Dynamic filters that adapt based on list type:

**Common Filters:**
- `All` - Shows all items (user's + partner's non-private)
- `Added by {Partner_Pet_Name}` - Shows only partner's items
- `Fulfilled` - Shows completed items only
- `Just for Me` - Shows private items only

**Wish List Only:**
- `Surprises` - Shows items marked as surprise

### 3. Sort Options
- `Newest First` (default) - Sorts by creation date descending
- `Oldest First` - Sorts by creation date ascending

### 4. Item Cards
Beautiful cards matching the design with:
- Color-coded background (from theme_color)
- Category label at top
- Large title text
- "Added:" timestamp
- User avatar (shows "Me" for own items, partner's initial for partner items)

## Usage

### Navigation
To navigate to the Lists View screen from anywhere in the app:

```dart
// Navigate to Wish List
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const ListsViewScreen(
      initialListType: ListType.wishList,
    ),
  ),
);

// Navigate to Bucket List
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const ListsViewScreen(
      initialListType: ListType.bucketList,
    ),
  ),
);
```

### Example Integration in Home Screen
You can add navigation buttons to the home screen's bucket list and wish list cards:

```dart
// In home_screen.dart, wrap the cards with GestureDetector
GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ListsViewScreen(
          initialListType: ListType.wishList,
        ),
      ),
    );
  },
  child: _buildWishlistCard(),
),
```

## File Structure

### New Files
- `lib/screens/lists_view_screen.dart` - Main view screen with toggle, filters, and list display

### Updated Files
- `lib/services/bucket_list_service.dart` - Added `fetchAllItems()` method
- `lib/services/wish_list_service.dart` - Added `fetchAllItems()` method

## API Methods

### BucketListService
```dart
static Future<List<BucketListItem>> fetchAllItems()
```
Fetches all bucket list items for the user and their partner's non-private items.

### WishListService
```dart
static Future<List<WishListItem>> fetchAllItems()
```
Fetches all wish list items for the user and their partner's non-private items.

## Filter Logic

### Filter Application
1. **All** - No filtering, shows everything user has access to
2. **Partner** - Filters by `userId == partnerId`
3. **Fulfilled** - Filters by `isCompleted == true`
4. **Surprises** (Wish List only) - Filters by `isSurprise == true`
5. **Private** - Filters by `isPrivate == true`

### Sort Application
- Newest First: `ORDER BY created_at DESC`
- Oldest First: `ORDER BY created_at ASC`

## Design Details

### Colors
- Selected toggle: `#7C3ABA` (purple)
- Unselected toggle: `#9CA3AF` (gray)
- Card backgrounds: Dynamic based on `theme_color`
- Filter icon: `#7C3ABA`

### Typography
- Screen title: Manrope 20px, weight 700
- Toggle text: Manrope 15px, weight 600
- Filter label: Manrope 16px, weight 600
- Category label: Manrope 13px, weight 500
- Item title: Manrope 24px, weight 700
- Timestamp: Manrope 13px, weight 500

### Layout
- Top padding: 16px
- Card margin: 16px bottom
- Card padding: 20px all sides
- Card border radius: 24px
- Toggle border radius: 16px

## Empty States
- Shows icon (gift for wish list, check circle for bucket list)
- Message: "No items found"
- Subtitle: "Add your first wish/goal!"

## Loading States
- Circular progress indicator in center
- Purple color (`#7C3ABA`)

## Partner Pet Name
- Dynamically loads partner's pet name from database
- Falls back to username if pet name not set
- Falls back to "Partner" if neither available
- Updates filter label automatically: "Added by {name}"

## Avatar Display
- Own items: Shows "Me" in purple circle
- Partner items: Shows first letter of partner's name in gray circle
- Size: 44x44px
- Font: Manrope 16px, weight 700

## Future Enhancements
- Pull to refresh
- Infinite scroll/pagination for large lists
- Item detail view on tap
- Mark as complete/fulfilled action
- Edit item functionality
- Delete item functionality
- Share items with partner
- Add photos to items
- Set reminders for items
