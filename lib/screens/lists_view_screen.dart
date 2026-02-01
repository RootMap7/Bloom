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
          .select('partner_id')
          .eq('id', user.id)
          .maybeSingle();

      final partnerId = userProfile?['partner_id'] as String?;
      _partnerId = partnerId;

      if (partnerId != null) {
        final partnerProfile = await SupabaseService.client
            .from('user_profiles')
            .select('partner_pet_name, username')
            .eq('id', partnerId)
            .maybeSingle();

        final petName = partnerProfile?['partner_pet_name'] as String?;
        final username = partnerProfile?['username'] as String?;

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
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
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
            const SizedBox(height: 20),
            _buildFilterOption('All', 'all'),
            _buildFilterOption('Added by $_partnerPetName', 'partner'),
            _buildFilterOption('Fulfilled', 'completed'),
            if (_currentListType == ListType.wishList)
              _buildFilterOption('Surprises', 'surprise'),
            _buildFilterOption('Just for Me', 'private'),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            Text(
              'Sort',
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            _buildSortOption('Newest First', 'created_at_desc'),
            _buildSortOption('Oldest First', 'created_at_asc'),
            const SizedBox(height: 20),
          ],
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
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8F6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _currentListType == ListType.wishList ? 'Wish List' : 'Bucket List',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Toggle buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _currentListType == ListType.wishList
                            ? const Color(0xFF7C3ABA)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _currentListType == ListType.wishList
                              ? const Color(0xFF7C3ABA)
                              : const Color(0xFFE5E5E5),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.card_giftcard,
                            color: _currentListType == ListType.wishList
                                ? Colors.white
                                : const Color(0xFF9CA3AF),
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
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _currentListType == ListType.bucketList
                            ? const Color(0xFF7C3ABA)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _currentListType == ListType.bucketList
                              ? const Color(0xFF7C3ABA)
                              : const Color(0xFFE5E5E5),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: _currentListType == ListType.bucketList
                                ? Colors.white
                                : const Color(0xFF9CA3AF),
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
                                  : const Color(0xFF9CA3AF),
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
          const SizedBox(height: 20),
          // Filter bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
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
                  onTap: _showFilterSheet,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.tune,
                      color: Color(0xFF7C3ABA),
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Divider(color: Color(0xFFE5E5E5)),
          ),
          const SizedBox(height: 16),
          // Items list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF7C3ABA),
                    ),
                  )
                : items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _currentListType == ListType.wishList
                                  ? Icons.card_giftcard
                                  : Icons.check_circle_outline,
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
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _buildItemCard(item);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(dynamic item) {
    final user = SupabaseService.currentUser;
    final isOwnItem = user != null && item.userId == user.id;
    
    String categoryLabel = '';
    if (item is BucketListItem) {
      categoryLabel = item.categoryName ?? 'Bucket list item';
    } else if (item is WishListItem) {
      categoryLabel = item.categoryName ?? 'Wish list item';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _parseHexColor(item.themeColor),
        borderRadius: BorderRadius.circular(24),
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
                        color: Colors.black.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      style: GoogleFonts.manrope(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // User avatar placeholder
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isOwnItem ? const Color(0xFF7C3ABA) : const Color(0xFF4D4B4B),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    isOwnItem ? 'Me' : _partnerPetName.substring(0, 1).toUpperCase(),
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Added: ${_formatDate(item.createdAt)}',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}
