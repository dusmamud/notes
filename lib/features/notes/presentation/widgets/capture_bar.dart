import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

class CaptureBar extends StatelessWidget {
  final VoidCallback onNewNote;
  final VoidCallback onNewChecklist;
  final VoidCallback onRecordAudio;
  final VoidCallback onScanDocument;

  const CaptureBar({
    super.key,
    required this.onNewNote,
    required this.onNewChecklist,
    required this.onRecordAudio,
    required this.onScanDocument,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        height: AppDimensions.heightCaptureBar,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark.withValues(alpha: 0.92) : Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black12,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CaptureIconButton(
              icon: Icons.edit_note_rounded,
              tooltip: "New Note",
              onTap: onNewNote,
            ),
            const SizedBox(width: 8),
            _CaptureIconButton(
              icon: Icons.checklist_rounded,
              tooltip: "New Checklist",
              onTap: onNewChecklist,
            ),
            const SizedBox(width: 8),
            _CaptureIconButton(
              icon: Icons.mic_rounded,
              tooltip: "Voice Memo",
              onTap: onRecordAudio,
            ),
            const SizedBox(width: 8),
            _CaptureIconButton(
              icon: Icons.camera_alt_rounded,
              tooltip: "Scan Document",
              onTap: onScanDocument,
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _CaptureIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      iconSize: 26,
      tooltip: tooltip,
      color: AppColors.accentGold,
      splashRadius: 24,
      onPressed: () {
        HapticFeedback.lightImpact();
        onTap();
      },
    );
  }
}

