import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/models/note_entity.dart';

enum NoteContextAction {
  pin,
  lock,
  duplicate,
  moveToFolder,
  share,
  trash,
}

class NoteContextMenuDialog extends StatelessWidget {
  final NoteEntity note;
  final ValueChanged<NoteContextAction> onAction;

  const NoteContextMenuDialog({
    super.key,
    required this.note,
    required this.onAction,
  });

  static Future<void> show(
    BuildContext context,
    NoteEntity note,
    ValueChanged<NoteContextAction> onAction,
  ) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      pageBuilder: (dialogContext, _, _) => NoteContextMenuDialog(note: note, onAction: onAction),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pop-in Card Preview
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  decoration: BoxDecoration(
                    color: note.colorValue != null
                        ? Color(note.colorValue!)
                        : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title.isNotEmpty ? note.title : "Untitled Note",
                        style: AppTypography.headingSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        note.contentMarkdown.isNotEmpty ? note.contentMarkdown : "No text",
                        style: AppTypography.bodySmall,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Action Menu Block
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _MenuItem(
                        icon: note.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
                        title: note.isPinned ? "Unpin" : "Pin",
                        onTap: () {
                          Navigator.of(context).pop();
                          onAction(NoteContextAction.pin);
                        },
                      ),
                      const Divider(height: 0.5),
                      _MenuItem(
                        icon: note.isLocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                        title: note.isLocked ? "Unlock Note" : "Lock Note",
                        onTap: () {
                          Navigator.of(context).pop();
                          onAction(NoteContextAction.lock);
                        },
                      ),
                      const Divider(height: 0.5),
                      _MenuItem(
                        icon: Icons.copy_rounded,
                        title: "Duplicate",
                        onTap: () {
                          Navigator.of(context).pop();
                          onAction(NoteContextAction.duplicate);
                        },
                      ),
                      const Divider(height: 0.5),
                      _MenuItem(
                        icon: Icons.folder_open_rounded,
                        title: "Move to Folder",
                        onTap: () {
                          Navigator.of(context).pop();
                          onAction(NoteContextAction.moveToFolder);
                        },
                      ),
                      const Divider(height: 0.5),
                      _MenuItem(
                        icon: Icons.share_rounded,
                        title: "Share",
                        onTap: () {
                          Navigator.of(context).pop();
                          onAction(NoteContextAction.share);
                        },
                      ),
                      const Divider(height: 0.5),
                      _MenuItem(
                        icon: Icons.delete_outline_rounded,
                        title: "Move to Trash",
                        isDestructive: true,
                        onTap: () {
                          Navigator.of(context).pop();
                          onAction(NoteContextAction.trash);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDestructive;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.tagCoral : null;

    return ListTile(
      leading: Icon(icon, color: color, size: 20),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      dense: true,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
    );
  }
}

