import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';

enum ListStructureType {
  bulletList,
  dashList,
  numberedList,
  blockquote,
  codeBlock,
  divider,
  noteLink,
}

class ListsStructurePanel extends StatelessWidget {
  final ValueChanged<ListStructureType> onSelect;
  final VoidCallback onClose;

  const ListsStructurePanel({
    super.key,
    required this.onSelect,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF7F7F7),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : Colors.black12,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.format_list_bulleted_rounded, size: 18, color: AppColors.accentGold),
              const SizedBox(width: 8),
              const Text("LISTS & STRUCTURE", style: AppTypography.captionSmall),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildItem("Bullet List", Icons.format_list_bulleted_rounded, () => onSelect(ListStructureType.bulletList)),
                _buildItem("Dashed List", Icons.remove_rounded, () => onSelect(ListStructureType.dashList)),
                _buildItem("Numbered List", Icons.format_list_numbered_rounded, () => onSelect(ListStructureType.numberedList)),
                _buildItem("Blockquote", Icons.format_quote_rounded, () => onSelect(ListStructureType.blockquote)),
                _buildItem("Code Block", Icons.code_rounded, () => onSelect(ListStructureType.codeBlock)),
                _buildItem("Divider", Icons.horizontal_rule_rounded, () => onSelect(ListStructureType.divider)),
                _buildItem("Note Link (>>)", Icons.link_rounded, () => onSelect(ListStructureType.noteLink)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ActionChip(
        avatar: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onPressed: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

