import 'supabase_service.dart';

class StreakData {
  final int currentStreak;
  final List<bool> weeklyStreak;
  final DateTime? lastActivityDate;

  StreakData({
    required this.currentStreak,
    required this.weeklyStreak,
    this.lastActivityDate,
  });
}

/// Service for calculating and tracking couple activity streaks
/// 
/// IMPORTANT: Streaks are COUPLE-BASED, meaning:
/// - Activity from EITHER partner counts toward the shared streak
/// - Both partners contribute to the same daily activity record
/// - The streak is maintained as long as at least ONE partner is active
class StreakService {
  /// Calculate the current streak for a couple based on daily activities
  /// 
  /// This fetches all daily_activities records for the couple and calculates:
  /// - Current consecutive streak (how many days in a row with activity)
  /// - Weekly streak pattern (which days this week had activity from either partner)
  static Future<StreakData> calculateStreak(String coupleId) async {
    try {
      // Fetch daily activities for the couple, ordered by date descending
      final response = await SupabaseService.client
          .from('daily_activities')
          .select('activity_date')
          .eq('couple_id', coupleId)
          .order('activity_date', ascending: false)
          .limit(365); // Get up to a year of data

      if (response.isEmpty) {
        return StreakData(
          currentStreak: 0,
          weeklyStreak: List.filled(7, false),
        );
      }

      final activities = response as List;
      final activityDates = activities
          .map((a) => DateTime.parse(a['activity_date'] as String))
          .toList();

      // Calculate current streak
      final currentStreak = _calculateCurrentStreak(activityDates);

      // Calculate weekly streak (last 7 days)
      final weeklyStreak = _calculateWeeklyStreak(activityDates);

      // Get last activity date
      final lastActivityDate = activityDates.isNotEmpty ? activityDates.first : null;

      return StreakData(
        currentStreak: currentStreak,
        weeklyStreak: weeklyStreak,
        lastActivityDate: lastActivityDate,
      );
    } catch (e) {
      // Return empty streak data on error
      return StreakData(
        currentStreak: 0,
        weeklyStreak: List.filled(7, false),
      );
    }
  }

  /// Calculate current consecutive streak
  static int _calculateCurrentStreak(List<DateTime> activityDates) {
    if (activityDates.isEmpty) return 0;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    // Check if there was activity today or yesterday
    final mostRecentDate = DateTime(
      activityDates.first.year,
      activityDates.first.month,
      activityDates.first.day,
    );
    
    final daysSinceLastActivity = todayDate.difference(mostRecentDate).inDays;
    
    // If more than 1 day has passed, streak is broken
    if (daysSinceLastActivity > 1) {
      return 0;
    }

    // Count consecutive days
    int streak = 0;
    DateTime expectedDate = todayDate;

    for (final activityDate in activityDates) {
      final dateOnly = DateTime(
        activityDate.year,
        activityDate.month,
        activityDate.day,
      );

      // Check if this date matches our expected date
      if (dateOnly == expectedDate) {
        streak++;
        expectedDate = expectedDate.subtract(const Duration(days: 1));
      } else if (dateOnly.isBefore(expectedDate)) {
        // Gap found, streak is broken
        break;
      }
    }

    return streak;
  }

  /// Calculate which days in the current week have activity
  /// Returns a list of 7 booleans (Monday to Sunday)
  static List<bool> _calculateWeeklyStreak(List<DateTime> activityDates) {
    final weeklyStreak = List.filled(7, false);
    
    if (activityDates.isEmpty) return weeklyStreak;

    final today = DateTime.now();
    
    // Get the Monday of the current week
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final mondayDate = DateTime(monday.year, monday.month, monday.day);

    // Check each day of the week
    for (int i = 0; i < 7; i++) {
      final checkDate = mondayDate.add(Duration(days: i));
      
      // Check if any activity falls on this date
      for (final activityDate in activityDates) {
        final dateOnly = DateTime(
          activityDate.year,
          activityDate.month,
          activityDate.day,
        );
        
        if (dateOnly == checkDate) {
          weeklyStreak[i] = true;
          break;
        }
      }
    }

    return weeklyStreak;
  }

  /// Record an activity for today (called after user performs a trackable action)
  static Future<void> recordActivity() async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return;

      // Get the user's couple_id
      final profileResponse = await SupabaseService.client
          .from('user_profiles')
          .select('couple_id')
          .eq('id', user.id)
          .maybeSingle();

      final coupleId = profileResponse?['couple_id'] as String?;
      if (coupleId == null) return;

      // The trigger will handle the insert/update automatically
      // This is just a manual way to ensure activity is recorded
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      await SupabaseService.client
          .from('daily_activities')
          .upsert({
            'couple_id': coupleId,
            'activity_date': todayDate.toIso8601String().split('T')[0],
            'activity_count': 1,
          })
          .select()
          .maybeSingle();
    } catch (e) {
      // Silently fail - activity recording is not critical
    }
  }
}
