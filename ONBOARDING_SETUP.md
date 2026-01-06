# Onboarding Setup Guide

This document explains the onboarding flow and how to set up the database.

## Onboarding Flow

The onboarding consists of 5 screens in order:

1. **Username Screen** (`lib/screens/onboarding/username_screen.dart`)
   - User creates a username
   - User can upload a profile picture
   - Progress: 1/5 (20%)

2. **Interests Screen** (`lib/screens/onboarding/interests_screen.dart`)
   - User selects one or more interests:
     - Stay connected
     - Plan things together
     - Track shared goals
     - Share Bucket-lists and wish-lists
     - Navigate a long-distance relationship
   - Progress: 2/5 (40%)

3. **Experience Screen** (`lib/screens/onboarding/experience_screen.dart`)
   - User selects experience level:
     - First time using something like this
     - I've tried similar apps
   - Progress: 3/5 (60%)

4. **Age Range Screen** (`lib/screens/onboarding/age_range_screen.dart`)
   - User selects age range:
     - 18-24
     - 25-34
     - 35-44
     - 45+
   - Progress: 4/5 (80%)

5. **Connect Partner Screen** (`lib/screens/onboarding/connect_partner_screen.dart`)
   - User sees their unique 5-character invite code
   - User can share their code or enter partner's code
   - User can skip and connect later
   - Progress: 5/5 (100%)

## Database Setup

### Step 1: Run SQL Schema

1. Go to your Supabase project dashboard
2. Navigate to SQL Editor
3. Copy and paste the contents of `supabase_schema.sql`
4. Run the SQL script

This will create:
- `user_profiles` table - stores user onboarding data
- `user_interests` table - stores user interests (many-to-many)
- Storage bucket `profile-images` for profile pictures
- RLS policies for security
- Functions for invite code generation and partner connection
- Triggers for automatic profile creation and invite code generation

### Step 2: Storage Bucket Setup

The SQL script automatically creates the `profile-images` storage bucket. If you need to create it manually:

1. Go to Storage in Supabase dashboard
2. Create a new bucket named `profile-images`
3. Set it to public
4. Add the storage policies from the SQL file

## User Flow

### After Sign Up:
1. User signs up → Email confirmation sheet appears
2. User clicks "Go to Login" → Navigates to Username Screen (first onboarding step)
3. User completes all onboarding screens
4. User connects with partner (or skips)
5. User reaches Home Screen

### After Login:
1. User logs in
2. System checks if onboarding is completed
3. If completed → Navigate to Home Screen
4. If not completed → Navigate to Username Screen (first onboarding step)

## Invite Code Generation

- Each user gets a unique 5-character alphanumeric code (A-Z, 0-9)
- Code is generated automatically when user profile is created (via trigger)
- Code is stored in `user_profiles.invite_code`
- Code is permanent and unique

## Partner Connection

- Users can connect by entering each other's invite codes
- The `connect_partners()` function validates and connects partners
- Both users' `partner_id` fields are updated
- Both users' `partner_invite_code` fields store the code used to connect

## Data Storage

All onboarding data is saved to Supabase as users progress:
- Username and profile image → Saved on Username Screen
- Interests → Saved on Interests Screen
- Experience level → Saved on Experience Screen
- Age range → Saved on Age Range Screen
- Partner connection → Saved on Connect Partner Screen
- Onboarding completion flag → Set when partner connects or user skips

## Files Created

### Screens:
- `lib/screens/onboarding/username_screen.dart`
- `lib/screens/onboarding/interests_screen.dart`
- `lib/screens/onboarding/experience_screen.dart`
- `lib/screens/onboarding/age_range_screen.dart`
- `lib/screens/onboarding/connect_partner_screen.dart`

### Services:
- `lib/services/onboarding_service.dart` - Handles all onboarding data operations

### Utils:
- `lib/utils/code_generator.dart` - Generates and validates invite codes

### Database:
- `supabase_schema.sql` - Complete database schema

## Dependencies Added

- `image_picker: ^1.0.7` - For profile picture upload
- `shared_preferences: ^2.2.2` - Already added
- `url_launcher: ^6.2.4` - Already added

## Notes

- All screens use the same radial gradient background as sign up/login screens
- Progress bar shows completion percentage at the top of each screen
- Data is saved incrementally as users progress through onboarding
- Users can skip partner connection and complete it later
- Invite codes are generated server-side to ensure uniqueness

