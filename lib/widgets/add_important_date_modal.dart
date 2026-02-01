import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';

class AddImportantDateModal extends StatefulWidget {
  final String coupleId;
  final VoidCallback onSaved;

  const AddImportantDateModal({
    super.key,
    required this.coupleId,
    required this.onSaved,
  });

  @override
  State<AddImportantDateModal> createState() => _AddImportantDateModalState();
}

class _AddImportantDateModalState extends State<AddImportantDateModal> {
  final TextEditingController _titleController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedMilestoneTypeId;
  String? _selectedMilestoneTypeName;
  bool _isRecurring = false;
  bool _remindMe = true;
  bool _isSaving = false;
  bool _isSaved = false;
  List<Map<String, dynamic>> _milestoneTypes = [];

  @override
  void initState() {
    super.initState();
    _loadMilestoneTypes();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadMilestoneTypes() async {
    try {
      final response = await SupabaseService.client
          .from('milestone_types')
          .select('id, name')
          .order('name');

      if (mounted) {
        setState(() {
          _milestoneTypes = List<Map<String, dynamic>>.from(response as List);
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
      lastDate: DateTime(2100),
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

  Future<void> _showMilestoneTypePicker() async {
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                'Select Milestone Type',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Divider(),
            ..._milestoneTypes.map((type) {
              return ListTile(
                title: Text(
                  type['name'] as String,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () => Navigator.pop(context, type),
              );
            }),
          ],
        ),
      ),
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedMilestoneTypeId = selected['id'] as String;
        _selectedMilestoneTypeName = selected['name'] as String;
      });
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

  Future<void> _saveImportantDate() async {
    if (_titleController.text.trim().isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title and select a date'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final user = SupabaseService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await SupabaseService.client.from('important_dates').insert({
        'couple_id': widget.coupleId,
        'date_title': _titleController.text.trim(),
        'event_date': _selectedDate!.toIso8601String().split('T')[0],
        'is_recurring': _isRecurring,
        'remind_me': _remindMe,
        'milestone_type_id': _selectedMilestoneTypeId,
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
                  : 'Failed to save date: ${e.toString()}',
            ),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add an important date',
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
              'We\'ll help you keep track of the moments that matter.',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            
            // Title field
            Text(
              'Title',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'E.g., First Date, Move-in Day',
                hintStyle: GoogleFonts.manrope(
                  fontSize: 16,
                  color: const Color(0xFF9CA3AF),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFFE9D5FF),
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFFE9D5FF),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFF7C3ABA),
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
              style: GoogleFonts.manrope(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            
            // Date field
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
                      color: Color(0xFF4D4B4B),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Milestone Type field
            Text(
              'Milestone Type',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _showMilestoneTypePicker,
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
                      _selectedMilestoneTypeName ?? '- - Select milestone type',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _selectedMilestoneTypeName == null
                            ? const Color(0xFF9CA3AF)
                            : Colors.black,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_drop_down,
                      size: 24,
                      color: Color(0xFF4D4B4B),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Is Recurring toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Is Recurring',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Set this to repeat yearly so your shared history\ncontinues to bloom.',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: const Color(0xFF6B7280),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isRecurring,
                  onChanged: (value) {
                    setState(() {
                      _isRecurring = value;
                    });
                  },
                  activeColor: const Color(0xFF7C3ABA),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Set Reminder toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set Reminder',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This and we\'ll make sure this date stays on your\nradar',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: const Color(0xFF6B7280),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _remindMe,
                  onChanged: (value) {
                    setState(() {
                      _remindMe = value;
                    });
                  },
                  activeColor: const Color(0xFF7C3ABA),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveImportantDate,
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
