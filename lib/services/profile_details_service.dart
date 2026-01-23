import 'package:flutter/foundation.dart';
import '../models/interest.dart';
import '../models/love_language.dart';
import '../models/receive_care_option.dart';
import '../models/profile_details.dart';
import '../config/app_constants.dart';
import 'supabase_service.dart';

class ProfileDetailsService {
  static List<Interest>? _interestsCache;

  static Future<List<Interest>> fetchAllAvailableInterests({bool forceRefresh = false}) async {
    if (!forceRefresh && _interestsCache != null) {
      _fetchInterestsFromDb();
      return _interestsCache!;
    }
    return _fetchInterestsFromDb();
  }

  static Future<List<Interest>> _fetchInterestsFromDb() async {
    try {
      final response = await SupabaseService.client
          .from('interests')
          .select('id, category, vibe_color, name, created_at')
          .order('category', ascending: true);
      
      _interestsCache = (response as List).map((m) => Interest.fromMap(m as Map<String, dynamic>)).toList();
      return _interestsCache!;
    } catch (e) {
      debugPrint('Error fetching all available interests: $e');
      return _interestsCache ?? [];
    }
  }

  static Future<List<LoveLanguage>> fetchAllLoveLanguages() async {
    return AppConstants.loveLanguages;
  }

  static Future<List<ReceiveCareOption>> fetchAllReceiveCareOptions() async {
    return AppConstants.receiveCareOptions;
  }

  static Future<List<Interest>> fetchUserSelectedInterests({String? userId}) async {
    final effectiveUserId = userId ?? SupabaseService.currentUser?.id;
    if (effectiveUserId == null) return [];

    try {
      final response = await SupabaseService.client
          .from('user_selected_interests')
          .select('interests (id, category, vibe_color, name, created_at)')
          .eq('user_id', effectiveUserId);

      return (response as List)
          .map((m) {
            final interestData = m['interests'];
            if (interestData == null) return null;
            return Interest.fromMap(interestData as Map<String, dynamic>);
          })
          .whereType<Interest>()
          .toList();
    } catch (e) {
      debugPrint('Error fetching user selected interests: $e');
      return [];
    }
  }

  static Future<ProfileDetails?> fetchProfileDetails({String? userId}) async {
    final effectiveUserId = userId ?? SupabaseService.currentUser?.id;
    if (effectiveUserId == null) return null;

    final response = await SupabaseService.client
        .from('user_profile_details')
        .select('user_id, birthday_date, short_note, interests, love_language, care_preferences')
        .eq('user_id', effectiveUserId)
        .maybeSingle();

    if (response == null) return null;
    return ProfileDetails.fromMap(response as Map<String, dynamic>);
  }

  static Future<void> saveProfileDetails({
    DateTime? birthdayDate,
    String? shortNote,
    String? interests,
    List<String>? selectedInterestIds,
    String? loveLanguage,
    String? carePreferences,
  }) async {
    final user = SupabaseService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final data = {
      'user_id': user.id,
      'birthday_date': birthdayDate?.toIso8601String(),
      'short_note': _normalize(shortNote),
      'interests': _normalize(interests),
      'love_language': _normalize(loveLanguage),
      'care_preferences': _normalize(carePreferences),
      'updated_at': DateTime.now().toIso8601String(),
    };

    await SupabaseService.client
        .from('user_profile_details')
        .upsert(data);

    if (selectedInterestIds != null) {
      // First delete existing selections
      await SupabaseService.client
          .from('user_selected_interests')
          .delete()
          .eq('user_id', user.id);

      // Then insert new ones
      if (selectedInterestIds.isNotEmpty) {
        final selectionData = selectedInterestIds.map((id) => {
          'user_id': user.id,
          'interest_id': id,
        }).toList();

        await SupabaseService.client
            .from('user_selected_interests')
            .insert(selectionData);
      }
    }
  }

  static Future<void> savePartnerPetName(String petName) async {
    final user = SupabaseService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await SupabaseService.client
        .from('user_profiles')
        .update({'partner_pet_name': petName})
        .eq('id', user.id);
  }

  static String? _normalize(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
