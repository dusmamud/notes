import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';

class WelcomeTourScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const WelcomeTourScreen({super.key, required this.onComplete});

  @override
  State<WelcomeTourScreen> createState() => _WelcomeTourScreenState();
}

class _WelcomeTourScreenState extends State<WelcomeTourScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_TourSlide> _slides = [
    _TourSlide(
      icon: Icons.edit_note_rounded,
      color: AppColors.accentGold,
      section: "Writing",
      title: "Write Naturally",
      description:
          "The pencil button at the bottom of any list starts a new note. Start typing—the first line becomes the title, and your notes auto-save continuously.",
      bullets: [
        "Headings, bold, italic & highlight colors",
        "Interactive checklists with automatic sorting",
        "Multi-column tables with row & column controls",
      ],
    ),
    _TourSlide(
      icon: Icons.attach_file_rounded,
      color: AppColors.tagBlue,
      section: "Attachments",
      title: "Rich Media & Documents",
      description:
          "Attach files, scan multi-page documents, and record voice notes directly inside your notes.",
      bullets: [
        "Camera & document scanner with auto-crop",
        "Live voice memos with audio transcription",
        "Embedded PDF reader with fast page navigation",
      ],
    ),
    _TourSlide(
      icon: Icons.functions_rounded,
      color: AppColors.tagCoral,
      section: "Smart Features",
      title: "Math Notes & Linking",
      description:
          "Perform calculations in your notes and see results as you type. Type >> to link other notes seamlessly.",
      bullets: [
        "Interactive Math Notes with variable support",
        "Deep note linking with section anchors (/)",
        "Instant search across titles, tags & attachments",
      ],
    ),
    _TourSlide(
      icon: Icons.palette_outlined,
      color: AppColors.tagPurple,
      section: "Personalize",
      title: "Glass & Classic Styles",
      description:
          "Choose between an iOS-inspired fluid Glassmorphism interface or solid Classic design with smooth spring animations.",
      bullets: [
        "Pretenda variable typography with scaling",
        "Pastel card tints: Yellow, Mint, Lavender, Peach, Sky",
        "Adaptive split view for tablets & foldables",
      ],
    ),
    _TourSlide(
      icon: Icons.shield_outlined,
      color: AppColors.tagTeal,
      section: "Privacy & Backup",
      title: "Secure & Always Backed Up",
      description:
          "Your thoughts stay private on your device. Set an app passcode or lock individual sensitive notes.",
      bullets: [
        "Biometric & passcode security gate",
        "Automatic scheduled local device backups",
        "Hide preview on Android Recents screen",
      ],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    HapticFeedback.lightImpact();
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final slide = _slides[_currentPage];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkScaffold : AppColors.lightScaffold,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar with Skip button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "User Guide",
                    style: AppTypography.headingSmall.copyWith(
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      widget.onComplete();
                    },
                    child: Text(
                      "Skip",
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Interactive Tour Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final s = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Icon in Squircle Container
                        Container(
                          width: 88,
                          height: 88,
                          decoration: ShapeDecoration(
                            color: s.color.withValues(alpha: 0.15),
                            shape: const ContinuousRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(28)),
                            ),
                          ),
                          child: Icon(s.icon, color: s.color, size: 44),
                        ),
                        const SizedBox(height: 24),
                        // Section Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: ShapeDecoration(
                            color: s.color.withValues(alpha: 0.12),
                            shape: const StadiumBorder(),
                          ),
                          child: Text(
                            s.section.toUpperCase(),
                            style: TextStyle(
                              color: s.color,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Title
                        Text(
                          s.title,
                          style: AppTypography.headingLarge.copyWith(fontSize: 26),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        // Description
                        Text(
                          s.description,
                          style: AppTypography.bodyMedium.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        // Bullets
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: ShapeDecoration(
                            color: isDark ? AppColors.surfaceDark : AppColors.lightCardBg,
                            shape: const ContinuousRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(18)),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: s.bullets.map((b) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle_rounded, size: 16, color: s.color),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        b,
                                        style: AppTypography.bodySmall.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Bottom Indicator & CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                children: [
                  // Page Indicator Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? slide.color
                              : (isDark ? Colors.white24 : Colors.black12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGold,
                        foregroundColor: Colors.black,
                        shape: const ContinuousRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _onNext,
                      child: Text(
                        _currentPage == _slides.length - 1 ? "Get Started" : "Continue",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TourSlide {
  final IconData icon;
  final Color color;
  final String section;
  final String title;
  final String description;
  final List<String> bullets;

  const _TourSlide({
    required this.icon,
    required this.color,
    required this.section,
    required this.title,
    required this.description,
    required this.bullets,
  });
}

