import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../utils/code_generator.dart';
import 'dart:io';

class OnboardingService {
  /// Save username and profile image
  static Future<void> saveUsername({
    required String username,
    File? profileImage,
  }) async {
    final user = SupabaseService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    String? imageUrl;
    
    // Upload profile image if provided
    if (profileImage != null) {
      final fileExtension = profileImage.path.split('.').last;
      final fileName = '${user.id}/profile.$fileExtension';
      
      await SupabaseService.client.storage
          .from('profile-images')
          .upload(fileName, profileImage, fileOptions: FileOptions(
            upsert: true,
            contentType: 'image/$fileExtension',
          ));
      
      imageUrl = SupabaseService.client.storage
          .from('profile-images')
          .getPublicUrl(fileName);
    }

    // Update or insert user profile (upsert)
    // First check if profile exists
    final existingProfile = await SupabaseService.client
        .from('user_profiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();

    if (existingProfile == null) {
      // Profile doesn't exist, create it with invite code
      final inviteCode = CodeGenerator.generateCode();
      await SupabaseService.client
          .from('user_profiles')
          .insert({
            'id': user.id,
            'email': user.email ?? '',
            'username': username,
            'invite_code': inviteCode,
            if (imageUrl != null) 'profile_image_url': imageUrl,
            'onboarding_completed': false,
          });
    } else {
      // Profile exists, update it
      await SupabaseService.client
          .from('user_profiles')
          .update({
            'username': username,
            if (imageUrl != null) 'profile_image_url': imageUrl,
          })
          .eq('id', user.id);
    }
  }

  /// Save user interests
  static Future<void> saveInterests(List<String> interests) async {
    final user = SupabaseService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Delete existing interests
    await SupabaseService.client
        .from('user_interests')
        .delete()
        .eq('user_id', user.id);

    // Insert new interests
    if (interests.isNotEmpty) {
      await SupabaseService.client
          .from('user_interests')
          .insert(
            interests.map((interest) => {
              'user_id': user.id,
              'interest': interest,
            }).toList(),
          );
    }
  }

  /// Save experience level
  static Future<void> saveExperienceLevel(String experienceLevel) async {
    final user = SupabaseService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Check if profile exists
    final existingProfile = await SupabaseService.client
        .from('user_profiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();

    if (existingProfile == null) {
      // Profile doesn't exist, create it
      final inviteCode = CodeGenerator.generateCode();
      await SupabaseService.client
          .from('user_profiles')
          .insert({
            'id': user.id,
            'email': user.email ?? '',
            'invite_code': inviteCode,
            'experience_level': experienceLevel,
            'onboarding_completed': false,
          });
    } else {
      // Profile exists, update it
      await SupabaseService.client
          .from('user_profiles')
          .update({
            'experience_level': experienceLevel,
          })
          .eq('id', user.id);
    }
  }

  /// Save age range
  static Future<void> saveAgeRange(String ageRange) async {
    final user = SupabaseService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Check if profile exists
    final existingProfile = await SupabaseService.client
        .from('user_profiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();

    if (existingProfile == null) {
      // Profile doesn't exist, create it
      final inviteCode = CodeGenerator.generateCode();
      await SupabaseService.client
          .from('user_profiles')
          .insert({
            'id': user.id,
            'email': user.email ?? '',
            'invite_code': inviteCode,
            'age_range': ageRange,
            'onboarding_completed': false,
          });
    } else {
      // Profile exists, update it
      await SupabaseService.client
          .from('user_profiles')
          .update({
            'age_range': ageRange,
          })
          .eq('id', user.id);
    }
  }

  /// Connect with partner using invite code
  static Future<Map<String, dynamic>> connectPartner(String inviteCode) async {
    final user = SupabaseService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await SupabaseService.client.rpc(
      'connect_partners',
      params: {'invite_code_param': inviteCode.toUpperCase()},
    );

    return response as Map<String, dynamic>;
  }

  /// Mark onboarding as completed
  static Future<void> completeOnboarding() async {
    final user = SupabaseService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await SupabaseService.client
        .from('user_profiles')
        .update({
          'onboarding_completed': true,
        })
        .eq('id', user.id);
  }

  /// Check if user has completed onboarding
  static Future<bool> hasCompletedOnboarding() async {
    final user = SupabaseService.currentUser;
    if (user == null) return false;

    try {
      final response = await SupabaseService.client
          .from('user_profiles')
          .select('onboarding_completed')
          .eq('id', user.id)
          .maybeSingle();

      // If profile doesn't exist, create it with invite code
      if (response == null) {
        // Profile doesn't exist, create it
        final inviteCode = CodeGenerator.generateCode();
        await SupabaseService.client
            .from('user_profiles')
            .insert({
              'id': user.id,
              'email': user.email,
              'invite_code': inviteCode,
              'onboarding_completed': false,
            });
        return false;
      }

      return response['onboarding_completed'] ?? false;
    } catch (e) {
      // If there's an error, assume onboarding is not completed
      return false;
    }
  }

  /// Get user's invite code
  static Future<String?> getInviteCode() async {
    final user = SupabaseService.currentUser;
    if (user == null) return null;

    try {
      final response = await SupabaseService.client
          .from('user_profiles')
          .select('invite_code')
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        // Profile doesn't exist, create it with invite code
        final inviteCode = CodeGenerator.generateCode();
        await SupabaseService.client
            .from('user_profiles')
            .insert({
              'id': user.id,
              'email': user.email,
              'invite_code': inviteCode,
              'onboarding_completed': false,
            });
        return inviteCode;
      }

      return response['invite_code'] as String?;
    } catch (e) {
      // If error, generate a code and return it
      return CodeGenerator.generateCode();
    }
  }
}

