import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_sheets/smooth_sheets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';

class WhatsNewSheet extends StatelessWidget {
  static const int currentVersionCode = 1089;

  final bool isGlassStyle;

  const WhatsNewSheet({super.key, this.isGlassStyle = true});

  static Future<void> showIfNeeded(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final lastSeenVersion = prefs.getInt('last_seen_version_code') ?? 0;
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    // Trigger What's New if the app was updated to a newer version
    // (Only for existing users who already completed onboarding)
    if (hasSeenOnboarding && lastSeenVersion < currentVersionCode && context.mounted) {
      final uiStyle = prefs.getString('ui_style_appearance') ?? 'glass';
      final isGlass = uiStyle == 'glass';

      await showModalSheet(
        context: context,
        barrierDismissible: true,
        builder: (_) => WhatsNewSheet(isGlassStyle: isGlass),
      );

      await prefs.setInt('last_seen_version_code', currentVersionCode);
      await prefs.setBool('has_seen_whats_new', true);
    }
  }

  static Future<void> show(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final uiStyle = prefs.getString('ui_style') ?? 'glass';
    final isGlass = uiStyle == 'glass';
    if (!context.mounted) return;
    await showModalSheet(
      context: context,
      barrierDismissible: true,
      builder: (_) => WhatsNewSheet(isGlassStyle: isGlass),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget sheetContent = Container(
      decoration: BoxDecoration(
        color: isGlassStyle
            ? (isDark
                ? const Color(0xB22C2C2E)
                : const Color(0xB2FFFFFF))
            : (isDark ? AppColors.surfaceDark : AppColors.lightCardBg),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusSheet),
        ),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
          width: 0.5,
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingLarge,
        vertical: AppDimensions.paddingMedium,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black26,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              SizedBox(height: AppDimensions.paddingLarge),
              // Header Title
              Text(
                "What's New in Notes",
                style: AppTypography.headingLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppDimensions.paddingSmall),
              // Header Subtitle
              Text(
                "Everything Notes can do, where to find it, and how to use it.",
                style: AppTypography.captionMedium.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppDimensions.paddingLarge),
              // Target Row 1: Math Notes
              const _FeatureRow(
                icon: Icons.functions_rounded,
                color: AppColors.accentGold,
                title: "Math Notes",
                description:
                    "Perform calculations in your notes and see the result as you type.",
              ),
              // Target Row 2: Note Links
              const _FeatureRow(
                icon: Icons.link_rounded,
                color: AppColors.tagBlue,
                title: "Note Links",
                description:
                    "Tap the link icon in the toolbar or type >> to link another note. After linking a note, type / to link one of its sections.",
              ),
              // Target Row 3: Audio Transcription
              const _FeatureRow(
                icon: Icons.mic_rounded,
                color: AppColors.tagCoral,
                title: "Audio Transcription",
                description:
                    "Record voice notes and see your words transcribed as you speak.",
              ),
              // Target Row 4: Quick Bar Widget
              const _FeatureRow(
                icon: Icons.grid_view_rounded,
                color: AppColors.tagTeal,
                title: "Quick Bar Widget",
                description:
                    "Start a new note right from your Home Screen with the Quick Bar widget.",
              ),
              // Target Row 5: Glass & Classic Style
              const _FeatureRow(
                icon: Icons.auto_awesome_rounded,
                color: AppColors.tagPurple,
                title: "Glass & Classic Style",
                description:
                    "Enjoy a glass-inspired interface with smooth animations. Switch back to the Classic theme anytime in Settings > Appearance > Style.",
              ),
              SizedBox(height: AppDimensions.paddingLarge),
              // Continue Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const ContinuousRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
                child: const Text(
                  "Continue",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              SizedBox(height: AppDimensions.paddingSmall),
            ],
          ),
        ),
      ),
    );

    if (isGlassStyle) {
      sheetContent = ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusSheet),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: sheetContent,
        ),
      );
    }

    return Sheet(
      physics: const BouncingSheetPhysics(),
      child: sheetContent,
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _FeatureRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: ShapeDecoration(
              color: color.withValues(alpha: 0.15),
              shape: const ContinuousRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: AppDimensions.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.headingSmall),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
