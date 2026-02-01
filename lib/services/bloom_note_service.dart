import 'package:flutter/foundation.dart';
import '../models/bloom_note.dart';
import 'supabase_service.dart';

class BloomNoteService {
  /// Send a bloom note to partner
  static Future<void> sendNote({
    required String message,
  }) async {
    final user = SupabaseService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Get user's couple_id and partner_id
      final userProfile = await SupabaseService.client
          .from('user_profiles')
          .select('couple_id, partner_id')
          .eq('id', user.id)
          .maybeSingle();

      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      final coupleId = userProfile['couple_id'] as String?;
      final partnerId = userProfile['partner_id'] as String?;

      if (coupleId == null || partnerId == null) {
        throw Exception('You must be connected with a partner to send notes');
      }

      // Calculate expiration time (24 hours from now)
      final expiresAt = DateTime.now().add(const Duration(hours: 24));

      // Insert the note
      await SupabaseService.client.from('bloom_notes').insert({
        'couple_id': coupleId,
        'sender_id': user.id,
        'recipient_id': partnerId,
        'message': message,
        'expires_at': expiresAt.toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error sending bloom note: $e');
      rethrow;
    }
  }

  /// Get the current active note for the logged-in user
  static Future<BloomNote?> getActiveNote() async {
    final user = SupabaseService.currentUser;
    if (user == null) return null;

    try {
      final now = DateTime.now().toIso8601String();
      
      // Get note sent TO this user that hasn't expired yet
      final response = await SupabaseService.client
          .from('bloom_notes')
          .select('*')
          .eq('recipient_id', user.id)
          .gt('expires_at', now)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        return BloomNote.fromMap(response);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching active note: $e');
      return null;
    }
  }

  /// Like a bloom note
  static Future<void> likeNote(String noteId) async {
    final user = SupabaseService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await SupabaseService.client
          .from('bloom_notes')
          .update({
            'is_liked': true,
            'liked_at': DateTime.now().toIso8601String(),
          })
          .eq('id', noteId)
          .eq('recipient_id', user.id); // Ensure user is the recipient
    } catch (e) {
      debugPrint('Error liking note: $e');
      rethrow;
    }
  }

  /// Unlike a bloom note
  static Future<void> unlikeNote(String noteId) async {
    final user = SupabaseService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await SupabaseService.client
          .from('bloom_notes')
          .update({
            'is_liked': false,
            'liked_at': null,
          })
          .eq('id', noteId)
          .eq('recipient_id', user.id); // Ensure user is the recipient
    } catch (e) {
      debugPrint('Error unliking note: $e');
      rethrow;
    }
  }

  /// Check if user has received a liked note notification
  /// This checks if the logged-in user sent a note that was liked
  static Future<BloomNote?> getRecentlyLikedNoteSentByMe() async {
    final user = SupabaseService.currentUser;
    if (user == null) return null;

    try {
      // Get notes sent BY this user that were recently liked
      final response = await SupabaseService.client
          .from('bloom_notes')
          .select('*')
          .eq('sender_id', user.id)
          .eq('is_liked', true)
          .not('liked_at', 'is', null)
          .order('liked_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        return BloomNote.fromMap(response);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching liked note: $e');
      return null;
    }
  }
}
