import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';
import '../services/onboarding_service.dart';
import '../services/bucket_list_service.dart';
import '../services/wish_list_service.dart';
import '../models/bucket_list_item.dart';
import '../models/wish_list_item.dart';
import '../widgets/couple_avatar.dart';
import '../widgets/partner_connected_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'add_bucket_list_item_screen.dart';
import 'add_wish_list_item_screen.dart';
import 'add_plan_screen.dart';
import 'individual_profile_screen.dart';
import 'notifications_screen.dart';
import 'our_bloom_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String? _inviteCode;
  String? _username;
  String? _profileImageUrl;
  String? _partnerId;
  String? _partnerProfileImageUrl;
  bool _showShareCode = true;
  final List<_PlanItem> _upcomingPlans = [];
  List<BucketListItem> _recentBucketListItems = [];
  List<WishListItem> _recentWishListItems = [];
  final List<TextEditingController> _codeControllers =
      List.generate(5, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(5, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Load data in background without showing loader
  }

  @override
  void dispose() {
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) {
        return;
      }

      final response = await SupabaseService.client
          .from('user_profiles')
          .select('username, profile_image_url, invite_code, partner_id')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _username = response['username'] as String?;
          _profileImageUrl = SupabaseService.getOptimizedImageUrl(response['profile_image_url'] as String?);
          _inviteCode = response['invite_code'] as String?;
          _partnerId = response['partner_id'] as String?;
        });
        
        // Load partner profile image if partner exists
        if (_partnerId != null) {
          _loadPartnerProfile();
        }

        _loadUpcomingPlans();
        _loadRecentItems();
      } else {
        final code = await OnboardingService.getInviteCode();
        setState(() {
          _inviteCode = code;
        });
      }
    } catch (e) {
      try {
        final code = await OnboardingService.getInviteCode();
        setState(() {
          _inviteCode = code;
        });
      } catch (e2) {
        // Silently fail, UI will show with default values
      }
    }
  }

  Future<void> _loadPartnerProfile() async {
    final partnerId = _partnerId;
    if (partnerId == null) return;
    
    try {
      final partnerResponse = await SupabaseService.client
          .from('user_profiles')
          .select('profile_image_url')
          .eq('id', partnerId)
          .maybeSingle();
      
      if (partnerResponse != null && mounted) {
        setState(() {
          _partnerProfileImageUrl = SupabaseService.getOptimizedImageUrl(partnerResponse['profile_image_url'] as String?);
        });
      }
    } catch (e) {
      // Silently fail, partner image will show placeholder
    }
  }

  Future<void> _loadUpcomingPlans() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    try {
      final partnerId = _partnerId;
      final now = DateTime.now().toIso8601String();
      final baseQuery = SupabaseService.client
          .from('plans')
          .select('plan_title, location, theme_color, plan_date_time')
          .gte('plan_date_time', now);
      final response = await ((partnerId != null && partnerId.isNotEmpty)
              ? baseQuery.or(
                  'user_id.eq.${user.id},user_id.eq.$partnerId',
                )
              : baseQuery.eq('user_id', user.id))
          .order('plan_date_time', ascending: true)
          .limit(2);

      if (mounted) {
        setState(() {
          _upcomingPlans
            ..clear()
            ..addAll(
              (response as List<dynamic>)
                  .map((item) => _PlanItem.fromMap(item as Map<String, dynamic>))
                  .where((item) => item.planDateTime != null),
            );
        });
      }
    } catch (e) {
      // Silently fail, upcoming list will be empty
    }
  }

  Future<void> _loadRecentItems() async {
    try {
      final bucketItems = await BucketListService.fetchRecentItems();
      final wishItems = await WishListService.fetchRecentItems();
      
      if (mounted) {
        setState(() {
          _recentBucketListItems = bucketItems;
          _recentWishListItems = wishItems;
        });
      }
    } catch (e) {
      debugPrint('Error loading recent items: $e');
    }
  }

  Future<void> _copyCode() async {
    if (_inviteCode != null) {
      await Clipboard.setData(ClipboardData(text: _inviteCode!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invite code copied to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _shareCode() async {
    if (_inviteCode != null) {
      final text = 'Join me on Bloom! Use my invite code: $_inviteCode';
      final uri = Uri.parse('sms:?body=${Uri.encodeComponent(text)}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _copyCode();
      }
    }
  }

  Future<void> _connectWithCode() async {
    final enteredCode = _codeControllers.map((c) => c.text).join('').toUpperCase();
    
    if (enteredCode.length != 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 5-character code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final result = await OnboardingService.connectPartner(enteredCode);
      
      if (result['success'] == true) {
        await OnboardingService.completeOnboarding();
        await _loadUserData();
        final partnerName = await _getPartnerName(result['partner_id'] as String?);

        if (!mounted) return;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => PartnerConnectedDialog(
            partnerName: partnerName,
            onPrimaryPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const OurBloomScreen(),
                ),
              );
            },
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Invalid invite code'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error connecting: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String> _getPartnerName(String? partnerId) async {
    if (partnerId == null) return 'your partner';
    try {
      final response = await SupabaseService.client
          .from('user_profiles')
          .select('username')
          .eq('id', partnerId)
          .maybeSingle();
      final name = response?['username'] as String?;
      if (name != null && name.trim().isNotEmpty) {
        return name;
      }
    } catch (_) {
      // Ignore and use fallback
    }
    return 'your partner';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFFFF8F6),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Top section
                _buildTopSection(),
                const SizedBox(height: 24),
                // Partner connection card
                if (_partnerId == null) _buildPartnerConnectionCard(),
                if (_partnerId == null) const SizedBox(height: 24),
                // Welcome section
                _buildWelcomeSection(),
                const SizedBox(height: 24),
                _buildUpcomingPlansCard(),
                const SizedBox(height: 16),
                // Bucketlist card
                _buildBucketlistCard(),
                const SizedBox(height: 16),
                // Wishlist card
                _buildWishlistCard(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildTopSection() {
    return Row(
      children: [
        CoupleAvatar(
          userProfileImageUrl: _profileImageUrl,
          partnerProfileImageUrl: _partnerProfileImageUrl,
          hasPartner: _partnerId != null,
          size: 49,
          onUserTap: () {
            // Navigate to Our Bloom profile page
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const OurBloomScreen()),
            );
          },
          onPartnerTap: () {
            // Navigate to Our Bloom profile page
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const OurBloomScreen()),
            );
          },
        ),
        const Spacer(),
        // Calendar and notification icons
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: SvgPicture.asset(
            'assets/images/calendar.svg',
            width: 20,
            height: 20,
            fit: BoxFit.scaleDown,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationsScreen()),
            );
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              'assets/images/notifications.svg',
              width: 20,
              height: 20,
              fit: BoxFit.scaleDown,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      children: [
        Text(
          'Hi, lets get blooming!',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF000000),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Start anywhere. Scroll to add plans, bucket lists, and wishlists — or share your code to begin together.',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.normal,
            color: const Color(0xFF4D4B4B),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingPlansCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F0FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calendar_today_outlined,
                    size: 18, color: Color(0xFF7C3ABA)),
              ),
              const SizedBox(width: 10),
              Text(
                'Upcoming',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4D4B4B),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddPlanScreen()),
                  ).then((_) => _loadUpcomingPlans());
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4F0FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Color(0xFF7C3ABA), size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_upcomingPlans.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No upcoming plans yet.',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: const Color(0xFF8E8A8A),
                ),
              ),
            )
          else
            Column(
              children: _upcomingPlans
                  .map((plan) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _buildUpcomingPlanRow(plan),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildUpcomingPlanRow(_PlanItem plan) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 48,
          decoration: BoxDecoration(
            color: plan.themeColor,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plan.title,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F1F1F),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                plan.location,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF7B7575),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              plan.dateLabel,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4D4B4B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              plan.timeLabel,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF7B7575),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPartnerConnectionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Tabs
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showShareCode = true;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _showShareCode
                          ? const Color(0xFF7C3ABA)
                          : const Color(0xFFE9D5FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Share your code',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: _showShareCode
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: _showShareCode
                            ? Colors.white
                            : const Color(0xFF4D4B4B),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showShareCode = false;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !_showShareCode
                          ? const Color(0xFF7C3ABA)
                          : const Color(0xFFE9D5FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Enter your partner\'s code',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: !_showShareCode
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: !_showShareCode
                            ? Colors.white
                            : const Color(0xFF4D4B4B),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Content
          if (_showShareCode)
            _buildShareCodeContent()
          else
            _buildEnterCodeContent(),
        ],
      ),
    );
  }

  Widget _buildShareCodeContent() {
    return Column(
      children: [
        // Code display - wrapped to prevent overflow
        LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_inviteCode != null)
                    ..._inviteCode!.split('').map((char) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Container(
                            width: 48,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                char,
                                style: GoogleFonts.manrope(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF000000),
                                ),
                              ),
                            ),
                          ),
                        )),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _copyCode,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.copy,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        // Share button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _shareCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3ABA),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.share, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Share my invite code',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnterCodeContent() {
    return Column(
      children: [
        Text(
          'Enter code here',
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: const Color(0xFF4D4B4B),
          ),
        ),
        const SizedBox(height: 12),
        // Code inputs - wrapped to prevent overflow
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: SizedBox(
                  width: 48,
                  height: 56,
                  child: TextField(
                    controller: _codeControllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    textCapitalization: TextCapitalization.characters,
                    style: GoogleFonts.manrope(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF000000),
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 4) {
                        _focusNodes[index + 1].requestFocus();
                      } else if (value.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                    },
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 20),
        // Connect button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _connectWithCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3ABA),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Connect',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBucketlistCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shopping_bag_outlined,
                    size: 18, color: Color(0xFF22C55E)),
              ),
              const SizedBox(width: 10),
              Text(
                'Bucketlist - Recently Added',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4D4B4B),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddBucketListItemScreen()),
                  ).then((_) => _loadRecentItems());
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0FDF4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Color(0xFF22C55E), size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_recentBucketListItems.isEmpty)
            _buildHorizontalEmptyState('bucket-list items')
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _recentBucketListItems.map((item) {
                  return _buildHorizontalItemCard(
                    title: item.title,
                    subtitle: item.targetDate != null
                        ? 'Added ${_formatDate(item.createdAt)}\n${_formatDate(item.targetDate!)}'
                        : 'Added ${_formatDate(item.createdAt)}\nNo Due Date',
                    color: _parseHexColor(item.themeColor),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWishlistCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.favorite_outline,
                    size: 18, color: Color(0xFFF97316)),
              ),
              const SizedBox(width: 10),
              Text(
                'Wishlist - Recently Added',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4D4B4B),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddWishListItemScreen()),
                  ).then((_) => _loadRecentItems());
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF7ED),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Color(0xFFF97316), size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_recentWishListItems.isEmpty)
            _buildHorizontalEmptyState('wish-list items')
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _recentWishListItems.map((item) {
                  return _buildHorizontalItemCard(
                    title: item.title,
                    subtitle: 'Added ${_formatDate(item.createdAt)}\n${item.categoryName ?? 'Category name'}',
                    color: _parseHexColor(item.themeColor),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHorizontalEmptyState(String itemType) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          'Tap + to add your first $itemType.',
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: const Color(0xFF8E8A8A),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalItemCard({
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      width: 160,
      height: 180,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
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

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  Color _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFFC8A8E9);
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFFC8A8E9);
    }
  }

  void _showShortcutMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.event, color: Color(0xFF7C3ABA)),
              title: Text(
                'Add Plan',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddPlanScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline, color: Color(0xFF7C3ABA)),
              title: Text(
                'Add to Bucket List',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddBucketListItemScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite_outline, color: Color(0xFF7C3ABA)),
              title: Text(
                'Add to Wish List',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddWishListItemScreen()),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 18), // 18px above bottom nav
      child: FloatingActionButton(
        onPressed: () {
          _showShortcutMenu(context);
        },
        backgroundColor: const Color(0xFF7C3ABA),
        shape: const CircleBorder(),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, 'assets/images/home-icon.svg', 'Home'),
              _buildNavItem(1, 'assets/images/goal.svg', 'Heart'),
              _buildNavItem(2, 'assets/images/bloom-menuicon.png', 'Flower'),
              _buildNavItem(3, 'assets/images/bucketlist-icon.png', 'Bucket'),
              _buildNavItem(4, 'assets/images/profile-icon.svg', 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String iconPath, String label) {
    final isActive = _currentIndex == index;
    final color = isActive ? const Color(0xFF7C3ABA) : const Color(0xFF4D4B4B);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isActive)
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3ABA),
              borderRadius: BorderRadius.circular(2),
            ),
          )
        else
          const SizedBox(height: 3),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () {
            if (index == 4) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const IndividualProfileScreen()),
              );
              return;
            }
            setState(() {
              _currentIndex = index;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: iconPath.endsWith('.svg')
                ? SvgPicture.asset(
                    iconPath,
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      color,
                      BlendMode.srcIn,
                    ),
                  )
                : ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      color,
                      BlendMode.srcIn,
                    ),
                    child: Image.asset(
                      iconPath,
                      width: 24,
                      height: 24,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _PlanItem {
  const _PlanItem({
    required this.title,
    required this.location,
    required this.planDateTime,
    required this.themeColor,
  });

  final String title;
  final String location;
  final DateTime? planDateTime;
  final Color themeColor;

  String get dateLabel {
    final dateTime = planDateTime;
    if (dateTime == null) return '';
    return '${_monthLabel(dateTime.month)} ${dateTime.day}';
  }

  String get timeLabel {
    final dateTime = planDateTime;
    if (dateTime == null) return '';
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$hour12:$minute $suffix';
  }

  static _PlanItem fromMap(Map<String, dynamic> map) {
    final dateValue = map['plan_date_time'];
    DateTime? parsed;
    if (dateValue is String) {
      parsed = DateTime.tryParse(dateValue);
    }
    return _PlanItem(
      title: map['plan_title'] as String? ?? 'Untitled plan',
      location: map['location'] as String? ?? 'Location pending',
      planDateTime: parsed,
      themeColor: _colorFromHex(map['theme_color'] as String?),
    );
  }

  static Color _colorFromHex(String? hex) {
    switch (hex) {
      case '#6EB4FF':
        return const Color(0xFF6EB4FF);
      case '#F4D100':
        return const Color(0xFFF4D100);
      case '#FFB7C3':
        return const Color(0xFFFFB7C3);
      case '#C8A8E9':
        return const Color(0xFFC8A8E9);
      default:
        return const Color(0xFFC8A8E9);
    }
  }

  static String _monthLabel(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[(month - 1).clamp(0, 11)];
  }
}
