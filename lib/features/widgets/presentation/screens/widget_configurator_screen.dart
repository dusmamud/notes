import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../notes/data/models/note_entity.dart';
import '../../../notes/domain/repositories/note_repository.dart';

enum WidgetThemeMode { light, dark, system }
enum WidgetTransparency { solid, glass }
enum WidgetTextSize { small, medium, large }

class WidgetConfiguratorScreen extends StatefulWidget {
  final int? appWidgetId;
  final NoteRepository repository;

  const WidgetConfiguratorScreen({
    super.key,
    this.appWidgetId,
    required this.repository,
  });

  @override
  State<WidgetConfiguratorScreen> createState() => _WidgetConfiguratorScreenState();
}

class _WidgetConfiguratorScreenState extends State<WidgetConfiguratorScreen> {
  NoteEntity? _selectedNote;
  List<NoteEntity> _allNotes = [];
  bool _isLoading = true;

  WidgetThemeMode _themeMode = WidgetThemeMode.system;
  WidgetTransparency _transparency = WidgetTransparency.glass;
  WidgetTextSize _textSize = WidgetTextSize.medium;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final notes = await widget.repository.getAllNotes();
    setState(() {
      _allNotes = notes;
      if (notes.isNotEmpty) {
        _selectedNote = notes.first;
      }
      _isLoading = false;
    });
  }

  Future<void> _saveAndDone() async {
    final prefs = await SharedPreferences.getInstance();
    final widgetId = widget.appWidgetId ?? 0;
    if (_selectedNote != null) {
      await prefs.setInt('widget_${widgetId}_note_id', _selectedNote!.id);
      await prefs.setString('widget_${widgetId}_theme', _themeMode.name);
      await prefs.setString('widget_${widgetId}_transparency', _transparency.name);
      await prefs.setString('widget_${widgetId}_text_size', _textSize.name);
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _pickNote() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.7,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text("Select Note for Widget", style: AppTypography.headingMedium),
              ),
              const Divider(height: 1),
              Expanded(
                child: _allNotes.isEmpty
                    ? const Center(child: Text("No notes available", style: AppTypography.captionMedium))
                    : ListView.separated(
                        itemCount: _allNotes.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, index) {
                          final note = _allNotes[index];
                          final isCurrent = _selectedNote?.id == note.id;
                          return ListTile(
                            title: Text(
                              note.title.isEmpty ? "Untitled Note" : note.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal),
                            ),
                            subtitle: Text(
                              note.contentMarkdown,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.captionSmall,
                            ),
                            trailing: isCurrent ? const Icon(Icons.check, color: AppColors.accentGold) : null,
                            onTap: () {
                              setState(() => _selectedNote = note);
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        title: const Text("Widget Options", style: AppTypography.bodyLarge),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveAndDone,
            child: const Text("Done", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentGold)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text("LIVE WIDGET PREVIEW", style: AppTypography.captionSmall),
                  const SizedBox(height: 10),
                  _buildWidgetPreview(isDark),
                  const SizedBox(height: 24),

                  const Text("CONFIGURATION OPTIONS", style: AppTypography.captionSmall),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF7F7F7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      title: const Text("Selected Note"),
                      subtitle: Text(
                        _selectedNote?.title.isNotEmpty == true ? _selectedNote!.title : "Untitled Note",
                        style: const TextStyle(color: AppColors.accentGold),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _pickNote,
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text("APPEARANCE & THEME", style: AppTypography.captionSmall),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF7F7F7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Expanded(child: Text("Theme")),
                              SegmentedButton<WidgetThemeMode>(
                                segments: const [
                                  ButtonSegment(value: WidgetThemeMode.light, label: Text("Light")),
                                  ButtonSegment(value: WidgetThemeMode.dark, label: Text("Dark")),
                                  ButtonSegment(value: WidgetThemeMode.system, label: Text("System")),
                                ],
                                selected: {_themeMode},
                                onSelectionChanged: (val) => setState(() => _themeMode = val.first),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            children: [
                              const Expanded(child: Text("Transparency")),
                              SegmentedButton<WidgetTransparency>(
                                segments: const [
                                  ButtonSegment(value: WidgetTransparency.solid, label: Text("Solid 100%")),
                                  ButtonSegment(value: WidgetTransparency.glass, label: Text("Glass 80%")),
                                ],
                                selected: {_transparency},
                                onSelectionChanged: (val) => setState(() => _transparency = val.first),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text("TEXT SIZE IN WIDGET", style: AppTypography.captionSmall),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF7F7F7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Expanded(child: Text("Size")),
                          SegmentedButton<WidgetTextSize>(
                            segments: const [
                              ButtonSegment(value: WidgetTextSize.small, label: Text("Small")),
                              ButtonSegment(value: WidgetTextSize.medium, label: Text("Medium")),
                              ButtonSegment(value: WidgetTextSize.large, label: Text("Large")),
                            ],
                            selected: {_textSize},
                            onSelectionChanged: (val) => setState(() => _textSize = val.first),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildWidgetPreview(bool isDark) {
    final previewDark = _themeMode == WidgetThemeMode.dark ||
        (_themeMode == WidgetThemeMode.system && isDark);
    final isGlass = _transparency == WidgetTransparency.glass;

    final fontSizeScale = switch (_textSize) {
      WidgetTextSize.small => 0.85,
      WidgetTextSize.medium => 1.0,
      WidgetTextSize.large => 1.2,
    };

    final title = _selectedNote?.title.isNotEmpty == true ? _selectedNote!.title : "Project Roadmap & Goals";
    final snippet = _selectedNote?.contentMarkdown.isNotEmpty == true
        ? _selectedNote!.contentMarkdown
        : "1. Finalize REA binary reverse engineering...\n2. Build Flutter Clean-Room scaffold...";

    return Center(
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: previewDark
              ? (isGlass ? Colors.black.withValues(alpha: 0.8) : const Color(0xFF1C1C1E))
              : (isGlass ? Colors.white.withValues(alpha: 0.8) : Colors.white),
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isGlass ? 0.08 : 0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: previewDark ? Colors.white12 : Colors.black12,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: previewDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 16 * fontSizeScale,
                    ),
                  ),
                ),
                Icon(
                  Icons.edit_note_rounded,
                  size: 20,
                  color: previewDark ? Colors.white60 : Colors.black45,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              snippet,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: previewDark ? Colors.white70 : Colors.black54,
                fontSize: 13 * fontSizeScale,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: previewDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                "Today at 10:45 AM",
                style: TextStyle(
                  color: previewDark ? Colors.white60 : Colors.black45,
                  fontSize: 10 * fontSizeScale,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

