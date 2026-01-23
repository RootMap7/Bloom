import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';
import '../widgets/couple_avatar.dart';
import '../widgets/pet_name_modal.dart';
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
        await _loadPartnerProfile(_partnerId!);
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

  String get _displayName {
    final userName = _username?.trim().isNotEmpty == true ? _username! : 'You';
    final partnerName =
        _partnerUsername?.trim().isNotEmpty == true ? _partnerUsername! : 'Partner';
    if (_partnerId == null) {
      return userName;
    }
    return '$userName & $partnerName';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),
      body: SafeArea(
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
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF7C3ABA),
                      side: const BorderSide(color: Color(0xFF7C3ABA)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.share, size: 18),
                    label: Text(
                      'Share',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3ABA),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.edit, size: 18),
                    label: Text(
                      'Complete profile',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
