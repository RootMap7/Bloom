import 'package:flutter/foundation.dart';
import '../models/wish_list_item.dart';
import 'supabase_service.dart';

class WishListService {
  static List<WishListItem>? _recentItemsCache;

  static Future<void> addWishListItem({
    required String title,
    String? categoryId,
    String? notes,
    String? links,
    String? themeColor,
    bool isSurprise = false,
    String wishFor = 'Me',
    bool isPrivate = false,
  }) async {
    final user = SupabaseService.currentUser;
    
    debugPrint('🔍 WishListService.addWishListItem called');
    debugPrint('📝 Title: $title');
    debugPrint('👤 User ID: ${user?.id}');
    debugPrint('🎨 Theme Color: $themeColor');
    debugPrint('🏷️ Category ID: $categoryId');
    
    if (user == null) {
      debugPrint('❌ ERROR: User not authenticated!');
      throw Exception('User not authenticated');
    }

    try {
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
      
      debugPrint('📤 Inserting data: $data');
      
      await SupabaseService.client.from('wish_list_items').insert(data);
      
      debugPrint('✅ Wish list item added successfully!');
      // Invalidate cache
      _recentItemsCache = null;
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR adding wish list item: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<List<WishListItem>> fetchRecentItems({bool forceRefresh = false}) async {
    final user = SupabaseService.currentUser;
    if (user == null) return [];

    if (!forceRefresh && _recentItemsCache != null) {
      // Background refresh (Stale-While-Revalidate)
      _fetchRecentItemsFromDb(user.id);
      return _recentItemsCache!;
    }

    return _fetchRecentItemsFromDb(user.id);
  }

  static Future<List<WishListItem>> _fetchRecentItemsFromDb(String userId) async {
    try {
      final response = await SupabaseService.client
          .from('wish_list_items')
          .select('id, user_id, title, category_id, notes, links, theme_color, is_surprise, wish_for, is_private, is_completed, created_at, bucket_list_categories(name)')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(10);
      
      _recentItemsCache = (response as List).map((m) => WishListItem.fromMap(m)).toList();
      return _recentItemsCache!;
    } catch (e) {
      debugPrint('Error fetching recent wish list items: $e');
      return _recentItemsCache ?? [];
    }
  }

  static Future<List<WishListItem>> fetchAllItems() async {
    final user = SupabaseService.currentUser;
    if (user == null) return [];

    try {
      // Get user's partner_id
      final userProfile = await SupabaseService.client
          .from('user_profiles')
          .select('partner_id')
          .eq('id', user.id)
          .maybeSingle();

      final partnerId = userProfile?['partner_id'] as String?;

      // Fetch user's items and partner's non-private items
      final response = await SupabaseService.client
          .from('wish_list_items')
          .select('id, user_id, title, category_id, notes, links, theme_color, is_surprise, wish_for, is_private, is_completed, created_at, bucket_list_categories(name)')
          .or('user_id.eq.${user.id}${partnerId != null ? ',and(user_id.eq.$partnerId,is_private.eq.false)' : ''}')
          .order('created_at', ascending: false);

      return (response as List).map((m) => WishListItem.fromMap(m)).toList();
    } catch (e) {
      debugPrint('Error fetching all wish list items: $e');
      return [];
    }
  }
}
