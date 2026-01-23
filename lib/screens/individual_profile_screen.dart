import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/interest.dart';
import '../models/love_language.dart';
import '../models/receive_care_option.dart';
import '../models/profile_details.dart';
import '../config/app_constants.dart';
import '../services/profile_details_service.dart';
import '../services/supabase_service.dart';
import '../widgets/pet_name_modal.dart';
import 'edit_profile_screen.dart';

class IndividualProfileScreen extends StatefulWidget {
  final String? userId;
  final bool isPartner;

  const IndividualProfileScreen({
    super.key,
    this.userId,
    this.isPartner = false,
  });

  @override
  State<IndividualProfileScreen> createState() => _IndividualProfileScreenState();
}

class _IndividualProfileScreenState extends State<IndividualProfileScreen> {
  String? _username;
  String? _profileImageUrl;
  String? _partnerPetName;
  double _completion = 0.0;
  bool _isLoading = true;
  
  // Profile data
  ProfileDetails? _details;
  List<Interest> _selectedInterests = [];
  LoveLanguage? _loveLanguageData;
  ReceiveCareOption? _careOptionData;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final effectiveUserId = widget.userId ?? SupabaseService.currentUser?.id;
    if (effectiveUserId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await SupabaseService.client
          .from('user_profiles')
          .select('username, profile_image_url, partner_id, invite_code, partner_invite_code, age_range, experience_level, onboarding_completed')
          .eq('id', effectiveUserId)
          .maybeSingle();

      String? petName;
      if (widget.isPartner) {
        // If viewing partner, fetch the pet name I (current user) gave them
        // This is stored in my own profile
        final currentUser = SupabaseService.currentUser;
        if (currentUser != null) {
          final myProfile = await SupabaseService.client
              .from('user_profiles')
              .select('partner_pet_name')
              .eq('id', currentUser.id)
              .maybeSingle();
          petName = myProfile?['partner_pet_name'] as String?;
        }
      } else {
        // If viewing myself, fetch the pet name my partner gave me
        // This is stored in my partner's profile
        final partnerId = response?['partner_id'] as String?;
        if (partnerId != null) {
          final partnerProfile = await SupabaseService.client
              .from('user_profiles')
              .select('partner_pet_name')
              .eq('id', partnerId)
              .maybeSingle();
          petName = partnerProfile?['partner_pet_name'] as String?;
        }
      }

      final details = await ProfileDetailsService.fetchProfileDetails(userId: effectiveUserId);
      final interests = await ProfileDetailsService.fetchUserSelectedInterests(userId: effectiveUserId);
      
      LoveLanguage? loveLanguage;
      if (details?.loveLanguage != null) {
        try {
          loveLanguage = AppConstants.loveLanguages.firstWhere(
            (ll) => ll.type == details!.loveLanguage,
          );
        } catch (_) {
          // Fallback if not found in constants
          final llRes = await SupabaseService.client
              .from('love_languages')
              .select('id, type, description')
              .eq('type', details!.loveLanguage!)
              .maybeSingle();
          if (llRes != null) loveLanguage = LoveLanguage.fromMap(llRes);
        }
      }

      ReceiveCareOption? careOption;
      if (details?.carePreferences != null) {
        try {
          careOption = AppConstants.receiveCareOptions.firstWhere(
            (rc) => rc.type == details!.carePreferences,
          );
        } catch (_) {
          // Fallback if not found in constants
          final careRes = await SupabaseService.client
              .from('receive_care_options')
              .select('id, type, description')
              .eq('type', details!.carePreferences!)
              .maybeSingle();
          if (careRes != null) careOption = ReceiveCareOption.fromMap(careRes);
        }
      }

      if (!mounted) return;

      setState(() {
        _username = (response?['username'] as String?)?.trim();
        _profileImageUrl = response?['profile_image_url'] as String?;
        _partnerPetName = petName;
        _details = details;
        _selectedInterests = interests;
        _loveLanguageData = loveLanguage;
        _careOptionData = careOption;
        _completion = _calculateCompletion(response, details);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _calculateCompletion(Map<String, dynamic>? profile, ProfileDetails? details) {
    const profileFields = [
      'username',
      'profile_image_url',
      'invite_code',
      'partner_invite_code',
      'age_range',
      'experience_level',
      'onboarding_completed',
    ];

    int filledCount = 0;
    int totalCount = profileFields.length;

    if (profile != null) {
      for (final field in profileFields) {
        final value = profile[field];
        if (value != null) {
          if (value is bool && value) filledCount++;
          else if (value is String && value.trim().isNotEmpty) filledCount++;
          else if (value is! bool && value is! String) filledCount++;
        }
      }
    }

    // Add fields from details (ProfileDetails model)
    const detailFields = [
      'birthdayDate',
      'shortNote',
      'interests',
      'loveLanguage',
      'carePreferences'
    ];
    totalCount += detailFields.length;

    if (details != null) {
      if (details.birthdayDate != null) filledCount++;
      if (details.shortNote?.isNotEmpty == true) filledCount++;
      if (details.interests?.isNotEmpty == true) filledCount++;
      if (details.loveLanguage?.isNotEmpty == true) filledCount++;
      if (details.carePreferences?.isNotEmpty == true) filledCount++;
    }

    return (filledCount / totalCount).clamp(0.0, 1.0);
  }

  String get _displayName {
    if (widget.isPartner && _partnerPetName != null) {
      return _partnerPetName!;
    }
    return _username?.isNotEmpty == true ? _username! : 'You';
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatBirthday(DateTime? date) {
    if (date == null) return '';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final completionPercent = (_completion * 100).round().clamp(0, 100);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildProfileContent(completionPercent),
            ),
            _buildBottomNavigationBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 24),
          ),
          Text(
            'Profile',
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          if (!widget.isPartner)
            InkWell(
              onTap: () => _showSnackBar('Settings coming soon.'),
              child: const Icon(Icons.settings_outlined, color: Colors.black, size: 28),
            )
          else
            const SizedBox(width: 28), // Maintain spacing
        ],
      ),
    );
  }

  Widget _buildProfileContent(int completionPercent) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildProfileAvatar(completionPercent),
          const SizedBox(height: 16),
          Text(
            _displayName,
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          if (widget.isPartner) ...[
            const SizedBox(height: 8),
            _buildPetNameButton(),
          ],
          if (!widget.isPartner) ...[
            const SizedBox(height: 16),
            _buildActionButtons(),
          ],
          const SizedBox(height: 32),
          _buildDetailsCard(),
        ],
      ),
    );
  }

  Widget _buildPetNameButton() {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => PetNameModal(
            partnerUsername: _username ?? 'Partner',
            initialPetName: _partnerPetName,
          ),
        ).then((result) {
          if (result != null) {
            _loadProfile();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF3E8FF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_outline, size: 18, color: Color(0xFFE91E63)),
            const SizedBox(width: 8),
            Text(
              _partnerPetName ?? 'Add Pet Name',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4D4B4B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(int completionPercent) {
    final hasImage = _profileImageUrl?.isNotEmpty == true;
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          width: 180,
          height: 180,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE91E63).withOpacity(0.2), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: ClipOval(
              child: hasImage
                  ? Image.network(
                      SupabaseService.getOptimizedImageUrl(_profileImageUrl, width: 360, height: 360)!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: const Color(0xFFFBF6F5),
                      child: const Icon(Icons.person, size: 80, color: Color(0xFFB4A5A5)),
                    ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$completionPercent%',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: () => _showSnackBar('Share coming soon.'),
          icon: const Icon(Icons.ios_share, size: 18),
          label: const Text('Share'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF4D4B4B),
            side: const BorderSide(color: Color(0xFF7C3ABA)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            ).then((_) => _loadProfile());
          },
          icon: const Icon(Icons.edit, size: 18),
          label: const Text('Edit Profile'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C3ABA),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailSection('About', _details?.shortNote ?? 'No bio added yet.'),
          const SizedBox(height: 24),
          _buildDetailSection('Birthday', _formatBirthday(_details?.birthdayDate)),
          const SizedBox(height: 24),
          _buildInterestsSection(),
          const SizedBox(height: 24),
          _buildLoveLanguageSection(),
          const SizedBox(height: 24),
          _buildReceiveCareSection(),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String label, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFFB8B8B8),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1F1F1F),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInterestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Interests',
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFFB8B8B8),
          ),
        ),
        const SizedBox(height: 12),
        if (_selectedInterests.isEmpty)
          Text('No interests selected', style: GoogleFonts.manrope(fontSize: 16, color: const Color(0xFF1F1F1F)))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedInterests.map((interest) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF7C3ABA)),
                ),
                child: Text(
                  interest.name,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1F1F1F),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildLoveLanguageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Love Language',
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFFB8B8B8),
          ),
        ),
        const SizedBox(height: 8),
        if (_loveLanguageData != null)
          RichText(
            text: TextSpan(
              style: GoogleFonts.manrope(fontSize: 16, color: const Color(0xFF1F1F1F), height: 1.5),
              children: [
                TextSpan(text: '${_loveLanguageData!.type} - ', style: const TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: _loveLanguageData!.description),
              ],
            ),
          )
        else
          Text('Not selected', style: GoogleFonts.manrope(fontSize: 16, color: const Color(0xFF1F1F1F))),
      ],
    );
  }

  Widget _buildReceiveCareSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Receive Care',
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFFB8B8B8),
          ),
        ),
        const SizedBox(height: 8),
        if (_careOptionData != null)
          RichText(
            text: TextSpan(
              style: GoogleFonts.manrope(fontSize: 16, color: const Color(0xFF1F1F1F), height: 1.5),
              children: [
                TextSpan(text: '${_careOptionData!.type} - ', style: const TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: _careOptionData!.description),
              ],
            ),
          )
        else
          Text('Not selected', style: GoogleFonts.manrope(fontSize: 16, color: const Color(0xFF1F1F1F))),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    const icons = [
      'assets/images/home-icon.svg',
      'assets/images/goal.svg',
      'assets/images/bloom-menuicon.png',
      'assets/images/bucketlist-icon.png',
      'assets/images/profile-icon.svg',
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 12, top: 6),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: icons.asMap().entries.map((entry) {
            final index = entry.key;
            final asset = entry.value;
            final isActive = index == icons.length - 1;
            return _buildNavItem(asset, isActive);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNavItem(String assetPath, bool isActive) {
    final color = isActive ? const Color(0xFF7C3ABA) : const Color(0xFFB8B8B8);
    final iconWidget = assetPath.endsWith('.svg')
        ? SvgPicture.asset(
            assetPath,
            width: 22,
            height: 22,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          )
        : ColorFiltered(
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            child: Image.asset(
              assetPath,
              width: 22,
              height: 22,
            ),
          );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 3,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF7C3ABA) : Colors.transparent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 6),
        iconWidget,
      ],
    );
  }
}
