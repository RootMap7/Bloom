import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'individual_profile_screen.dart';

enum _NotificationKind { alert, love, reminder }

class _NotificationItem {
  const _NotificationItem({
    required this.kind,
    required this.title,
    required this.timeLabel,
    this.unread = false,
  });

  final _NotificationKind kind;
  final String title;
  final String timeLabel;
  final bool unread;
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<_NotificationItem> _items = const [
    _NotificationItem(
      kind: _NotificationKind.alert,
      title: 'Alert: New Features unlocked\nwith the new update',
      timeLabel: 'Just now',
      unread: true,
    ),
    _NotificationItem(
      kind: _NotificationKind.love,
      title: 'Love sent you a note',
      timeLabel: '1h ago',
      unread: true,
    ),
    _NotificationItem(
      kind: _NotificationKind.love,
      title: 'Love added a new item on the\nbucket-list',
      timeLabel: '2h ago',
      unread: true,
    ),
    _NotificationItem(
      kind: _NotificationKind.love,
      title: 'Love liked items on your wish-list',
      timeLabel: '2h ago',
      unread: true,
    ),
    _NotificationItem(
      kind: _NotificationKind.love,
      title: 'Love liked your note',
      timeLabel: '2h ago',
      unread: true,
    ),
    _NotificationItem(
      kind: _NotificationKind.reminder,
      title: 'Reminder: Your anniversary is in 5 days',
      timeLabel: '4h ago',
      unread: false,
    ),
    _NotificationItem(
      kind: _NotificationKind.reminder,
      title: 'Reminder: Gamenight @ Nia’s is this\nFriday 6 PM',
      timeLabel: 'Yesterday',
      unread: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.manrope(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: const Color(0xFFFFF8F6),
        child: SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 76, 20, 140),
            itemBuilder: (context, index) => _buildNotificationCard(_items[index]),
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemCount: _items.length,
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  ({IconData icon, Color color}) _kindVisuals(_NotificationKind kind) {
    switch (kind) {
      case _NotificationKind.alert:
        return (icon: Icons.campaign_outlined, color: const Color(0xFF7C3ABA));
      case _NotificationKind.love:
        return (icon: Icons.favorite, color: const Color(0xFFFF3B30));
      case _NotificationKind.reminder:
        return (icon: Icons.notifications_none, color: const Color(0xFF34C759));
    }
  }

  Widget _buildNotificationCard(_NotificationItem item) {
    final visuals = _kindVisuals(item.kind);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: visuals.color, width: 2),
            ),
            child: Center(
              child: Icon(
                visuals.icon,
                color: visuals.color,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F1F1F),
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.timeLabel,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFB6B0B0),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (item.unread)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xFF7C3ABA),
                  shape: BoxShape.circle,
                ),
              ),
            )
          else
            const SizedBox(width: 12, height: 12),
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
            color: Colors.black.withValues(alpha: 0.05),
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
    // In this screen, home is always active if we came from there, 
    // or we can just show no active tab if we want.
    // Given the image, the first tab (home) seems to have a purple bar above it.
    final isActive = index == 0; 
    final color = isActive ? const Color(0xFF7C3ABA) : const Color(0xFF4D4B4B);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isActive)
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3ABA),
              borderRadius: BorderRadius.circular(2),
            ),
          )
        else
          const SizedBox(height: 3),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () {
            if (index == 0) {
              Navigator.of(context).pop();
              return;
            }
            if (index == 4) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const IndividualProfileScreen()),
              );
            }
            // Other tabs can be implemented later
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
        ),
      ],
    );
  }
}
