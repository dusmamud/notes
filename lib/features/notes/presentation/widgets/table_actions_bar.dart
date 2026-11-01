import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';

enum TableActionType {
  addColumnLeft,
  addColumnRight,
  addRowAbove,
  addRowBelow,
  deleteColumn,
  deleteRow,
  reverseDirection,
  convertToText,
  copyTable,
  shareTable,
  deleteTable,
}

class TableActionsBar extends StatelessWidget {
  final ValueChanged<TableActionType> onAction;
  final VoidCallback onClose;

  const TableActionsBar({
    super.key,
    required this.onAction,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF7F7F7),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
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
              const Icon(Icons.table_chart_outlined, size: 18, color: AppColors.accentGold),
              const SizedBox(width: 8),
              const Text("TABLE ACTIONS", style: AppTypography.captionSmall),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildButton("+ Col Left", Icons.add_box_outlined, () => onAction(TableActionType.addColumnLeft)),
                _buildButton("+ Col Right", Icons.add_box_rounded, () => onAction(TableActionType.addColumnRight)),
                _buildButton("+ Row Above", Icons.table_rows_outlined, () => onAction(TableActionType.addRowAbove)),
                _buildButton("+ Row Below", Icons.table_rows_rounded, () => onAction(TableActionType.addRowBelow)),
                _buildButton("Del Col", Icons.delete_sweep_outlined, () => onAction(TableActionType.deleteColumn)),
                _buildButton("Del Row", Icons.remove_circle_outline, () => onAction(TableActionType.deleteRow)),
                _buildButton("Flip LTR/RTL", Icons.swap_horiz_rounded, () => onAction(TableActionType.reverseDirection)),
                _buildButton("Convert to Text", Icons.text_fields_rounded, () => onAction(TableActionType.convertToText)),
                _buildButton("Copy Table", Icons.copy_rounded, () => onAction(TableActionType.copyTable)),
                _buildButton("Share Table", Icons.share_rounded, () => onAction(TableActionType.shareTable)),
                _buildButton("Delete Table", Icons.delete_outline_rounded, () => onAction(TableActionType.deleteTable), isDestructive: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String label, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          foregroundColor: isDestructive ? AppColors.tagCoral : null,
          side: isDestructive ? const BorderSide(color: AppColors.tagCoral, width: 0.5) : null,
        ),
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onPressed: onTap,
      ),
    );
  }
}

