# Supabase Setup Guide for Bloom

## Step 1: Create a Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Sign up or log in
3. Click "New Project"
4. Fill in your project details:
   - Name: Bloom (or your preferred name)
   - Database Password: Choose a strong password
   - Region: Choose the closest region to your users
5. Click "Create new project"

## Step 2: Get Your Supabase Credentials

1. In your Supabase project dashboard, go to **Settings** → **API**
2. Copy the following values:
   - **Project URL** (under "Project URL")
   - **anon/public key** (under "Project API keys")

## Step 3: Configure the App

1. Open `lib/config/supabase_config.dart`
2. Replace `YOUR_SUPABASE_URL` with your Project URL
3. Replace `YOUR_SUPABASE_ANON_KEY` with your anon/public key

Example:
```dart
static const String supabaseUrl = 'https://your-project-id.supabase.co';
static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

## Step 4: Set Up Authentication

Supabase automatically provides:
- User registration and login
- Password hashing and security
- Email verification (optional)
- Password reset functionality
- OAuth providers (Google, Apple, etc.)

### Enable Email Authentication

1. Go to **Authentication** → **Providers** in your Supabase dashboard
2. Make sure **Email** is enabled
3. Configure email templates if needed

### Enable OAuth Providers (Optional)

#### Google OAuth:
1. Go to **Authentication** → **Providers** → **Google**
2. Enable Google provider
3. Add your Google OAuth credentials:
   - Client ID
   - Client Secret
4. Add authorized redirect URLs:
   - `io.supabase.bloom://login-callback/`

#### Apple OAuth:
1. Go to **Authentication** → **Providers** → **Apple**
2. Enable Apple provider
3. Add your Apple OAuth credentials
4. Add authorized redirect URLs:
   - `io.supabase.bloom://login-callback/`

## Step 5: Database Schema (Optional)

If you need to store additional user data beyond what Supabase Auth provides, you can create custom tables:

### Example: User Profiles Table

```sql
-- Run this in Supabase SQL Editor
CREATE TABLE user_profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT,
  full_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Create policy to allow users to read their own profile
CREATE POLICY "Users can view own profile"
  ON user_profiles FOR SELECT
  USING (auth.uid() = id);

-- Create policy to allow users to update their own profile
CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  USING (auth.uid() = id);
```

## Step 6: Install Dependencies

Run:
```bash
flutter pub get
```

## Step 7: Test the Integration

The app is now configured to use Supabase for authentication. You can test:
- User registration (Sign Up screen)
- User login (Login screen)
- Password reset (Forgot Password link)
- OAuth login (Google/Apple buttons)

## Security Notes

- Never commit your `.env` file or `supabase_config.dart` with real credentials to version control
- The anon key is safe to use in client-side code (it's public)
- Supabase handles password hashing automatically
- All authentication is handled securely by Supabase

## Additional Resources

- [Supabase Flutter Documentation](https://supabase.com/docs/reference/dart/introduction)
- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Supabase Database Documentation](https://supabase.com/docs/guides/database)


