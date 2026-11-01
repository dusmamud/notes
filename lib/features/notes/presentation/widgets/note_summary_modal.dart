import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/models/note_entity.dart';

class NoteSummaryModal extends StatelessWidget {
  final NoteEntity note;

  const NoteSummaryModal({super.key, required this.note});

  static void show(BuildContext context, NoteEntity note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NoteSummaryModal(note: note),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = "${note.title}\n${note.contentMarkdown}";

    // Metrics calculations
    final words = text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
    final characters = text.length;
    final readingTimeMinutes = (words / 200).ceil().clamp(1, 999);

    // Checklist count
    final lines = text.split('\n');
    int totalChecklists = 0;
    int completedChecklists = 0;
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('- [ ]') || trimmed.startsWith('[]')) {
        totalChecklists++;
      } else if (trimmed.startsWith('- [x]') || trimmed.startsWith('- [X]')) {
        totalChecklists++;
        completedChecklists++;
      }
    }

    // Detected links
    final urlRegex = RegExp(r'https?://[^\s]+|>>[^\s\n]+');
    final detectedLinks = urlRegex.allMatches(text).map((m) => m.group(0)!).toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.analytics_outlined, color: AppColors.accentGold),
                  const SizedBox(width: 8),
                  Text("Note Summary & Overview", style: AppTypography.headingMedium),
                ],
              ),
              const SizedBox(height: 16),

              // Overview Grid
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard("Words", "$words", isDark),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard("Characters", "$characters", isDark),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard("Reading Time", "$readingTimeMinutes min", isDark),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Checklist Stats
              if (totalChecklists > 0) ...[
                Text("TASKS & CHECKLIST", style: AppTypography.captionSmall),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text("Total Tasks: $totalChecklists", style: AppTypography.bodyMedium),
                      Text("Done: $completedChecklists", style: AppTypography.bodyMedium.copyWith(color: AppColors.tagForest)),
                      Text("Pending: ${totalChecklists - completedChecklists}", style: AppTypography.bodyMedium.copyWith(color: AppColors.tagCoral)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Detected Links
              if (detectedLinks.isNotEmpty) ...[
                Text("DETECTED LINKS (${detectedLinks.length})", style: AppTypography.captionSmall),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 140),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: detectedLinks.length,
                    separatorBuilder: (_, _) => const Divider(height: 8),
                    itemBuilder: (_, i) => Text(
                      detectedLinks[i],
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.tagSky,
                        decoration: TextDecoration.underline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.accentGold),
                  child: const Text("Done", style: TextStyle(color: Colors.black)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: AppTypography.headingMedium.copyWith(color: AppColors.accentGold)),
          const SizedBox(height: 4),
          Text(title, style: AppTypography.captionSmall),
        ],
      ),
    );
  }
}

