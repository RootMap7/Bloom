import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/bloom_note_service.dart';
import '../services/supabase_service.dart';

class SendBloomNoteModal extends StatefulWidget {
  final VoidCallback onSaved;

  const SendBloomNoteModal({
    super.key,
    required this.onSaved,
  });

  @override
  State<SendBloomNoteModal> createState() => _SendBloomNoteModalState();
}

class _SendBloomNoteModalState extends State<SendBloomNoteModal> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;
  bool _isSent = false;
  String _partnerPetName = 'your partner';

  @override
  void initState() {
    super.initState();
    _loadPartnerName();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadPartnerName() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    try {
      // Get current user's profile to find partner_id
      final userProfile = await SupabaseService.client
          .from('user_profiles')
          .select('partner_id')
          .eq('id', user.id)
          .maybeSingle();

      final partnerId = userProfile?['partner_id'] as String?;
      
      if (partnerId != null) {
        // Get partner's pet name or username
        final partnerProfile = await SupabaseService.client
            .from('user_profiles')
            .select('partner_pet_name, username')
            .eq('id', partnerId)
            .maybeSingle();

        if (partnerProfile != null && mounted) {
          final petName = partnerProfile['partner_pet_name'] as String?;
          final username = partnerProfile['username'] as String?;
          
          setState(() {
            _partnerPetName = petName?.isNotEmpty == true 
                ? petName! 
                : (username?.isNotEmpty == true ? username! : 'your partner');
          });
        }
      }
    } catch (e) {
      // Use default if error
      debugPrint('Error loading partner name: $e');
    }
  }

  Future<void> _sendNote() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a message'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await BloomNoteService.sendNote(message: _messageController.text.trim());

      if (mounted) {
        setState(() {
          _isSent = true;
          _isSending = false;
        });

        // Wait a moment to show success state
        await Future.delayed(const Duration(seconds: 2));

        widget.onSaved();
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send note: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSent) {
      return _buildSuccessState();
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF8F6),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Share a note with\n$_partnerPetName',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      height: 1.3,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  color: Colors.black,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Share a sweet thought, a sudden \'I love you,\' or a tiny compliment. These notes are just for now—they\'ll disappear in 24 hours, making every message a special moment in time.',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            
            // Message field with Bradley Hand font
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE9D5FF),
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: 6,
                maxLength: 250,
                decoration: InputDecoration(
                  hintText: 'Enter a special message here',
                  hintStyle: GoogleFonts.caveat(
                    fontSize: 20,
                    color: const Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: GoogleFonts.caveat(
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Send button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSending ? null : _sendNote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3ABA),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  disabledBackgroundColor: const Color(0xFF7C3ABA).withOpacity(0.5),
                ),
                child: _isSending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/images/share.svg',
                            width: 20,
                            height: 20,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Share Note',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF8F6),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              color: Color(0xFFDCC4F5),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/images/shared.svg',
                width: 50,
                height: 50,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF7C3ABA),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Note Shared!',
            style: GoogleFonts.manrope(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'We\'ll keep this safe and remind you both when it\'s time to celebrate. Here\'s to many more years of blooming together!',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onSaved();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3ABA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Close',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
