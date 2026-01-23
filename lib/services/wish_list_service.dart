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
    if (user == null) throw Exception('User not authenticated');

    try {
      await SupabaseService.client.from('wish_list_items').insert({
        'user_id': user.id,
        'title': title,
        'category_id': categoryId,
        'notes': notes,
        'links': links,
        'theme_color': themeColor,
        'is_surprise': isSurprise,
        'wish_for': wishFor,
        'is_private': isPrivate,
      });
      // Invalidate cache
      _recentItemsCache = null;
    } catch (e) {
      debugPrint('Error adding wish list item: $e');
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
}
