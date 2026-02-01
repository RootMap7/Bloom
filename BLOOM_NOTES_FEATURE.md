# Bloom Notes Feature Implementation

## Overview
A new feature that allows partners to send short, ephemeral notes to each other. Notes expire after 24 hours and can be liked by the recipient.

## Features Implemented

### 1. Database Schema
**Table: `bloom_notes`**
- Stores notes sent between partners
- Automatically expires after 24 hours
- Tracks like status and timestamp
- Row-level security policies ensure only partners can access notes

**Columns:**
- `id` (UUID) - Primary key
- `couple_id` (UUID) - References the couple
- `sender_id` (UUID) - User who sent the note
- `recipient_id` (UUID) - User receiving the note
- `message` (TEXT) - The note content
- `is_liked` (BOOLEAN) - Whether recipient liked the note
- `liked_at` (TIMESTAMP) - When the note was liked
- `expires_at` (TIMESTAMP) - Expiration time (24 hours from creation)
- `created_at` (TIMESTAMP) - Creation timestamp

### 2. Model Layer
**File:** `lib/models/bloom_note.dart`
- `BloomNote` class with all properties
- Factory method `fromMap()` for database deserialization
- `toMap()` method for database serialization
- Helper property `isExpired` to check if note has expired

### 3. Service Layer
**File:** `lib/services/bloom_note_service.dart`
- `sendNote()` - Send a note to partner
- `getActiveNote()` - Get current non-expired note for logged-in user
- `likeNote()` - Like a received note
- `unlikeNote()` - Unlike a note
- `getRecentlyLikedNoteSentByMe()` - Check for liked notes to trigger notifications

### 4. UI Components

#### Send Bloom Note Modal
**File:** `lib/widgets/send_bloom_note_modal.dart`
- Beautiful modal with partner's name in header
- Text input with Caveat font (handwriting style, 20px)
- Character limit of 250 characters
- Send button with **share.svg** icon
- Success state showing confirmation with **shared.svg** icon in purple circle
- Smooth transition between compose and success states

#### Note Display Card (Home Screen)
- Gradient purple card design (gradient from `#9B6DD6` to `#7C3ABA`)
- Light purple inner container (`#DCC4F5`) with rounded corners
- Displays note message **centered** in Caveat font (24px)
- Heart icon positioned **below the note box** (right-aligned, no border)
- Menu button (three dots) with delete option in top-right
- Heart is white outline when not liked, filled red (`#FF3B30`) when liked
- **Cannot unlike** - heart becomes non-interactive after liking
- Only shows if note exists and hasn't expired

### 5. Home Screen Integration
**File:** `lib/screens/home_screen.dart`

**Changes:**
1. Added "Send a Bloom Note" option to the floating action button popup menu
2. Added note display card between welcome section and upcoming plans
3. Updated welcome message when note is present: "Here's to another shared day."
4. Added like functionality (one-time only, cannot unlike)
5. Added **animated top banner notification** when partner likes your note
6. Created `_NotificationBanner` widget with smooth slide and fade animations

### 6. Notifications Screen Integration
**File:** `lib/screens/notifications_screen.dart`

**Changes:**
1. Now loads **real notifications** from database instead of static data
2. Shows notification when partner sends a note
3. Shows notification when partner likes your note
4. Uses **partner's pet name** in all notifications for personalization
5. Empty state when no notifications
6. Loading state while fetching data
7. Dynamic time labels (e.g., "Just now", "2h ago", "Yesterday")

### 6. Notification System
- When a user logs in and their partner has liked their note, they see a notification
- **Animated banner notification at the top** with smooth slide-down animation
- Uses gradient purple background with shadow
- Message includes **partner's pet name**: "{Partner Name} liked your note"
- Duration: 4 seconds with smooth slide-up exit animation
- **Also appears in Notifications screen** with real-time data
- All notifications use partner's pet name for personalization

## User Flow

### Sending a Note
1. User taps the floating action button (+) on home screen
2. Selects "Send a Bloom Note"
3. Modal appears with text input
4. User types message (max 250 characters) in handwriting-style font
5. Taps "Share Note" button
6. Success screen appears
7. Note is sent to partner and expires in 24 hours

### Receiving a Note
1. Partner logs in or refreshes home screen
2. Note card appears below welcome message
3. Welcome message changes to "Here's to another shared day."
4. Partner can read the note in handwriting-style font
5. Partner can tap heart icon to like the note
6. Heart turns red when liked

### Like Notification
1. When sender logs in after their note was liked
2. **Animated purple notification banner slides down from top**
3. Shows "{Partner's Pet Name} liked your note" with heart icon
4. Smooth entrance and exit animations
5. Also appears in Notifications screen

## Design Details

### Colors
- Primary Purple: `#7C3ABA`
- Light Purple (Gradient): `#9B6DD6`
- Note Background: `#DCC4F5`
- Like Button Red: `#FF3B30`
- White (for heart outline): `#FFFFFF`

### Animations
- **Notification Banner**: 500ms slide-down with cubic ease-out curve
- **Fade In**: Opacity from 0 to 1 with ease-in curve
- **Exit Animation**: Starts at 3.5s, reverses slide and fade
- Total display time: 4 seconds

### Typography
- Note text display: Caveat font, 24px, weight 500, centered
- Note text input: Caveat font, 20px, weight 500
- Headers: Manrope font (existing app style)
- Notification text: Manrope font, 15px, weight 600

### Note Expiration
- Notes expire 24 hours after creation
- Expired notes are automatically filtered out
- Database function `delete_expired_bloom_notes()` available for cleanup

## Security
- Row Level Security (RLS) policies ensure:
  - Users can only view notes sent to them or by them
  - Users can only send notes to their connected partner
  - Users can only like notes sent to them
  - All operations require couple_id verification

## Database Migration
To apply the new schema, run the updated `supabase_schema.sql` file in your Supabase SQL editor.

## Font Note
The feature uses **Caveat** font from Google Fonts as a substitute for Bradley Hand, since Bradley Hand is not available through Google Fonts. Caveat provides a similar handwriting aesthetic at 20px (slightly larger than requested 16px for better readability).

If you prefer to use the actual Bradley Hand font, you would need to:
1. Add the font file to `assets/fonts/`
2. Update `pubspec.yaml` to include the font
3. Replace `GoogleFonts.caveat()` with `TextStyle(fontFamily: 'Bradley Hand')`

## Testing Checklist
- [ ] Run database migration
- [ ] Test sending a note
- [ ] Test receiving a note (check home screen display)
- [ ] Test liking a note (verify cannot unlike)
- [ ] Test top notification animation when note is liked
- [ ] Test notification appears in Notifications screen
- [ ] Verify partner's pet name appears in notifications
- [ ] Test note expiration after 24 hours
- [ ] Test with both partners connected
- [ ] Test error handling when not connected
- [ ] Test empty state in Notifications screen
- [ ] Verify welcome message changes when note is present

## Future Enhancements
- Push notifications for received notes (currently in-app only)
- Note history/archive (before 24h expiration)
- Different note styles or themes
- Emoji support in notes
- Daily note reminders
- Mark notifications as read
- Delete individual notifications
- Notification badges on home screen
