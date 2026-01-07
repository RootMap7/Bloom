import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';
import '../services/onboarding_service.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _isLoading = true;
  bool _showShareCode = true;
  final List<TextEditingController> _codeControllers =
      List.generate(5, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(5, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
        setState(() {
          _isLoading = false;
        });
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
          _profileImageUrl = response['profile_image_url'] as String?;
          _inviteCode = response['invite_code'] as String?;
          _partnerId = response['partner_id'] as String?;
          _isLoading = false;
        });
      } else {
        final code = await OnboardingService.getInviteCode();
        setState(() {
          _inviteCode = code;
          _isLoading = false;
        });
      }
    } catch (e) {
      try {
        final code = await OnboardingService.getInviteCode();
        setState(() {
          _inviteCode = code;
          _isLoading = false;
        });
      } catch (e2) {
        setState(() {
          _isLoading = false;
        });
      }
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
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Partner connected successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          color: const Color(0xFFFFF8F6),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

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
                // Welcome section
                _buildWelcomeSection(),
                const SizedBox(height: 24),
                // Partner connection card
                if (_partnerId == null) _buildPartnerConnectionCard(),
                const SizedBox(height: 24),
                // Partnership card
                _buildPartnershipCard(),
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
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildTopSection() {
    return Row(
      children: [
        // Profile pictures - wrapped in SizedBox to provide bounded constraints
        SizedBox(
          width: 49,
          height: 61, // 49 + 12 offset
          child: Stack(
            clipBehavior: Clip.none,
            children: [
            // User profile (below)
            Positioned(
              left: 0,
              top: 12,
              child: Container(
                width: 49,
                height: 49,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF7C3ABA),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 22.5,
                  backgroundColor: Colors.white,
                  backgroundImage: _profileImageUrl != null
                      ? NetworkImage(_profileImageUrl!)
                      : null,
                  child: _profileImageUrl == null
                      ? Icon(Icons.person, color: Colors.grey[400], size: 28)
                      : null,
                ),
              ),
            ),
            // Partner add icon (on top)
            Positioned(
              left: 0,
              top: 0,
              child: _partnerId == null
                  ? GestureDetector(
                      onTap: () {
                        setState(() {
                          _showShareCode = false;
                        });
                      },
                      child: Container(
                        width: 49,
                        height: 49,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF7C3ABA),
                              Color(0xFFC8A8E9),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    )
                  : Container(
                      width: 49,
                      height: 49,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF7C3ABA),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 22.5,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, color: Colors.grey[400], size: 28),
                      ),
                    ),
            ),
          ],
        ),
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
        Container(
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

  Widget _buildPartnershipCard() {
    return Container(
      height: 316,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Center(
                  child: SvgPicture.asset(
                    'assets/images/plan.svg',
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3ABA),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {},
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
                  const Icon(Icons.add, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Add plans',
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
      ),
    );
  }

  Widget _buildBucketlistCard() {
    return Container(
      height: 316,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/bucketlist-icon.png',
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3ABA),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {},
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
                  const Icon(Icons.add, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Add items to your bucket-list',
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
      ),
    );
  }

  Widget _buildWishlistCard() {
    return Container(
      height: 316,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Center(
                  child: SvgPicture.asset(
                    'assets/images/wishlist-icon.svg',
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3ABA),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {},
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
                  const Icon(Icons.add, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Add items to your wish-list',
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
    
    return GestureDetector(
      onTap: () {
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
    );
  }
}
