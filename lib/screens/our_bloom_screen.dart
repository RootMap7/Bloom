import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';
import '../services/streak_service.dart';
import '../widgets/couple_avatar.dart';
import '../widgets/pet_name_modal.dart';
import '../widgets/add_anniversary_modal.dart';
import '../widgets/add_important_date_modal.dart';
import 'individual_profile_screen.dart';

class OurBloomScreen extends StatefulWidget {
  const OurBloomScreen({super.key});

  @override
  State<OurBloomScreen> createState() => _OurBloomScreenState();
}

class _OurBloomScreenState extends State<OurBloomScreen> {
  String? _username;
  String? _profileImageUrl;
  String? _partnerId;
  String? _partnerUsername;
  String? _partnerProfileImageUrl;
  DateTime? _relationshipStartDate;
  String? _coupleId;
  bool _hasAnniversaryDate = false;
  int _bucketListCount = 0;
  int _wishListCount = 0;
  int _plansCount = 0;
  int _bloomNotesCount = 0;
  int _streakDays = 0;
  List<bool> _weeklyStreak = List.filled(7, false);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    try {
      final response = await SupabaseService.client
          .from('user_profiles')
          .select('username, profile_image_url, partner_id')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        _username = response?['username'] as String?;
        _profileImageUrl = SupabaseService.getOptimizedImageUrl(response?['profile_image_url'] as String?, width: 260, height: 260);
        _partnerId = response?['partner_id'] as String?;
      });

      if (_partnerId != null) {
        await Future.wait([
          _loadPartnerProfile(_partnerId!),
          _loadRelationshipData(),
          _loadActivityStats(),
        ]);
      }
    } catch (e) {
      // Keep defaults if loading fails
    }
  }

  Future<void> _loadPartnerProfile(String partnerId) async {
    try {
      final partnerResponse = await SupabaseService.client
          .from('user_profiles')
          .select('username, profile_image_url')
          .eq('id', partnerId)
          .maybeSingle();

      if (partnerResponse != null && mounted) {
        setState(() {
          _partnerUsername = partnerResponse['username'] as String?;
          _partnerProfileImageUrl = SupabaseService.getOptimizedImageUrl(partnerResponse['profile_image_url'] as String?, width: 260, height: 260);
        });
      }
    } catch (e) {
      // Keep defaults if partner loading fails
    }
  }

  Future<void> _loadRelationshipData() async {
    final user = SupabaseService.currentUser;
    if (user == null || _partnerId == null) return;

    try {
      // Get the couple's creation date and couple_id
      final coupleResponse = await SupabaseService.client
          .from('couples')
          .select('id, created_at')
          .or('user_a_id.eq.${user.id},user_b_id.eq.${user.id}')
          .maybeSingle();

      if (coupleResponse != null && mounted) {
        final coupleId = coupleResponse['id'] as String;
        
        setState(() {
          _coupleId = coupleId;
        });

        // Check if they have an anniversary date
        await _checkAnniversaryDate(coupleId);
        
        // Calculate streak based on actual daily activities
        final streakData = await StreakService.calculateStreak(coupleId);
        
        if (mounted) {
          setState(() {
            _streakDays = streakData.currentStreak;
            _weeklyStreak = streakData.weeklyStreak;
          });
        }
      }
    } catch (e) {
      // Keep defaults if loading fails
    }
  }

  Future<void> _checkAnniversaryDate(String coupleId) async {
    try {
      // Check if couple has an anniversary date
      final anniversaryResponse = await SupabaseService.client
          .from('important_dates')
          .select('event_date, milestone_types!inner(name)')
          .eq('couple_id', coupleId)
          .eq('milestone_types.name', 'Relationship Anniversary')
          .maybeSingle();

      if (mounted) {
        if (anniversaryResponse != null) {
          setState(() {
            _hasAnniversaryDate = true;
            _relationshipStartDate = DateTime.parse(anniversaryResponse['event_date'] as String);
          });
        } else {
          setState(() {
            _hasAnniversaryDate = false;
            _relationshipStartDate = null;
          });
        }
      }
    } catch (e) {
      // Keep defaults if loading fails
    }
  }

  Future<void> _loadActivityStats() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    try {
      // Count bucket list items for both users
      final bucketListResponse = await SupabaseService.client
          .from('bucket_list_items')
          .select('id')
          .or('user_id.eq.${user.id},user_id.eq.$_partnerId');

      // Count wish list items for both users
      final wishListResponse = await SupabaseService.client
          .from('wish_list_items')
          .select('id')
          .or('user_id.eq.${user.id},user_id.eq.$_partnerId');

      // Count plans for both users
      final plansResponse = await SupabaseService.client
          .from('plans')
          .select('id')
          .or('user_id.eq.${user.id},user_id.eq.$_partnerId');

      if (mounted) {
        setState(() {
          _bucketListCount = (bucketListResponse as List).length;
          _wishListCount = (wishListResponse as List).length;
          _plansCount = (plansResponse as List).length;
          // Placeholder for bloom notes - this would need a separate table
          _bloomNotesCount = 27;
        });
      }
    } catch (e) {
      // Keep defaults if loading fails
    }
  }

  String get _displayName {
    final userName = _username?.trim().isNotEmpty == true ? _username! : 'You';
    final partnerName =
        _partnerUsername?.trim().isNotEmpty == true ? _partnerUsername! : 'Partner';
    if (_partnerId == null) {
      return userName;
    }
    return '$userName & $partnerName';
  }

  Widget _buildStreakSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/images/streak.svg',
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Streak',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              Text(
                '$_streakDays Days',
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              return Column(
                children: [
                  Text(
                    _getWeekdayLabel(index),
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _weeklyStreak[index]
                          ? const Color(0xFFFBBF24)
                          : const Color(0xFFE5E7EB),
                      shape: BoxShape.circle,
                    ),
                    child: _weeklyStreak[index]
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20,
                          )
                        : null,
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTogetherForSection() {
    if (!_hasAnniversaryDate || _relationshipStartDate == null) {
      return _buildAnniversaryEmptyState();
    }

    final now = DateTime.now();
    final duration = now.difference(_relationshipStartDate!);
    
    // Calculate years, months, and days together
    final years = (duration.inDays / 365).floor();
    final remainingDaysAfterYears = duration.inDays % 365;
    final months = (remainingDaysAfterYears / 30).floor();
    final days = remainingDaysAfterYears % 30;

    // Calculate next anniversary
    DateTime nextAnniversary = DateTime(
      now.year,
      _relationshipStartDate!.month,
      _relationshipStartDate!.day,
    );
    
    // If this year's anniversary has passed, use next year
    if (nextAnniversary.isBefore(now)) {
      nextAnniversary = DateTime(
        now.year + 1,
        _relationshipStartDate!.month,
        _relationshipStartDate!.day,
      );
    }

    final daysUntilAnniversary = nextAnniversary.difference(now).inDays;
    final monthsUntilAnniversary = (daysUntilAnniversary / 30).floor();
    final daysRemainder = daysUntilAnniversary % 30;

    // Calculate which anniversary year it will be
    final anniversaryYear = nextAnniversary.year - _relationshipStartDate!.year;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/images/heart.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFFEF4444),
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Together For',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      // TODO: Navigate to edit anniversary screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Edit anniversary feature coming soon!'),
                          backgroundColor: Color(0xFF7C3ABA),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.edit,
                      size: 20,
                      color: Color(0xFF4D4B4B),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Time together display
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Years - use horizontal line if 0
                  years == 0
                      ? Column(
                          children: [
                            Container(
                              width: 60,
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFF7C3ABA),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Years',
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        )
                      : _buildTimeUnit(_formatTimeUnit(years), 'Years'),
                  _buildTimeUnit(_formatTimeUnit(months), 'Months'),
                  _buildTimeUnit(_formatTimeUnit(days), 'Days'),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Countdown to next anniversary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/images/party.svg',
                      width: 40,
                      height: 40,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$monthsUntilAnniversary months $daysRemainder days until',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_getOrdinal(anniversaryYear)} Anniversary',
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Add another important date button
        InkWell(
          onTap: () {
            if (_coupleId != null) {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: AddImportantDateModal(
                    coupleId: _coupleId!,
                    onSaved: () {
                      // Refresh data if needed
                      _loadRelationshipData();
                    },
                  ),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF7C3ABA),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.add,
                  color: Color(0xFF7C3ABA),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Add another important date',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF7C3ABA),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getOrdinal(int number) {
    if (number == 1) return '1st year';
    if (number == 2) return '2nd year';
    if (number == 3) return '3rd year';
    return '${number}th year';
  }

  Widget _buildAnniversaryEmptyState() {
    return InkWell(
      onTap: () {
        if (_coupleId != null) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: AddAnniversaryModal(
                coupleId: _coupleId!,
                onSaved: () {
                  _loadRelationshipData();
                },
              ),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF3E8FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE9D5FF),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                SvgPicture.asset(
                  'assets/images/heart.svg',
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFFEF4444),
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Together For',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'Important Date',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter Anniversary Date',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeUnit(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 36,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF7C3ABA),
            height: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SvgPicture.asset(
              'assets/images/Activity.svg',
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Activity',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActivityCard(
                _bucketListCount.toString(),
                'Items added to the\nbucket list',
                const Color(0xFFDDD6FE),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActivityCard(
                _wishListCount.toString(),
                'Items added to the\nwish list',
                const Color(0xFFFBCFE8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActivityCard(
                _plansCount.toString(),
                'Plans completed',
                const Color(0xFFFDE68A),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActivityCard(
                _bloomNotesCount.toString(),
                'Bloom notes shared',
                const Color(0xFFBAE6FD),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityCard(String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 160,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            count,
            style: GoogleFonts.manrope(
              fontSize: 56,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              height: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black.withOpacity(0.7),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeUnit(int value) {
    return value.toString().padLeft(2, '0');
  }

  String _getWeekdayLabel(int index) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days[index];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Expanded(
                      child: Text(
                        'Our Bloom',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE9D5FF)),
                      ),
                      child: const Icon(
                        Icons.settings,
                        color: Color(0xFF7C3ABA),
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                CoupleAvatar(
                  userProfileImageUrl: _profileImageUrl,
                  partnerProfileImageUrl: _partnerProfileImageUrl,
                  hasPartner: _partnerId != null,
                  size: 130,
                  onUserTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const IndividualProfileScreen(),
                      ),
                    );
                  },
                  onPartnerTap: () {
                    if (_partnerId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => IndividualProfileScreen(
                            userId: _partnerId,
                            isPartner: true,
                          ),
                        ),
                      ).then((_) => _loadProfile());
                    }
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  _displayName,
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Streak Section
                if (_partnerId != null) ...[
                  _buildStreakSection(),
                  const SizedBox(height: 32),
                  
                  // Together For Section
                  _buildTogetherForSection(),
                  const SizedBox(height: 32),
                  
                  // Activity Section
                  _buildActivitySection(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
