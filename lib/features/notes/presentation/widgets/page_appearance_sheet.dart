import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:smooth_sheets/smooth_sheets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/app_theme_controller.dart';
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
    return showModalSheet(
      context: context,
      barrierDismissible: true,
      builder: (_) => PageAppearanceSheet(note: note, onAppearanceChanged: onChanged),
    );
  }

  @override
  State<PageAppearanceSheet> createState() => _PageAppearanceSheetState();
}

class _PageAppearanceSheetState extends State<PageAppearanceSheet> {
  String _selectedCover = 'none'; // 'none', 'photo', 'gif', 'link'
  String _blurLevel = 'off'; // 'off', 'subtle', 'heavy'
  String _selectedFont = 'pretenda'; // 'pretenda', 'system', 'custom'
  double _fontSize = 16.0;
  bool _fullWidth = false;
  bool _smallAttachments = false;

  @override
  void initState() {
    super.initState();
    final double mult = widget.note.textScale > 0
        ? (widget.note.textScale > 2.0 ? widget.note.textScale / 16.0 : widget.note.textScale)
        : (AppThemeController.instance.defaultFontSize / 16.0);
    _fontSize = (mult * 16.0).clamp(12.0, 28.0);
    widget.note.textScale = _fontSize / 16.0;
  }

