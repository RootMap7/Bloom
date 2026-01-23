import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../models/interest.dart';
import '../services/onboarding_service.dart';
import '../services/profile_details_service.dart';
import '../services/supabase_service.dart';
import '../widgets/interests_modal.dart';
import '../widgets/love_language_modal.dart';
import '../widgets/receive_care_modal.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _birthdayController = TextEditingController();
  final _noteController = TextEditingController();
  final _interestsController = TextEditingController();
  final _loveLanguageController = TextEditingController();
  final _careController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  DateTime? _birthday;
  List<Interest> _selectedInterests = [];
  bool _isLoading = true;
  bool _isSaving = false;
  File? _pickedImage;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _birthdayController.dispose();
    _noteController.dispose();
    _interestsController.dispose();
    _loveLanguageController.dispose();
    _careController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = SupabaseService.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final details = await ProfileDetailsService.fetchProfileDetails();
      final selectedInterests = await ProfileDetailsService.fetchUserSelectedInterests();
      final profile = await SupabaseService.client
          .from('user_profiles')
          .select('profile_image_url')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        _birthday = details?.birthdayDate;
        _birthdayController.text = _birthday != null ? _formatDate(_birthday!) : '';
        _noteController.text = details?.shortNote ?? '';
        _selectedInterests = selectedInterests;
        _interestsController.text = _selectedInterests.map((i) => i.name).join(', ');
        _loveLanguageController.text = details?.loveLanguage ?? '';
        _careController.text = details?.carePreferences ?? '';
        _existingImageUrl = profile?['profile_image_url'] as String?;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Unable to load profile');
    }
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      String? imageUrl;
      if (_pickedImage != null) {
        imageUrl = await OnboardingService.uploadProfileImage(_pickedImage!);
      }

      await ProfileDetailsService.saveProfileDetails(
        birthdayDate: _birthday,
        shortNote: _noteController.text,
        interests: _interestsController.text,
        selectedInterestIds: _selectedInterests.map((i) => i.id).toList(),
        loveLanguage: _loveLanguageController.text,
        carePreferences: _careController.text,
      );

      if (!mounted) return;

      setState(() {
        if (imageUrl != null) {
          _existingImageUrl = imageUrl;
          _pickedImage = null;
        }
      });

      _showSnackBar('Profile updated');
      
      // Navigate back to profile page after a small delay to let the user see the success
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) Navigator.of(context).pop();
      });
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Unable to save profile: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _showInterestsModal() async {
    final result = await showModalBottomSheet<List<Interest>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InterestsModal(
        initialSelectedInterests: _selectedInterests,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedInterests = result;
        _interestsController.text = _selectedInterests.map((i) => i.name).join(', ');
      });
    }
  }

  Future<void> _showLoveLanguageModal() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LoveLanguageModal(
        initialSelectedType: _loveLanguageController.text.isNotEmpty
            ? _loveLanguageController.text
            : null,
      ),
    );

    if (result != null) {
      setState(() {
        _loveLanguageController.text = result;
      });
    }
  }

  Future<void> _showReceiveCareModal() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReceiveCareModal(
        initialSelectedType: _careController.text.isNotEmpty
            ? _careController.text
            : null,
      ),
    );

    if (result != null) {
      setState(() {
        _careController.text = result;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image == null) return;
      setState(() {
        _pickedImage = File(image.path);
      });
    } catch (_) {
      _showSnackBar('Unable to pick an image right now.');
    }
  }

  Future<void> _selectBirthday() async {
    final now = DateTime.now();
    final initial = _birthday ?? now;
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (selected == null) return;
    setState(() {
      _birthday = selected;
      _birthdayController.text = _formatDate(selected);
    });
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildForm(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF7C3ABA), width: 1.25),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF4D4B4B),
                size: 18,
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F1F1F),
                ),
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: _isSaving ? null : _saveProfile,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF7C3ABA),
              ),
              child: _isSaving
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 26,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 24),
          _buildAvatar(),
          const SizedBox(height: 28),
          _buildField(
            label: 'Birthday Date',
            controller: _birthdayController,
            suffix: const Icon(Icons.calendar_today, size: 24, color: Color(0xFF7C3ABA)),
            readOnly: true,
            onTap: _selectBirthday,
          ),
          const SizedBox(height: 22),
          _buildField(
            label: 'Short note about me',
            controller: _noteController,
            maxLines: 4,
          ),
          const SizedBox(height: 22),
          _buildField(
            label: 'Interests',
            controller: _interestsController,
            suffix: const Icon(Icons.chevron_right, size: 28, color: Color(0xFF7C3ABA)),
            maxLines: 3,
            readOnly: true,
            onTap: _showInterestsModal,
          ),
          const SizedBox(height: 22),
          _buildField(
            label: 'Love Language',
            controller: _loveLanguageController,
            suffix: const Icon(Icons.chevron_right, size: 28, color: Color(0xFF7C3ABA)),
            readOnly: true,
            onTap: _showLoveLanguageModal,
          ),
          const SizedBox(height: 22),
          _buildField(
            label: 'How I like to receive care',
            controller: _careController,
            suffix: const Icon(Icons.chevron_right, size: 28, color: Color(0xFF7C3ABA)),
            readOnly: true,
            onTap: _showReceiveCareModal,
          ),
          const SizedBox(height: 38),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    ImageProvider? imageProvider;
    if (_pickedImage != null) {
      imageProvider = FileImage(_pickedImage!);
    } else if (_existingImageUrl != null) {
      imageProvider = NetworkImage(SupabaseService.getOptimizedImageUrl(_existingImageUrl, width: 372, height: 372)!);
    }

    return GestureDetector(
      onTap: _pickImage,
      child: SizedBox(
        width: 186,
        height: 186,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 186,
              height: 186,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFC1D9), width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipOval(
                child: imageProvider != null
                    ? Image(
                        image: imageProvider,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    : Container(
                        color: const Color(0xFFFDF5F5),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.person,
                          size: 80,
                          color: Colors.black.withOpacity(0.4),
                        ),
                      ),
              ),
            ),
            Container(
              width: 186,
              height: 186,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.35),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              bottom: 18,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Upload a profile picture',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F1F1F),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    Widget? suffix,
    bool readOnly = false,
    int maxLines = 1,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF140E1E),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          onTap: readOnly ? onTap : null,
          maxLines: maxLines,
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF2C2632),
          ),
          decoration: InputDecoration(
            suffixIcon: suffix != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: suffix,
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFFC8A8E9)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFFC8A8E9), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFF7C3ABA), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
