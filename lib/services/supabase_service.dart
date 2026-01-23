import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  // Initialize Supabase
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  // Get optimized image URL using Supabase Storage CDN transformations
  static String? getOptimizedImageUrl(String? url, {int width = 200, int height = 200}) {
    if (url == null || url.isEmpty) return null;
    if (!url.contains('storage/v1/object/public/')) return url;
    
    // Replace object/public with render/image/public and add query params
    return url.replaceFirst('storage/v1/object/public/', 'storage/v1/render/image/public/') + 
           '?width=$width&height=$height&resize=cover';
  }

  // Check if user is logged in
  static bool get isLoggedIn => client.auth.currentUser != null;

  // Get current user
  static User? get currentUser => client.auth.currentUser;

  // Sign up with email and password
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
    );
  }

  // Sign in with email and password
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign out
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // Sign in with Google
  static Future<bool> signInWithGoogle() async {
    return await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'com.kev.bloom.app://login-callback/',
    );
  }

  // Sign in with Apple
  static Future<bool> signInWithApple() async {
    return await client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'com.kev.bloom.app://login-callback/',
    );
  }

  // Reset password
  static Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  // Update password
  static Future<UserResponse> updatePassword(String newPassword) async {
    return await client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
}

