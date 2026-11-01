import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';

enum AttachmentAction {
  scanDocument,
  takePhoto,
  photoLibrary,
  recordAudio,
  chooseFile,
}

class AttachmentSelectorSheet extends StatelessWidget {
  final ValueChanged<AttachmentAction> onActionSelected;

  const AttachmentSelectorSheet({
    super.key,
    required this.onActionSelected,
  });

  static Future<void> show(BuildContext context, ValueChanged<AttachmentAction> onAction) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => AttachmentSelectorSheet(onActionSelected: onAction),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusSheet),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
        vertical: AppDimensions.paddingMedium,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            const SizedBox(height: 16),
            Text(
              "Add to Note",
              style: AppTypography.headingSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _SheetTile(
              icon: Icons.document_scanner_rounded,
              color: AppColors.accentGold,
              title: "Scan Documents",
              subtitle: "Detect edges and scan multipage PDF",
              onTap: () {
                Navigator.of(context).pop();
                onActionSelected(AttachmentAction.scanDocument);
              },
            ),
            _SheetTile(
              icon: Icons.camera_alt_rounded,
              color: AppColors.tagCoral,
              title: "Take Photo or Video",
              subtitle: "Capture with device camera",
              onTap: () {
                Navigator.of(context).pop();
                onActionSelected(AttachmentAction.takePhoto);
              },
            ),
            _SheetTile(
              icon: Icons.photo_library_rounded,
              color: AppColors.tagBlue,
              title: "Photo Library",
              subtitle: "Select images from your gallery",
              onTap: () {
                Navigator.of(context).pop();
                onActionSelected(AttachmentAction.photoLibrary);
              },
            ),
            _SheetTile(
              icon: Icons.mic_rounded,
              color: AppColors.tagTeal,
              title: "Record Audio",
              subtitle: "Record voice memo inside note",
              onTap: () {
                Navigator.of(context).pop();
                onActionSelected(AttachmentAction.recordAudio);
              },
            ),
            _SheetTile(
              icon: Icons.folder_open_rounded,
              color: AppColors.tagPurple,
              title: "Attach File / PDF",
              subtitle: "Import external document",
              onTap: () {
                Navigator.of(context).pop();
                onActionSelected(AttachmentAction.chooseFile);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SheetTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: AppTypography.headingSmall.copyWith(fontSize: 15)),
      subtitle: Text(subtitle, style: AppTypography.captionSmall),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
    );
  }
}

