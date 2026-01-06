import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/supabase_service.dart';
import '../../services/onboarding_service.dart';
import '../../utils/code_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../home_screen.dart';

class ConnectPartnerScreen extends StatefulWidget {
  const ConnectPartnerScreen({super.key});

  @override
  State<ConnectPartnerScreen> createState() => _ConnectPartnerScreenState();
}

class _ConnectPartnerScreenState extends State<ConnectPartnerScreen> {
  final List<TextEditingController> _codeControllers =
      List.generate(5, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(5, (_) => FocusNode());
  String? _inviteCode;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOrGenerateCode();
    // Set up focus nodes to move to next field
    for (int i = 0; i < 4; i++) {
      _codeControllers[i].addListener(() {
        if (_codeControllers[i].text.isNotEmpty && i < 4) {
          _focusNodes[i + 1].requestFocus();
        }
      });
    }
  }

  Future<void> _loadOrGenerateCode() async {
    try {
      // Try to get code from Supabase first
      final code = await OnboardingService.getInviteCode();
      if (code != null) {
        setState(() {
          _inviteCode = code;
        });
        return;
      }
    } catch (e) {
      // If error, fall back to SharedPreferences
    }

    // Fallback to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    String? savedCode = prefs.getString('user_invite_code');

    if (savedCode == null) {
      // Generate new code
      savedCode = CodeGenerator.generateCode();
      await prefs.setString('user_invite_code', savedCode);
    }

    setState(() {
      _inviteCode = savedCode;
    });
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
    // TODO: Implement native share functionality
    _copyCode();
  }

  Future<void> _connectWithCode() async {
    final enteredCode = _codeControllers.map((c) => c.text).join('').toUpperCase();
    
    if (!CodeGenerator.isValidCode(enteredCode)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 5-character code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await OnboardingService.connectPartner(enteredCode);
      
      if (result['success'] == true) {
        // Mark onboarding as completed
        await OnboardingService.completeOnboarding();
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _skipAndGoHome() async {
    try {
      // Mark onboarding as completed even if skipping partner connection
      await OnboardingService.completeOnboarding();
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      }
    } catch (e) {
      // If error, still navigate to home
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      }
    }
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
              Colors.white.withOpacity(0.9),
              const Color(0xFFFFF5F5),
              const Color(0xFFFFE5E5),
              const Color(0xFFF3E8FF),
              const Color(0xFFE9D5FF),
            ],
            stops: const [0.0, 0.2, 0.4, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Progress bar (complete)
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3ABA),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                // Title
                Text(
                  'Connect with your Partner',
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF000000),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // Subtitle
                Text(
                  'Start your shared space for memories, plans, and little surprises.',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: const Color(0xFF4D4B4B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Invite your partner card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invite your partner',
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF000000),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Invite code display
                      Row(
                        children: [
                          ...(_inviteCode?.split('') ?? []).asMap().entries.map(
                                (entry) => Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFF4D4B4B).withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        entry.value,
                                        style: GoogleFonts.manrope(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF000000),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _copyCode,
                            icon: const Icon(
                              Icons.copy,
                              color: Color(0xFF4D4B4B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 57,
                        child: ElevatedButton(
                          onPressed: _shareCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3ABA),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Share my invite code',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Enter partner's code card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enter your partner\'s code',
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF000000),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Code input fields
                      Row(
                        children: List.generate(
                          5,
                          (index) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: TextField(
                                controller: _codeControllers[index],
                                focusNode: _focusNodes[index],
                                textAlign: TextAlign.center,
                                maxLength: 1,
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
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: const Color(0xFF4D4B4B).withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: const Color(0xFF4D4B4B).withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF7C3ABA),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                onChanged: (value) {
                                  if (value.isNotEmpty && index < 4) {
                                    _focusNodes[index + 1].requestFocus();
                                  }
                                },
                                textInputAction: index < 4
                                    ? TextInputAction.next
                                    : TextInputAction.done,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 57,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _connectWithCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3ABA),
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
                                  'Connect',
                                  style: GoogleFonts.manrope(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Skip button
                SizedBox(
                  width: double.infinity,
                  height: 57,
                  child: OutlinedButton(
                    onPressed: _skipAndGoHome,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4D4B4B),
                      side: BorderSide(
                        color: const Color(0xFF4D4B4B).withOpacity(0.3),
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      backgroundColor: Colors.white,
                    ),
                    child: Text(
                      'Skip For Now',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4D4B4B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You can add your partner later.',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: const Color(0xFF4D4B4B),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

