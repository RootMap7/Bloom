import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';

class PlanSavedScreen extends StatelessWidget {
  const PlanSavedScreen({
    super.key,
    required this.title,
    required this.location,
    required this.dateLabel,
    required this.timeLabel,
    required this.themeColor,
    required this.planDateTime,
    required this.description,
  });

  final String title;
  final String location;
  final String dateLabel;
  final String timeLabel;
  final Color themeColor;
  final DateTime? planDateTime;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              Text(
                'Its a date!',
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your plan is saved and added to your\nshared calendar.',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6E6A6A),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFF7C3ABA),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white),
              ),
              const SizedBox(height: 22),
              _buildPlanCard(),
              const SizedBox(height: 18),
              _buildNotificationCard(),
              const Spacer(),
              _buildPrimaryButton(
                label: 'Export to Calendar',
                onPressed: () => _exportToCalendar(context),
                filled: true,
              ),
              const SizedBox(height: 14),
              _buildPrimaryButton(
                label: 'Done',
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
                  );
                },
                filled: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: themeColor,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            location,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 80),
          Text(
            dateLabel,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            timeLabel,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF6EB4FF), width: 2),
            ),
            child: const Icon(
              Icons.notifications_none,
              color: Color(0xFF6EB4FF),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'We\'ve notified Cate!',
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4D4B4B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onPressed,
    required bool filled,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: filled ? const Color(0xFF7C3ABA) : Colors.white,
          foregroundColor: filled ? Colors.white : const Color(0xFF7C3ABA),
          side: filled ? null : const BorderSide(color: Color(0xFF7C3ABA)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _exportToCalendar(BuildContext context) async {
    final startDate = planDateTime;
    if (startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a date and time to export.')),
      );
      return;
    }

    final event = Event(
      title: title,
      description: description,
      location: location,
      startDate: startDate,
      endDate: startDate.add(const Duration(hours: 2)),
    );

    await Add2Calendar.addEvent2Cal(event);
  }
}
