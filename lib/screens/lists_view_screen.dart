import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/bucket_list_service.dart';
import '../services/wish_list_service.dart';
import '../services/supabase_service.dart';
import '../models/bucket_list_item.dart';
import '../models/wish_list_item.dart';

enum ListType { wishList, bucketList }

class ListsViewScreen extends StatefulWidget {
  final ListType initialListType;

  const ListsViewScreen({
    super.key,
    this.initialListType = ListType.wishList,
  });

  @override
  State<ListsViewScreen> createState() => _ListsViewScreenState();
}

class _ListsViewScreenState extends State<ListsViewScreen> {
  late ListType _currentListType;
  String _selectedFilter = 'all';
  String _selectedSort = 'created_at_desc';
  bool _isLoading = true;
  List<BucketListItem> _bucketListItems = [];
  List<WishListItem> _wishListItems = [];
  String _partnerPetName = 'Partner';
  String? _partnerId;
  Map<String, String?> _userProfileImages = {};

  @override
  void initState() {
    super.initState();
    _currentListType = widget.initialListType;
    _loadPartnerInfo();
    _loadItems();
  }

  Future<void> _loadPartnerInfo() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    try {
      final userProfile = await SupabaseService.client
          .from('user_profiles')
          .select('partner_id, profile_image_url')
          .eq('id', user.id)
          .maybeSingle();

      final partnerId = userProfile?['partner_id'] as String?;
      final userProfileImage = userProfile?['profile_image_url'] as String?;
      
      _partnerId = partnerId;
      _userProfileImages[user.id] = userProfileImage;

      if (partnerId != null) {
        final partnerProfile = await SupabaseService.client
            .from('user_profiles')
            .select('partner_pet_name, username, profile_image_url')
            .eq('id', partnerId)
            .maybeSingle();

        final petName = partnerProfile?['partner_pet_name'] as String?;
        final username = partnerProfile?['username'] as String?;
        final partnerProfileImage = partnerProfile?['profile_image_url'] as String?;

        _userProfileImages[partnerId] = partnerProfileImage;

        if (mounted) {
          setState(() {
            _partnerPetName = petName?.isNotEmpty == true
                ? petName!
                : (username?.isNotEmpty == true ? username! : 'Partner');
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading partner info: $e');
    }
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_currentListType == ListType.bucketList) {
        final items = await BucketListService.fetchAllItems();
        if (mounted) {
          setState(() {
            _bucketListItems = items;
            _isLoading = false;
          });
        }
      } else {
        final items = await WishListService.fetchAllItems();
        if (mounted) {
          setState(() {
            _wishListItems = items;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading items: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshItems() async {
    try {
      if (_currentListType == ListType.bucketList) {
        final items = await BucketListService.fetchAllItems();
        if (mounted) {
          setState(() {
            _bucketListItems = items;
          });
        }
      } else {
        final items = await WishListService.fetchAllItems();
        if (mounted) {
          setState(() {
            _wishListItems = items;
          });
        }
      }
    } catch (e) {
      debugPrint('Error refreshing items: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to refresh items'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  List<dynamic> get _filteredAndSortedItems {
    final user = SupabaseService.currentUser;
    if (user == null) return [];

    List<dynamic> items = _currentListType == ListType.bucketList
        ? _bucketListItems
        : _wishListItems;

    // Apply filters
    switch (_selectedFilter) {
      case 'partner':
        items = items.where((item) => item.userId == _partnerId).toList();
        break;
      case 'completed':
        items = items.where((item) => item.isCompleted).toList();
        break;
      case 'surprise':
        if (_currentListType == ListType.wishList) {
          items = items.where((item) => (item as WishListItem).isSurprise).toList();
        }
        break;
      case 'private':
        items = items.where((item) => item.isPrivate).toList();
        break;
      case 'all':
      default:
        // Show all items (both user's and partner's non-private items)
        break;
    }

    // Apply sorting
    items.sort((a, b) {
      if (_selectedSort == 'created_at_desc') {
        return b.createdAt.compareTo(a.createdAt);
      } else {
        return a.createdAt.compareTo(b.createdAt);
      }
    });

    return items;
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter',
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                _buildFilterOption('All', 'all'),
                _buildFilterOption('Added by $_partnerPetName', 'partner'),
                _buildFilterOption('Fulfilled', 'completed'),
                if (_currentListType == ListType.wishList)
                  _buildFilterOption('Surprises', 'surprise'),
                _buildFilterOption('Just for Me', 'private'),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Sort',
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSortOption('Newest First', 'created_at_desc'),
                _buildSortOption('Oldest First', 'created_at_asc'),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOption(String label, String value) {
    final isSelected = _selectedFilter == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? const Color(0xFF7C3ABA) : Colors.grey,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? const Color(0xFF7C3ABA) : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String label, String value) {
    final isSelected = _selectedSort == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedSort = value;
        });
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? const Color(0xFF7C3ABA) : Colors.grey,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? const Color(0xFF7C3ABA) : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFilterLabel() {
    switch (_selectedFilter) {
      case 'partner':
        return 'Added by $_partnerPetName';
      case 'completed':
        return 'Fulfilled';
      case 'surprise':
        return 'Surprises';
      case 'private':
        return 'Just for Me';
      case 'all':
      default:
        return 'All';
    }
  }

  Color _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFFF4D100);
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFFF4D100);
    }
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day}-${months[date.month - 1]}-${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredAndSortedItems;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Toggle buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentListType = ListType.wishList;
                            _selectedFilter = 'all';
                          });
                          _loadItems();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _currentListType == ListType.wishList
                                ? const Color(0xFF7C3ABA)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.card_giftcard,
                                color: _currentListType == ListType.wishList
                                    ? Colors.white
                                    : const Color(0xFFCBD5E1),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Wish List',
                                style: GoogleFonts.manrope(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _currentListType == ListType.wishList
                                      ? Colors.white
                                      : const Color(0xFFCBD5E1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentListType = ListType.bucketList;
                            _selectedFilter = 'all';
                          });
                          _loadItems();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _currentListType == ListType.bucketList
                                ? const Color(0xFF7C3ABA)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.format_list_bulleted,
                                color: _currentListType == ListType.bucketList
                                    ? Colors.white
                                    : const Color(0xFFCBD5E1),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Bucket List',
                                style: GoogleFonts.manrope(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _currentListType == ListType.bucketList
                                      ? Colors.white
                                      : const Color(0xFFCBD5E1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Filter bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    _getFilterLabel(),
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      // Toggle sort direction
                      setState(() {
                        _selectedSort = _selectedSort == 'created_at_desc' 
                            ? 'created_at_asc' 
                            : 'created_at_desc';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        _selectedSort == 'created_at_desc'
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _showFilterSheet,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      child: const Icon(
                        Icons.tune,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Items list
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF7C3ABA),
                      ),
                    )
                  : items.isEmpty
                      ? RefreshIndicator(
                          onRefresh: _refreshItems,
                          color: const Color(0xFF7C3ABA),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height * 0.6,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _currentListType == ListType.wishList
                                          ? Icons.card_giftcard
                                          : Icons.format_list_bulleted,
                                      size: 80,
                                      color: Colors.grey[300],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No items found',
                                      style: GoogleFonts.manrope(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Add your first ${_currentListType == ListType.wishList ? 'wish' : 'goal'}!',
                                      style: GoogleFonts.manrope(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _refreshItems,
                          color: const Color(0xFF7C3ABA),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return _buildItemCard(item);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(dynamic item) {
    final user = SupabaseService.currentUser;
    final isOwnItem = user != null && item.userId == user.id;
    final profileImageUrl = _userProfileImages[item.userId];
    
    String categoryLabel = '';
    if (item is BucketListItem) {
      categoryLabel = item.categoryName ?? 'Bucket list item';
    } else if (item is WishListItem) {
      categoryLabel = item.categoryName ?? 'Wish list item';
    }

    return GestureDetector(
      onLongPress: () => _showItemOptions(context, item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _parseHexColor(item.themeColor),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryLabel,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black.withOpacity(0.55),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.title,
                        style: GoogleFonts.manrope(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // User avatar with profile picture
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isOwnItem ? const Color(0xFF7C3ABA) : const Color(0xFF4D4B4B),
                    shape: BoxShape.circle,
                    image: profileImageUrl != null && profileImageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(profileImageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: profileImageUrl == null || profileImageUrl.isEmpty
                      ? Center(
                          child: Text(
                            isOwnItem ? 'Me' : _partnerPetName.substring(0, 1).toUpperCase(),
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Added: ${_formatDate(item.createdAt)}',
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black.withOpacity(0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showItemOptions(BuildContext context, dynamic item) {
    final user = SupabaseService.currentUser;
    final isOwnItem = user != null && item.userId == user.id;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOptionItem(
              icon: Icons.edit_outlined,
              label: 'Edit',
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to edit screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit functionality coming soon')),
                );
              },
            ),
            _buildOptionItem(
              icon: Icons.bookmark_border,
              label: 'Add to collection',
              onTap: () {
                Navigator.pop(context);
                // TODO: Show collection picker
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add to collection functionality coming soon')),
                );
              },
            ),
            _buildOptionItem(
              icon: Icons.check_circle_outline,
              label: item.isCompleted ? 'Mark as not done' : 'Mark as done',
              onTap: () async {
                Navigator.pop(context);
                await _toggleCompleteStatus(item);
              },
            ),
            const Divider(height: 1, color: Color(0xFFE5E5E5)),
            _buildOptionItem(
              icon: Icons.delete_outline,
              label: 'Delete',
              textColor: const Color(0xFFEF4444),
              iconColor: const Color(0xFFEF4444),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, item);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor ?? Colors.black,
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColor ?? Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleCompleteStatus(dynamic item) async {
    try {
      if (_currentListType == ListType.bucketList) {
        await SupabaseService.client
            .from('bucket_list_items')
            .update({'is_completed': !item.isCompleted})
            .eq('id', item.id);
      } else {
        await SupabaseService.client
            .from('wish_list_items')
            .update({'is_completed': !item.isCompleted})
            .eq('id', item.id);
      }
      await _loadItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(item.isCompleted ? 'Marked as not done' : 'Marked as done!'),
            backgroundColor: const Color(0xFF7C3ABA),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling complete status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update item'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _confirmDelete(BuildContext context, dynamic item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Item?',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${item.title}"? This action cannot be undone.',
          style: GoogleFonts.manrope(
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteItem(item);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFEF4444),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(dynamic item) async {
    try {
      if (_currentListType == ListType.bucketList) {
        await SupabaseService.client
            .from('bucket_list_items')
            .delete()
            .eq('id', item.id);
      } else {
        await SupabaseService.client
            .from('wish_list_items')
            .delete()
            .eq('id', item.id);
      }
      await _loadItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item deleted successfully'),
            backgroundColor: Color(0xFF7C3ABA),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete item'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }
}
