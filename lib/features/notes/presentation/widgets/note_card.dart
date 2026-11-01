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

    final cardContent = InkWell(
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
                : (isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
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
                    activeColor: AppColors.accentGold,
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
                if (note.mathResultsMode != 'off')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withOpacity(0.15),
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
