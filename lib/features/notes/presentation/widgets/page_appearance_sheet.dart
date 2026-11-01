import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/models/note_entity.dart';

class PageAppearanceSheet extends StatefulWidget {
  final NoteEntity note;
  final VoidCallback onAppearanceChanged;

  const PageAppearanceSheet({
    super.key,
    required this.note,
    required this.onAppearanceChanged,
  });

  static Future<void> show(
    BuildContext context,
    NoteEntity note,
    VoidCallback onChanged,
  ) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => PageAppearanceSheet(note: note, onAppearanceChanged: onChanged),
    );
  }

  @override
  State<PageAppearanceSheet> createState() => _PageAppearanceSheetState();
}

class _PageAppearanceSheetState extends State<PageAppearanceSheet> {
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
              "Page Appearance",
              style: AppTypography.headingSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text("NOTE COLOR", style: AppTypography.captionSmall.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            // Horizontal palette selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ColorOption(
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    isSelected: widget.note.colorValue == null,
                    label: "Default",
                    onTap: () {
                      setState(() => widget.note.colorValue = null);
                      widget.onAppearanceChanged();
                    },
                  ),
                  ...AppColors.pastelPalette.map((col) {
                    return _ColorOption(
                      color: col,
                      isSelected: widget.note.colorValue == col.toARGB32(),
                      onTap: () {
                        setState(() => widget.note.colorValue = col.toARGB32());
                        widget.onAppearanceChanged();
                      },
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text("TEXT SIZE", style: AppTypography.captionSmall.copyWith(fontWeight: FontWeight.bold)),
            Row(
              children: [
                const Text("A", style: TextStyle(fontSize: 14)),
                Expanded(
                  child: Slider(
                    value: widget.note.textScale,
                    min: 0.8,
                    max: 1.5,
                    divisions: 7,
                    activeColor: AppColors.accentGold,
                    onChanged: (val) {
                      setState(() => widget.note.textScale = val);
                      widget.onAppearanceChanged();
                    },
                  ),
                ),
                const Text("A", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ColorOption extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final String? label;
  final VoidCallback onTap;

  const _ColorOption({
    required this.color,
    required this.isSelected,
    this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.accentGold : Colors.grey.withValues(alpha: 0.4),
            width: isSelected ? 3.0 : 1.0,
          ),
        ),
        alignment: Alignment.center,
        child: label != null
            ? Text(label!, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold))
            : (isSelected ? const Icon(Icons.check_rounded, size: 20, color: Colors.black87) : null),
      ),
    );
  }
}

