import 'package:flutter/foundation.dart';
import '../models/bucket_list_category.dart';
import '../models/bucket_list_collection.dart';
import '../models/bucket_list_item.dart';
import '../config/app_constants.dart';
import 'supabase_service.dart';

class BucketListService {
  static List<BucketListItem>? _recentItemsCache;
  static List<BucketListCollection>? _collectionsCache;

  static Future<List<BucketListCategory>> fetchCategories() async {
    // Return from local constants to avoid DB calls
    return AppConstants.categories;
  }

  static Future<List<BucketListCollection>> fetchCollections({bool forceRefresh = false}) async {
    final user = SupabaseService.currentUser;
    if (user == null) return [];

    if (!forceRefresh && _collectionsCache != null) {
      // Background refresh (Stale-While-Revalidate)
      _fetchCollectionsFromDb(user.id);
      return _collectionsCache!;
    }

    return _fetchCollectionsFromDb(user.id);
  }

  static Future<List<BucketListCollection>> _fetchCollectionsFromDb(String userId) async {
    try {
      final response = await SupabaseService.client
          .from('bucket_list_collections')
          .select('id, user_id, name, created_at')
          .eq('user_id', userId)
          .order('name');
      
      _collectionsCache = (response as List).map((m) => BucketListCollection.fromMap(m)).toList();
      return _collectionsCache!;
    } catch (e) {
      debugPrint('Error fetching bucket list collections: $e');
      return _collectionsCache ?? [];
    }
  }

  static Future<BucketListCollection> addCollection(String name) async {
    final user = SupabaseService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final response = await SupabaseService.client
          .from('bucket_list_collections')
          .insert({
            'user_id': user.id,
            'name': name,
          })
          .select('id, user_id, name, created_at')
          .single();
      
      final newCollection = BucketListCollection.fromMap(response);
      _collectionsCache?.add(newCollection);
      return newCollection;
    } catch (e) {
      debugPrint('Error adding collection: $e');
      rethrow;
    }
  }

  static Future<void> addBucketListItem({
    required String title,
    DateTime? targetDate,
    String? categoryId,
    String? collection,
    String? notes,
    String? links,
    String? themeColor,
    bool isPrivate = false,
  }) async {
    final user = SupabaseService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await SupabaseService.client.from('bucket_list_items').insert({
        'user_id': user.id,
        'title': title,
        'target_date': targetDate?.toIso8601String(),
        'category_id': categoryId,
        'collection': collection,
        'notes': notes,
        'links': links,
        'theme_color': themeColor,
        'is_private': isPrivate,
      });
      // Invalidate cache
      _recentItemsCache = null;
    } catch (e) {
      debugPrint('Error adding bucket list item: $e');
      rethrow;
    }
  }

  static Future<List<BucketListItem>> fetchRecentItems({bool forceRefresh = false}) async {
    final user = SupabaseService.currentUser;
    if (user == null) return [];

    if (!forceRefresh && _recentItemsCache != null) {
      // Background refresh (Stale-While-Revalidate)
      _fetchRecentItemsFromDb(user.id);
      return _recentItemsCache!;
    }

    return _fetchRecentItemsFromDb(user.id);
  }

  static Future<List<BucketListItem>> _fetchRecentItemsFromDb(String userId) async {
    try {
      final response = await SupabaseService.client
          .from('bucket_list_items')
          .select('id, user_id, title, target_date, category_id, collection, notes, links, theme_color, is_private, is_completed, created_at, bucket_list_categories(name)')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(10);
      
      _recentItemsCache = (response as List).map((m) => BucketListItem.fromMap(m)).toList();
      return _recentItemsCache!;
    } catch (e) {
      debugPrint('Error fetching recent bucket list items: $e');
      return _recentItemsCache ?? [];
    }
  }
}
