import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postgrest/postgrest.dart';
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
      // Profile doesn't exist, create it with a unique invite code
      await _insertProfileWithUniqueCode(
        user: user,
        username: username,
        imageUrl: imageUrl,
      );
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

  /// Uploads a profile image and updates the user's profile.
  static Future<String?> uploadProfileImage(File profileImage) async {
    final user = SupabaseService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final fileExtension = profileImage.path.split('.').last;
    final fileName = '${user.id}/profile.$fileExtension';

    await SupabaseService.client.storage
        .from('profile-images')
        .upload(
          fileName,
          profileImage,
          fileOptions: FileOptions(
            upsert: true,
            contentType: 'image/$fileExtension',
          ),
        );

    final imageUrl = SupabaseService.client.storage
        .from('profile-images')
        .getPublicUrl(fileName);

    await SupabaseService.client
        .from('user_profiles')
        .update({'profile_image_url': imageUrl})
        .eq('id', user.id);

    return imageUrl;
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
      // Profile doesn't exist, create it with a unique invite code
      await _insertProfileWithUniqueCode(
        user: user,
        experienceLevel: experienceLevel,
      );
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
      // Profile doesn't exist, create it with a unique invite code
      await _insertProfileWithUniqueCode(
        user: user,
        ageRange: ageRange,
      );
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

    return _normalizeConnectPartnerResponse(response);
  }

  static Map<String, dynamic> _normalizeConnectPartnerResponse(
    dynamic response,
  ) {
    dynamic data = response;
    if (response is PostgrestResponse) {
      data = response.data;
    }

    if (data is Map<String, dynamic>) return data;

    if (data is List && data.isNotEmpty && data.first is Map<String, dynamic>) {
      return Map<String, dynamic>.from(data.first as Map<String, dynamic>);
    }

    if (data is String && data.isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {
        // Fall through to error response below
      }
    }

    return {
      'success': false,
      'message': 'Unexpected response from server. Please try again.',
    };
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
        // Profile doesn't exist, create it with a unique invite code
        await _insertProfileWithUniqueCode(user: user);
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
        // Profile doesn't exist, create it with a unique invite code
        await _insertProfileWithUniqueCode(user: user);
        return await getInviteCode();
      }

      return response['invite_code'] as String?;
    } catch (e) {
      try {
        await _insertProfileWithUniqueCode(user: user);
        final retryResponse = await SupabaseService.client
            .from('user_profiles')
            .select('invite_code')
            .eq('id', user.id)
            .maybeSingle();
        if (retryResponse != null && retryResponse['invite_code'] != null) {
          return retryResponse['invite_code'] as String?;
        }
      } catch (_) {
        // Ignore and fall through to null
      }
      return null;
    }
  }

  static Future<String> _fetchUniqueInviteCode() async {
    try {
      final response =
          await SupabaseService.client.rpc('generate_unique_invite_code');
      if (response is String && response.isNotEmpty) {
        return response;
      }
    } catch (_) {
      // Fallback to local generator if RPC fails
    }
    return CodeGenerator.generateCode();
  }

  static Future<void> _insertProfileWithUniqueCode({
    required User user,
    String? username,
    String? experienceLevel,
    String? ageRange,
    String? imageUrl,
  }) async {
    const maxAttempts = 5;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final inviteCode = await _fetchUniqueInviteCode();
      try {
        await SupabaseService.client.from('user_profiles').insert({
          'id': user.id,
          'email': user.email ?? '',
          'invite_code': inviteCode,
          if (username != null) 'username': username,
          if (experienceLevel != null) 'experience_level': experienceLevel,
          if (ageRange != null) 'age_range': ageRange,
          if (imageUrl != null) 'profile_image_url': imageUrl,
          'onboarding_completed': false,
        });
        return;
      } catch (error) {
        if (error is PostgrestException &&
            error.code == '23505' &&
            (error.message.contains('invite_code') ||
                error.details?.toString().contains('invite_code') == true)) {
          if (attempt == maxAttempts - 1) rethrow;
          continue;
        }
        rethrow;
      }
    }
  }
}

