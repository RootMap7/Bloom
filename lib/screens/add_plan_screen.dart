import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';
import 'plan_saved_screen.dart';

class AddPlanScreen extends StatefulWidget {
  const AddPlanScreen({super.key});

  @override
  State<AddPlanScreen> createState() => _AddPlanScreenState();
}

class _AddPlanScreenState extends State<AddPlanScreen> {
  final TextEditingController _dateTimeController = TextEditingController();
  final TextEditingController _planTitleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _checklistController = TextEditingController();
  final List<String> _checklistItems = [];
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _linksController = TextEditingController();

  final List<_ThemeOption> _themeOptions = const [
    _ThemeOption(label: 'Blue', color: Color(0xFF6EB4FF)),
    _ThemeOption(label: 'Yellow', color: Color(0xFFF4D100)),
    _ThemeOption(label: 'Peach', color: Color(0xFFFFB7C3)),
    _ThemeOption(label: 'Purple', color: Color(0xFFC8A8E9)),
  ];

  _ThemeOption _selectedTheme = const _ThemeOption(
    label: 'Blue',
    color: Color(0xFF6EB4FF),
  );
  DateTime? _selectedDateTime;
  bool _isSaving = false;

  @override
  void dispose() {
    _dateTimeController.dispose();
    _planTitleController.dispose();
    _locationController.dispose();
    _checklistController.dispose();
    _notesController.dispose();
    _linksController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFF7C3ABA),
                ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFF7C3ABA),
                ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (pickedTime == null || !mounted) return;

    final date = DateUtils.dateOnly(pickedDate);
    final time = pickedTime.format(context);
    final formatted = '${_twoDigits(date.day)}/${_twoDigits(date.month)}/${date.year}  $time';
    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      _dateTimeController.text = formatted;
      _selectedDateTime = combined;
    });
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  Future<void> _savePlan() async {
    if (_isSaving) return;
    final user = SupabaseService.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to save a plan.')),
        );
      }
      return;
    }

    final title = _planTitleController.text.trim();
    final notes = _notesController.text.trim();
    final links = _linksController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan title is required.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await SupabaseService.client.from('plans').insert({
        'user_id': user.id,
        'plan_title': title,
        'location': _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        'checklist': _checklistItems,
        'notes': notes.isEmpty ? null : notes,
        'links': links.isEmpty ? null : links,
        'theme_color': _themeHex(_selectedTheme),
        'plan_date_time': _selectedDateTime?.toIso8601String(),
      });

      if (mounted) {
        final description = [
          if (notes.isNotEmpty) 'Notes: $notes',
          if (links.isNotEmpty) 'Links: $links',
        ].join('\n');

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PlanSavedScreen(
              title: title,
              location: _locationController.text.trim().isEmpty
                  ? 'Location pending'
                  : _locationController.text.trim(),
              dateLabel: _formatDateLabel(_selectedDateTime),
              timeLabel: _formatTimeLabel(_selectedDateTime),
              themeColor: _selectedTheme.color,
              planDateTime: _selectedDateTime,
              description: description.isEmpty ? null : description,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save plan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8F6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Add a Plan',
          style: GoogleFonts.manrope(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: _isSaving ? null : _savePlan,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _isSaving ? const Color(0xFFB6B0B0) : const Color(0xFF7C3ABA),
                  shape: BoxShape.circle,
                ),
                child: _isSaving
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.check, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
          children: [
            _buildLabel('Date & Time'),
            const SizedBox(height: 8),
            _buildReadOnlyField(
              controller: _dateTimeController,
              hintText: '19/02/2026',
              suffix: const Icon(Icons.calendar_today_outlined, size: 20),
              onTap: _pickDateTime,
            ),
            const SizedBox(height: 18),
            _buildLabel('Plan Title'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _planTitleController,
              hintText: 'What\'s the next adventure?',
            ),
            const SizedBox(height: 18),
            _buildLabel('Location'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _locationController,
              hintText: 'Where are you heading?',
            ),
            const SizedBox(height: 18),
            _buildLabel('Checklist (if applicable)'),
            const SizedBox(height: 8),
            _buildChecklistField(),
            const SizedBox(height: 18),
            _buildLabel('Notes/Reminders'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _notesController,
              hintText: 'Things not to forget, budget etc',
              maxLines: 3,
            ),
            const SizedBox(height: 18),
            _buildLabel('Links'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _linksController,
              hintText: 'Link to a menu, map, or inspiration',
            ),
            const SizedBox(height: 18),
            _buildLabel('Theme Color'),
            const SizedBox(height: 8),
            _buildThemeSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF4D4B4B),
      ),
      decoration: _inputDecoration(hintText, suffix),
    );
  }

  Widget _buildReadOnlyField({
    required TextEditingController controller,
    required String hintText,
    required VoidCallback onTap,
    Widget? suffix,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AbsorbPointer(
        child: TextField(
          controller: controller,
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF4D4B4B),
          ),
          decoration: _inputDecoration(hintText, suffix),
        ),
      ),
    );
  }

  Widget _buildChecklistField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6E0F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_checklistItems.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _checklistItems
                  .map(
                    (item) => Chip(
                      label: Text(
                        item,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4D4B4B),
                        ),
                      ),
                      backgroundColor: const Color(0xFFF5F2FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onDeleted: () {
                        setState(() {
                          _checklistItems.remove(item);
                        });
                      },
                      deleteIconColor: const Color(0xFF7C3ABA),
                    ),
                  )
                  .toList(),
            ),
          TextField(
            controller: _checklistController,
            textInputAction: TextInputAction.done,
            onSubmitted: (value) {
              final trimmed = value.trim();
              if (trimmed.isEmpty) return;
              setState(() {
                _checklistItems.add(trimmed);
                _checklistController.clear();
              });
            },
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF4D4B4B),
            ),
            decoration: InputDecoration(
              hintText: 'List the small steps to make it happen...',
              hintStyle: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFB6B0B0),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(
                top: _checklistItems.isEmpty ? 2 : 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hintText, Widget? suffix) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: const Color(0xFFB6B0B0),
      ),
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffix == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(right: 12),
              child: suffix,
            ),
      suffixIconConstraints: const BoxConstraints(minHeight: 20, minWidth: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE6E0F5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF7C3ABA), width: 1.2),
      ),
    );
  }

  String _themeHex(_ThemeOption option) {
    switch (option.label) {
      case 'Blue':
        return '#6EB4FF';
      case 'Yellow':
        return '#F4D100';
      case 'Peach':
        return '#FFB7C3';
      case 'Purple':
        return '#C8A8E9';
      default:
        return '#6EB4FF';
    }
  }

  String _formatDateLabel(DateTime? dateTime) {
    if (dateTime == null) return 'Date to be set';
    final day = _twoDigits(dateTime.day);
    final month = _monthLabel(dateTime.month);
    final year = dateTime.year.toString();
    return '$day $month $year';
  }

  String _formatTimeLabel(DateTime? dateTime) {
    if (dateTime == null) return 'Time to be set';
    final time = TimeOfDay.fromDateTime(dateTime);
    return time.format(context);
  }

  String _monthLabel(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[(month - 1).clamp(0, 11)];
  }

  Widget _buildThemeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6E0F5)),
      ),
      child: Column(
        children: _themeOptions.map((option) {
          final isSelected = _selectedTheme.label == option.label;
          return InkWell(
            onTap: () {
              setState(() {
                _selectedTheme = option;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: option.color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      option.label,
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4D4B4B),
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle, color: Color(0xFF7C3ABA))
                  else
                    const SizedBox(width: 20, height: 20),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ThemeOption {
  const _ThemeOption({required this.label, required this.color});

  final String label;
  final Color color;
}
