import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/supabase_service.dart';
import 'login_screen.dart';
import 'coming_soon_screen.dart';
import 'onboarding/username_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  static const String _pendingEmailKey = 'pending_email_verification_email';

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorText;
  bool _isShowingConfirmationSheet = false;

  @override
  void initState() {
    super.initState();
    _restorePendingEmail();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _restorePendingEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingEmail = prefs.getString(_pendingEmailKey);
    if (pendingEmail != null && mounted) {
      _emailController.text = pendingEmail;
      _showEmailConfirmationSheet(pendingEmail);
    }
  }

  Future<void> _savePendingEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingEmailKey, email);
  }

  Future<void> _clearPendingEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingEmailKey);
  }

  void _showEmailConfirmationSheet(String email) {
    if (_isShowingConfirmationSheet || !mounted) return;
    _isShowingConfirmationSheet = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return EmailConfirmationBottomSheet(
          email: email,
          onOpenEmailApp: () async {
            final uri = Uri(scheme: 'mailto');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Open your email app to continue'),
                  ),
                );
              }
            }
          },
          onGoToLogin: () async {
            await _clearPendingEmail();
            if (!mounted) return;
            Navigator.of(sheetContext).pop();
            setState(() {
              _isShowingConfirmationSheet = false;
            });
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const UsernameScreen(),
              ),
            );
          },
          onChangeEmail: () async {
            await _clearPendingEmail();
            if (!mounted) return;
            Navigator.of(sheetContext).pop();
            setState(() {
              _isShowingConfirmationSheet = false;
              _emailController.clear();
            });
          },
        );
      },
    ).whenComplete(() {
      _isShowingConfirmationSheet = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              Colors.white.withOpacity(0.9), // Almost white at very center
              const Color(0xFFFFF5F5), // Very light pink/peach
              const Color(0xFFFFE5E5), // Light pink
              const Color(0xFFF3E8FF), // Light lavender
              const Color(0xFFE9D5FF), // Light purple
            ],
            stops: const [0.0, 0.2, 0.4, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Column(
                  children: [
                const SizedBox(height: 40),
                // Flower icon
                SvgPicture.asset(
                  'assets/images/bloom.svg',
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 32),
                // Title
                Text(
                  'Ready to Bloom?',
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF000000), // Text color
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // Subtitle
                Text(
                  'Sign up and bring your connection to life.',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: const Color(0xFF4D4B4B), // Subtext color
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Email field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF000000),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 52,
                      child: TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                        hintText: 'Enter your Email',
                        hintStyle: GoogleFonts.manrope(
                          fontSize: 14,
                          color: const Color(0xFF4D4B4B).withOpacity(0.5),
                        ),
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: Color(0xFF7C3ABA),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Color(0xFFC8A8E9),
                            width: 0.7,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Color(0xFFC8A8E9),
                            width: 0.7,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Color(0xFFC8A8E9),
                            width: 0.7,
                          ),
                        ),
                      ),
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: const Color(0xFF000000),
                      ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Password field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Password',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF000000),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 52,
                      child: TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                        hintText: 'Enter your password',
                        hintStyle: GoogleFonts.manrope(
                          fontSize: 14,
                          color: const Color(0xFF4D4B4B).withOpacity(0.5),
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Color(0xFF7C3ABA),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: const Color(0xFF7C3ABA),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Color(0xFFC8A8E9),
                            width: 0.7,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Color(0xFFC8A8E9),
                            width: 0.7,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Color(0xFFC8A8E9),
                            width: 0.7,
                          ),
                        ),
                      ),
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: const Color(0xFF000000),
                      ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Confirm Password field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confirm Password',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF000000),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 52,
                      child: TextField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                        hintText: 'Enter your password',
                        hintStyle: GoogleFonts.manrope(
                          fontSize: 14,
                          color: const Color(0xFF4D4B4B).withOpacity(0.5),
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Color(0xFF7C3ABA),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: const Color(0xFF7C3ABA),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Color(0xFFC8A8E9),
                            width: 0.7,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Color(0xFFC8A8E9),
                            width: 0.7,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Color(0xFFC8A8E9),
                            width: 0.7,
                          ),
                        ),
                      ),
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: const Color(0xFF000000),
                      ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                if (_errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _errorText!,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                // Continue button
                SizedBox(
                  width: double.infinity,
                  height: 57,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            final email = _emailController.text.trim();
                            final password = _passwordController.text.trim();
                            final confirm = _confirmPasswordController.text.trim();

                            if (email.isEmpty ||
                                password.isEmpty ||
                                confirm.isEmpty) {
                              setState(() {
                                _errorText = 'Please fill in all fields.';
                              });
                              return;
                            }

                            if (password != confirm) {
                              setState(() {
                                _errorText = 'Passwords do not match.';
                              });
                              return;
                            }

                            setState(() {
                              _isLoading = true;
                              _errorText = null;
                            });

                            try {
                              await SupabaseService.signUp(
                                email: email,
                                password: password,
                              );

                              await _savePendingEmail(email);
                              if (!mounted) return;
                              _showEmailConfirmationSheet(email);
                            } catch (e) {
                              setState(() {
                                _errorText = e.toString();
                              });
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isLoading = false;
                                });
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3ABA), // Primary color
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Continue',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                // Divider with text
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: const Color(0xFF4D4B4B).withOpacity(0.3),
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or sign up with',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: const Color(0xFF4D4B4B),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: const Color(0xFF4D4B4B).withOpacity(0.3),
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Google and Apple buttons
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 57,
                        child: OutlinedButton(
                          onPressed: () {
                            // TODO: Handle Google sign up
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF4D4B4B),
                            side: const BorderSide(
                              color: Color(0xFF7C3ABA),
                              width: 0.7,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            backgroundColor: Colors.transparent,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Google icon
                              SvgPicture.asset(
                                'assets/images/google.svg',
                                width: 20,
                                height: 20,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Google',
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF4D4B4B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 57,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const ComingSoonScreen(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF4D4B4B),
                            side: const BorderSide(
                              color: Color(0xFF7C3ABA),
                              width: 0.7,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            backgroundColor: Colors.transparent,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Apple icon
                              SvgPicture.asset(
                                'assets/images/apple.svg',
                                width: 20,
                                height: 20,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Apple',
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF4D4B4B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Login link
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  child: Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: const Color(0xFF4D4B4B),
                        ),
                        children: [
                          const TextSpan(
                            text: 'Already have an account, ',
                          ),
                          TextSpan(
                            text: 'Login',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF7C3ABA),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Privacy Policy text
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: const Color(0xFF4D4B4B),
                      ),
                      children: [
                        const TextSpan(
                          text: 'By tapping \"continue\", you agree to our\n',
                        ),
                        TextSpan(
                          text: 'Privacy Policy & Terms of Service',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: const Color(0xFF7C3ABA),
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                  ],
                ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class EmailConfirmationBottomSheet extends StatelessWidget {
  final String email;
  final VoidCallback onOpenEmailApp;
  final VoidCallback onGoToLogin;
  final VoidCallback onChangeEmail;

  const EmailConfirmationBottomSheet({
    super.key,
    required this.email,
    required this.onOpenEmailApp,
    required this.onGoToLogin,
    required this.onChangeEmail,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFF3E8FF),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/images/sent.svg',
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'We’ve sent a confirmation email to',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF000000),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  email,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF000000),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Open it and tap the link to finish setting up Bloom.',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: const Color(0xFF4D4B4B),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 57,
                  child: ElevatedButton(
                    onPressed: onOpenEmailApp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3ABA),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Open Email App',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 57,
                  child: OutlinedButton(
                    onPressed: onGoToLogin,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF7C3ABA),
                      side: const BorderSide(
                        color: Color(0xFF7C3ABA),
                        width: 0.7,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'Go to Login',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 57,
                  child: OutlinedButton(
                    onPressed: onChangeEmail,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4D4B4B),
                      side: const BorderSide(
                        color: Color(0xFF9CA3AF),
                        width: 0.7,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'Change Email',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Didn’t see it? Check spam or promotions.',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: const Color(0xFF4D4B4B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

