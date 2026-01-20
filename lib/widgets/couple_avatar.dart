import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CoupleAvatar extends StatelessWidget {
  final String? userProfileImageUrl;
  final String? partnerProfileImageUrl;
  final bool hasPartner;
  final VoidCallback? onTap;
  final double size;

  const CoupleAvatar({
    super.key,
    this.userProfileImageUrl,
    this.partnerProfileImageUrl,
    required this.hasPartner,
    this.onTap,
    this.size = 49,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size + (size * 0.35), // Extra width for overlap
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // User profile picture (base, left, slightly behind)
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF7C3ABA),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: (size - 4) / 2, // Account for border
                  backgroundColor: Colors.white,
                  backgroundImage: userProfileImageUrl != null
                      ? NetworkImage(userProfileImageUrl!)
                      : null,
                  child: userProfileImageUrl == null
                      ? Icon(
                          Icons.person,
                          color: Colors.grey[400],
                          size: size * 0.57,
                        )
                      : null,
                ),
              ),
            ),
            // Partner avatar or add button (on top, offset to right)
            Positioned(
              left: size * 0.35, // 35% overlap
              top: 0,
              child: hasPartner
                  ? Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF7C3ABA),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: (size - 4) / 2,
                        backgroundColor: Colors.white,
                        backgroundImage: partnerProfileImageUrl != null
                            ? NetworkImage(partnerProfileImageUrl!)
                            : null,
                        child: partnerProfileImageUrl == null
                            ? Icon(
                                Icons.person,
                                color: Colors.grey[400],
                                size: size * 0.57,
                              )
                            : null,
                      ),
                    )
                  : Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF7C3ABA),
                            Color(0xFFC8A8E9),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add,
                        color: Colors.white,
                        size: size * 0.49,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

