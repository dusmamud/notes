import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/models/note_entity.dart';

class NoteCard extends StatelessWidget {
  final NoteEntity note;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ValueChanged<bool>? onPinToggle;
  final VoidCallback? onDelete;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectToggle;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onLongPress,
    this.onPinToggle,
    this.onDelete,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = note.colorValue != null
        ? Color(note.colorValue!)
        : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);

    // Analyze content for badges
    int checklistTotal = 0;
    int checklistDone = 0;
    bool hasAudio = note.contentMarkdown.contains('🎙️ Voice Memo');
    bool hasScannedPdf = note.contentMarkdown.contains('📄 [Scanned Document PDF]');
    final lines = note.contentMarkdown.split('\n');
    for (final l in lines) {
      final t = l.trim();
      if (t.startsWith('- [ ]') || t.startsWith('[]')) {
        checklistTotal++;
      } else if (t.startsWith('- [x]') || t.startsWith('- [X]')) {
        checklistTotal++;
        checklistDone++;
      }
    }

    final cardContent = Hero(
      tag: 'note_${note.id}',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: isSelectionMode ? () => onSelectToggle?.call(!isSelected) : onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
          child: Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
              border: Border.all(
                color: isSelected
                    ? AppColors.accentGold
                    : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)),
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isSelectionMode) ...[
                      Checkbox(
                        value: isSelected,
                        fillColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected)
                              ? AppColors.accentGold
                              : Colors.transparent,
                        ),
                        shape: const CircleBorder(),
                        onChanged: onSelectToggle,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        note.title.isNotEmpty ? note.title : "Untitled Note",
                        style: AppTypography.headingSmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (note.isPinned)
                      const Padding(
                        padding: EdgeInsets.only(left: 4.0),
                        child: Icon(Icons.push_pin_rounded, size: 16, color: AppColors.accentGold),
                      ),
                    if (note.isLocked)
                      const Padding(
                        padding: EdgeInsets.only(left: 4.0),
                        child: Icon(Icons.lock_rounded, size: 16, color: AppColors.textSecondaryLight),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                if (note.isLocked)
                  Row(
                    children: [
                      const Icon(Icons.lock_outline, size: 14, color: AppColors.textSecondaryLight),
                      const SizedBox(width: 4),
                      Text(
                        "Locked Note",
                        style: AppTypography.captionMedium.copyWith(fontStyle: FontStyle.italic),
                      ),
                    ],
                  )
                else if (note.contentMarkdown.isNotEmpty)
                  Text(
                    note.contentMarkdown,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(note.updatedAt),
                      style: AppTypography.captionSmall,
                    ),
                    Wrap(
                      spacing: 4,
                      children: [
                        if (checklistTotal > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.tagForest.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_outline_rounded, size: 10, color: AppColors.tagForest),
                                const SizedBox(width: 3),
                                Text(
                                  "$checklistDone/$checklistTotal",
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.tagForest,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (hasAudio)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accentBlue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.mic_none_rounded, size: 10, color: AppColors.accentBlue),
                                SizedBox(width: 3),
                                Text(
                                  "Audio",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accentBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (hasScannedPdf)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.tagCoral.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.document_scanner_outlined, size: 10, color: AppColors.tagCoral),
                                SizedBox(width: 3),
                                Text(
                                  "Scan",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.tagCoral,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (note.mathResultsMode != 'off')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accentGold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              "∑ Math",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accentGold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (isSelectionMode) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: cardContent,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Slidable(
        key: ValueKey(note.id),
        startActionPane: ActionPane(
          motion: const BehindMotion(),
          children: [
            SlidableAction(
              onPressed: (_) {
                HapticFeedback.selectionClick();
                onPinToggle?.call(!note.isPinned);
              },
              backgroundColor: AppColors.accentGold,
              foregroundColor: Colors.white,
              icon: note.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
              label: note.isPinned ? 'Unpin' : 'Pin',
              borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          children: [
            SlidableAction(
              onPressed: (_) {
                HapticFeedback.lightImpact();
                onDelete?.call();
              },
              backgroundColor: AppColors.tagCoral,
              foregroundColor: Colors.white,
              icon: Icons.delete_outline_rounded,
              label: 'Trash',
              borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
            ),
          ],
        ),
        child: cardContent,
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } else if (diff.inDays == 1) {
      return "Yesterday";
    } else if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dt.weekday - 1];
    } else {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return "${months[dt.month - 1]} ${dt.day}";
    }
  }
}