  Future<void> _pickCustomFont() async {
    try {
      // file_picker 12+ breaking change (CI run #39): FilePicker.platform
      // and FilePickerResult are gone. pickFile() is the single-file API
      // in 13.x and returns PlatformFile? directly (same pattern already
      // used in note_editor_screen.dart).
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['ttf', 'otf'],
      );
      if (picked != null && picked.path != null) {
        final path = picked.path!;
        final fontBytes = await File(path).readAsBytes();
        final fontLoader = FontLoader('CustomNoteFont_${DateTime.now().millisecondsSinceEpoch}');
        fontLoader.addFont(Future.value(ByteData.view(fontBytes.buffer)));
        await fontLoader.load();
        if (mounted) {
          setState(() {
            _selectedFont = 'custom';
            widget.note.customFontPath = path;
          });
          widget.onAppearanceChanged();
        }
      } else {
        if (mounted) setState(() => _selectedFont = 'pretenda');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not load font file: $e. Reverting to pretenda.")),
        );
        setState(() => _selectedFont = 'pretenda');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeCtrl = AppThemeController.instance;

    final sheetContent = Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusSheet),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
            Text(
              "Note Options",
              style: AppTypography.headingSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                children: [
                  // PAGE COVER
                  _buildSectionLabel("PAGE COVER"),
                  Row(
                    children: [
                      _buildCoverChoice("None", Icons.block, _selectedCover == 'none', () {
                        setState(() => _selectedCover = 'none');
                      }),
                      const SizedBox(width: 8),
                      _buildCoverChoice("Photo", Icons.image_outlined, _selectedCover == 'photo', () {
                        setState(() => _selectedCover = 'photo');
                      }),
                      const SizedBox(width: 8),
                      _buildCoverChoice("GIF", Icons.gif_box_outlined, _selectedCover == 'gif', () {
                        setState(() => _selectedCover = 'gif');
                      }),
                      const SizedBox(width: 8),
                      _buildCoverChoice("Web Link", Icons.link, _selectedCover == 'link', () {
                        setState(() => _selectedCover = 'link');
                      }),
                    ],
                  ),

                  const SizedBox(height: 20),
                  // BACKGROUND COLOR & BLUR
                  _buildSectionLabel("BACKGROUND COLOR & BLUR"),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _ColorOption(
                          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
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
                        _ColorOption(
                          color: Colors.black,
                          isSelected: widget.note.colorValue == Colors.black.toARGB32(),
                          label: "OLED",
                          onTap: () {
                            setState(() => widget.note.colorValue = Colors.black.toARGB32());
                            widget.onAppearanceChanged();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text("Blur: ", style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text("Off"),
                        selected: _blurLevel == 'off',
                        onSelected: (sel) => setState(() => _blurLevel = 'off'),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text("Subtle"),
                        selected: _blurLevel == 'subtle',
                        onSelected: (sel) => setState(() => _blurLevel = 'subtle'),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text("Heavy"),
                        selected: _blurLevel == 'heavy',
                        onSelected: (sel) => setState(() => _blurLevel = 'heavy'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  // TYPOGRAPHY & FONT FAMILY
                  _buildSectionLabel("TYPOGRAPHY & FONT FAMILY"),
                  Card(
                    elevation: 0,
                    color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: RadioGroup<String>(
                      groupValue: _selectedFont,
                      onChanged: (val) {
                        if (val == 'custom') {
                          _pickCustomFont();
                        } else {
                          setState(() => _selectedFont = val!);
                        }
                      },
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            title: const Text("pretenda (Default Variable TTF)"),
                            value: 'pretenda',
                            activeColor: themeCtrl.accentColor,
                          ),
                          const Divider(height: 1),
                          RadioListTile<String>(
                            title: const Text("System Default"),
                            value: 'system',
                            activeColor: themeCtrl.accentColor,
                          ),
                          const Divider(height: 1),
                          RadioListTile<String>(
                            title: const Text("Custom Imported Font (.ttf/.otf)"),
                            value: 'custom',
                            activeColor: themeCtrl.accentColor,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  // TEXT SIZE & SCALING (NoteTextScaler Multiplier)
                  _buildSectionLabel("TEXT SIZE & SCALING (NoteTextScaler)"),
                  Card(
                    elevation: 0,
                    color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Text("A", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                              Expanded(
                                child: Slider(
                                  value: _fontSize,
                                  min: 12,
                                  max: 28,
                                  divisions: 16,
                                  activeColor: themeCtrl.accentColor,
                                  label: "${_fontSize.toInt()} sp",
                                  onChanged: (val) {
                                    setState(() {
                                      _fontSize = val;
                                      widget.note.textScale = val / 16.0;
                                    });
                                    widget.onAppearanceChanged();
                                  },
                                ),
                              ),
                              const Text("A", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey)),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _fontSize = themeCtrl.defaultFontSize.clamp(12.0, 28.0);
                                widget.note.textScale = themeCtrl.defaultFontSize / 16.0;
                              });
                              widget.onAppearanceChanged();
                            },
                            child: Text(
                              "Reset to App Default (${themeCtrl.defaultFontSize.toInt()} sp)",
                              style: TextStyle(color: themeCtrl.accentColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  // PAGE OPTIONS
                  _buildSectionLabel("PAGE OPTIONS"),
                  Card(
                    elevation: 0,
                    color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text("Full Width Note"),
                          subtitle: const Text("Expand text to full canvas edge"),
                          value: _fullWidth,
                          activeThumbColor: themeCtrl.accentColor,
                          onChanged: (val) => setState(() => _fullWidth = val),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text("Small Attachment View"),
                          subtitle: const Text("Compact rows for photos and PDFs"),
                          value: _smallAttachments,
                          activeThumbColor: themeCtrl.accentColor,
                          onChanged: (val) => setState(() => _smallAttachments = val),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    final hasViewport = context.findAncestorWidgetOfExactType<SheetViewport>() != null;
    final sheet = Sheet(
      physics: const BouncingSheetPhysics(),
      child: sheetContent,
    );
    if (!hasViewport) {
      return SheetViewport(child: sheet);
    }
    return sheet;
  }

  Widget _buildSectionLabel(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text,
        style: AppTypography.captionSmall.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
          color: isDark ? Colors.white54 : Colors.black54,
        ),
      ),
    );
  }

  Widget _buildCoverChoice(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    final themeCtrl = AppThemeController.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? themeCtrl.accentColor.withValues(alpha: 0.15)
                : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? themeCtrl.accentColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: isSelected ? themeCtrl.accentColor : Colors.grey),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? themeCtrl.accentColor : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ],
          ),
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
            color: isSelected ? AppThemeController.instance.accentColor : Colors.black12,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppThemeController.instance.accentColor.withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Center(
          child: label != null
              ? Text(
                  label!,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
                  ),
                )
              : (isSelected ? const Icon(Icons.check, size: 20, color: Colors.black87) : null),
        ),
      ),
    );
  }
}
