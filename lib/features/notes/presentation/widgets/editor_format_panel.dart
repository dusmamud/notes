import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';

enum ParagraphStyle { title, heading, subheading, body }
enum TextAlignType { left, center, right }
enum TextDirectionType { auto, ltr, rtl }

class EditorFormatPanel extends StatefulWidget {
  final ValueChanged<ParagraphStyle> onParagraphStyle;
  final ValueChanged<String> onInlineFormat; // 'bold', 'italic', 'underline', 'strikethrough', 'code'
  final ValueChanged<Color> onTextColor;
  final ValueChanged<Color?> onHighlightColor;
  final ValueChanged<TextAlignType> onTextAlign;
  final ValueChanged<TextDirectionType> onTextDirection;
  final VoidCallback onIndent;
  final VoidCallback onOutdent;
  final VoidCallback onStylusScribe;
  final VoidCallback onClose;

  const EditorFormatPanel({
    super.key,
    required this.onParagraphStyle,
    required this.onInlineFormat,
    required this.onTextColor,
    required this.onHighlightColor,
    required this.onTextAlign,
    required this.onTextDirection,
    required this.onIndent,
    required this.onOutdent,
    required this.onStylusScribe,
    required this.onClose,
  });

  @override
  State<EditorFormatPanel> createState() => _EditorFormatPanelState();
}

class _EditorFormatPanelState extends State<EditorFormatPanel> {
  ParagraphStyle _currentStyle = ParagraphStyle.body;
  TextAlignType _currentAlign = TextAlignType.left;
  TextDirectionType _currentDirection = TextDirectionType.auto;

  static const List<Color> _textColors = [
    Colors.black,
    Colors.blue,
    Colors.green,
    Colors.red,
    Colors.purple,
    Colors.orange,
  ];

  static const List<Color> _highlightColors = [
    Color(0xFFFFF59D), // Yellow
    Color(0xFFA5D6A7), // Mint
    Color(0xFFFFCCBC), // Rose
    Color(0xFF90CAF9), // Sky
    Color(0xFFCE93D8), // Lavender
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.text_fields_rounded, size: 18, color: AppColors.accentGold),
              const SizedBox(width: 8),
              const Text("FORMAT TOOLBOX", style: AppTypography.captionSmall),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: widget.onClose,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 1. Paragraph Styles Segmented Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStyleChip("Title (H1)", ParagraphStyle.title),
                _buildStyleChip("Heading (H2)", ParagraphStyle.heading),
                _buildStyleChip("Subheading (H3)", ParagraphStyle.subheading),
                _buildStyleChip("Body (Aa)", ParagraphStyle.body),
              ],
            ),
          ),
          const Divider(height: 16),

          // 2. Inline Character Styles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildIconButton(Icons.format_bold_rounded, "Bold", () => widget.onInlineFormat('bold')),
              _buildIconButton(Icons.format_italic_rounded, "Italic", () => widget.onInlineFormat('italic')),
              _buildIconButton(Icons.format_underlined_rounded, "Underline", () => widget.onInlineFormat('underline')),
              _buildIconButton(Icons.strikethrough_s_rounded, "Strikethrough", () => widget.onInlineFormat('strikethrough')),
              _buildIconButton(Icons.code_rounded, "Code", () => widget.onInlineFormat('code')),
            ],
          ),
          const Divider(height: 16),

          // 3. Color Pickers (Text Color & Highlight Color)
          Row(
            children: [
              const Text("Text: ", style: AppTypography.captionSmall),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _textColors.map((c) {
                      return GestureDetector(
                        onTap: () => widget.onTextColor(c),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text("Highlight: ", style: AppTypography.captionSmall),
              GestureDetector(
                onTap: () => widget.onHighlightColor(null),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey, width: 1.5),
                  ),
                  child: const Icon(Icons.block, size: 12, color: Colors.grey),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _highlightColors.map((c) {
                      return GestureDetector(
                        onTap: () => widget.onHighlightColor(c),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 16),

          // 4. Alignment, Direction & Indentation & Stylus
          Row(
            children: [
              // Align
              IconButton(
                icon: const Icon(Icons.format_align_left_rounded, size: 18),
                tooltip: "Left",
                onPressed: () {
                  setState(() => _currentAlign = TextAlignType.left);
                  widget.onTextAlign(TextAlignType.left);
                },
                color: _currentAlign == TextAlignType.left ? AppColors.accentGold : null,
              ),
              IconButton(
                icon: const Icon(Icons.format_align_center_rounded, size: 18),
                tooltip: "Center",
                onPressed: () {
                  setState(() => _currentAlign = TextAlignType.center);
                  widget.onTextAlign(TextAlignType.center);
                },
                color: _currentAlign == TextAlignType.center ? AppColors.accentGold : null,
              ),
              IconButton(
                icon: const Icon(Icons.format_align_right_rounded, size: 18),
                tooltip: "Right",
                onPressed: () {
                  setState(() => _currentAlign = TextAlignType.right);
                  widget.onTextAlign(TextAlignType.right);
                },
                color: _currentAlign == TextAlignType.right ? AppColors.accentGold : null,
              ),
              IconButton(
                icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                tooltip: "Direction (${_currentDirection.name.toUpperCase()})",
                onPressed: () {
                  setState(() {
                    _currentDirection = switch (_currentDirection) {
                      TextDirectionType.auto => TextDirectionType.ltr,
                      TextDirectionType.ltr => TextDirectionType.rtl,
                      TextDirectionType.rtl => TextDirectionType.auto,
                    };
                  });
                  widget.onTextDirection(_currentDirection);
                },
              ),
              const VerticalDivider(width: 16),

              // Indent / Outdent
              IconButton(
                icon: const Icon(Icons.format_indent_decrease_rounded, size: 18),
                tooltip: "Outdent",
                onPressed: widget.onOutdent,
              ),
              IconButton(
                icon: const Icon(Icons.format_indent_increase_rounded, size: 18),
                tooltip: "Indent",
                onPressed: widget.onIndent,
              ),
              const Spacer(),

              // Stylus Scribe
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.draw_rounded, size: 16),
                label: const Text("Stylus", style: TextStyle(fontSize: 12)),
                onPressed: widget.onStylusScribe,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStyleChip(String label, ParagraphStyle style) {
    final isSelected = _currentStyle == style;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        selectedColor: AppColors.accentGold.withValues(alpha: 0.25),
        onSelected: (_) {
          setState(() => _currentStyle = style);
          widget.onParagraphStyle(style);
        },
      ),
    );
  }

  Widget _buildIconButton(IconData icon, String tooltip, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      onPressed: onTap,
    );
  }
}

