import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';

class AddAnniversaryModal extends StatefulWidget {
  final String coupleId;
  final VoidCallback onSaved;

  const AddAnniversaryModal({
    super.key,
    required this.coupleId,
    required this.onSaved,
  });

  @override
  State<AddAnniversaryModal> createState() => _AddAnniversaryModalState();
}

class _AddAnniversaryModalState extends State<AddAnniversaryModal> {
  DateTime? _selectedDate;
  bool _isSaving = false;
  bool _isSaved = false;
  String? _milestoneTypeId;

  @override
  void initState() {
    super.initState();
    _loadMilestoneType();
  }

  Future<void> _loadMilestoneType() async {
    try {
      final response = await SupabaseService.client
          .from('milestone_types')
          .select('id')
          .eq('name', 'Relationship Anniversary')
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _milestoneTypeId = response['id'] as String;
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF7C3ABA),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveAnniversary() async {
    if (_selectedDate == null || _milestoneTypeId == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final user = SupabaseService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await SupabaseService.client.from('important_dates').insert({
        'couple_id': widget.coupleId,
        'date_title': 'Our Anniversary',
        'event_date': _selectedDate!.toIso8601String().split('T')[0],
        'is_recurring': true,
        'remind_me': true,
        'milestone_type_id': _milestoneTypeId,
        'category': 'Anniversary',
        'added_by': user.id,
      });

      if (mounted) {
        setState(() {
          _isSaved = true;
          _isSaving = false;
        });

        // Wait a moment to show success state
        await Future.delayed(const Duration(seconds: 1));

        widget.onSaved();
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('one Relationship Anniversary')
                  ? 'You already have an anniversary date set'
                  : 'Failed to save anniversary',
            ),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isSaved) {
      return _buildSuccessState();
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF8F6),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Add your Anniversary',
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
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
            'We\'ll help you keep track of the moments that matter.\nStart by adding your anniversary.',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Date',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE9D5FF),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedDate == null
                        ? '–/–/–'
                        : _formatDate(_selectedDate!),
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _selectedDate == null
                          ? const Color(0xFF9CA3AF)
                          : Colors.black,
                    ),
                  ),
                  const Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: Color(0xFF7C3ABA),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedDate == null || _isSaving
                  ? null
                  : _saveAnniversary,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3ABA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                disabledBackgroundColor: const Color(0xFF7C3ABA).withOpacity(0.5),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Save',
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
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFF7C3ABA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Date saved!',
            style: GoogleFonts.manrope(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'We\'ll keep this safe and remind you both when it\'s\ntime to celebrate. Here\'s to many more years of\nblooming together!',
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
