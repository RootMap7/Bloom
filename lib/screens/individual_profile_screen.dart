import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/supabase_service.dart';

class IndividualProfileScreen extends StatefulWidget {
  const IndividualProfileScreen({super.key});

  @override
  State<IndividualProfileScreen> createState() => _IndividualProfileScreenState();
}

class _IndividualProfileScreenState extends State<IndividualProfileScreen> {
  String? _username;
  String? _profileImageUrl;
  double _completion = 0.65;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = SupabaseService.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final response = await SupabaseService.client
          .from('user_profiles')
          .select(
              'username, profile_image_url, invite_code, partner_invite_code, age_range, experience_level, onboarding_completed')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        _username = (response?['username'] as String?)?.trim();
        _profileImageUrl = response?['profile_image_url'] as String?;
        _completion = _calculateCompletion(response);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  double _calculateCompletion(Map<String, dynamic>? profile) {
    if (profile == null) return 0.65;

    const trackedFields = [
      'username',
      'profile_image_url',
      'invite_code',
      'partner_invite_code',
      'age_range',
      'experience_level',
      'onboarding_completed',
    ];

    final filled = trackedFields.where((field) {
      final value = profile[field];
      if (value == null) return false;
      if (value is bool) return value;
      if (value is String) return value.trim().isNotEmpty;
      return true;
    }).length;

    if (trackedFields.isEmpty) {
      return 0.65;
    }

    return (filled / trackedFields.length).clamp(0.0, 1.0);
  }

  String get _displayName => _username?.isNotEmpty == true ? _username! : 'You';

  @override
  Widget build(BuildContext context) {
    final completionPercent = (_completion * 100).round().clamp(0, 100);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Profile',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon.')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                )
              else
                Column(
                  children: [
                    SizedBox(
                      width: 152,
                      height: 152,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 152,
                            height: 152,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: const Color(0xFFFFD9EC),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              image: _profileImageUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(_profileImageUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _profileImageUrl == null
                                ? const Icon(
                                    Icons.person,
                                    size: 70,
                                    color: Color(0xFFB4A5A5),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF7C3ABA)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                '$completionPercent%',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF7C3ABA),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _displayName,
                      style: GoogleFonts.manrope(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Keep your profile up-to-date to unlock more thoughtful recommendations.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF4D4B4B),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Share link coming soon.')),
                            );
                          },
                          icon: const Icon(Icons.share_outlined, size: 18),
                          label: Text(
                            'Share',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF7C3ABA),
                            side: const BorderSide(color: Color(0xFF7C3ABA)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Complete profile flow coming soon.')),
                            );
                          },
                          icon: const Icon(Icons.edit, size: 18),
                          label: Text(
                            'Complete profile',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3ABA),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
