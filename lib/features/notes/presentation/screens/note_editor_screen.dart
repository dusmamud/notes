import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/services/math_notes_engine.dart';
import '../../data/models/note_entity.dart';
import '../../domain/repositories/note_repository.dart';

class NoteEditorScreen extends StatefulWidget {
  final NoteEntity note;
  final NoteRepository repository;

  const NoteEditorScreen({
    super.key,
    required this.note,
    required this.repository,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final MathNotesEngine _mathEngine = MathNotesEngine();
  bool _showFormatToolbar = false;
  String _saveStatus = "Saved";
  final List<String> _undoHistory = [];
  final List<String> _redoHistory = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.contentMarkdown);
    _contentController.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _contentController.removeListener(_onContentChanged);
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    final text = _contentController.text;
    _checkMathTriggers(text);
    _autoSave();
  }

  void _checkMathTriggers(String text) {
    if (widget.note.mathResultsMode == 'off') return;
    final lines = text.split('\n');
    if (lines.isEmpty) return;
    final lastLine = lines.last.trim();
    if (lastLine.endsWith('=')) {
      final expr = lastLine.substring(0, lastLine.length - 1).trim();
      final result = _mathEngine.evaluateExpression(expr);
      if (result != null) {
        final newText = "$text $result";
        _contentController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );
      }
    }
  }

  Future<void> _autoSave() async {
    setState(() => _saveStatus = "Saving...");
    widget.note.title = _titleController.text.trim();
    widget.note.contentMarkdown = _contentController.text;
    widget.note.updatedAt = DateTime.now();
    await widget.repository.saveNote(widget.note);
    if (mounted) {
      setState(() => _saveStatus = "Saved");
    }
  }

  void _insertFormatting(String prefix, [String suffix = '']) {
    final val = _contentController.value;
    final sel = val.selection;
    final text = val.text;
    final start = sel.start < 0 ? text.length : sel.start;
    final end = sel.end < 0 ? text.length : sel.end;
    final selectedText = text.substring(start, end);
    final replacement = "$prefix$selectedText$suffix";
    final newText = text.replaceRange(start, end, replacement);
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + replacement.length),
    );
  }

  void _undo() {
    if (_undoHistory.isNotEmpty) {
      _redoHistory.add(_contentController.text);
      final prev = _undoHistory.removeLast();
      _contentController.text = prev;
    }
  }

  void _redo() {
    if (_redoHistory.isNotEmpty) {
      _undoHistory.add(_contentController.text);
      final next = _redoHistory.removeLast();
      _contentController.text = next;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wordCount = _contentController.text.trim().isEmpty
        ? 0
        : _contentController.text.trim().split(RegExp(r'\s+')).length;

    return WillPopScope(
      onWillPop: () async {
        await _autoSave();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () async {
              await _autoSave();
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
          title: Text(_saveStatus, style: AppTypography.captionMedium),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.undo_rounded),
              tooltip: "Undo (Hold for Redo)",
              onPressed: _undo,
            ),
            IconButton(
              icon: const Icon(Icons.redo_rounded),
              tooltip: "Redo",
              onPressed: _redo,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz_rounded),
              onSelected: (val) async {
                if (val == 'pin') {
                  widget.note.isPinned = !widget.note.isPinned;
                  await _autoSave();
                } else if (val == 'delete') {
                  await widget.repository.deleteNote(widget.note.id);
                  if (context.mounted) Navigator.of(context).pop();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'pin',
                  child: Row(
                    children: [
                      Icon(widget.note.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(widget.note.isPinned ? "Unpin Note" : "Pin Note"),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.tagCoral),
                      SizedBox(width: 8),
                      Text("Move to Trash", style: TextStyle(color: AppColors.tagCoral)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _titleController,
                      style: AppTypography.headingLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                      ),
                      decoration: const InputDecoration(
                        hintText: "Title",
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        "$wordCount words | ${_contentController.text.length} characters",
                        style: AppTypography.captionSmall,
                      ),
                    ),
                    const Divider(height: 16),
                    TextField(
                      controller: _contentController,
                      style: AppTypography.bodyLarge.copyWith(height: 1.5),
                      decoration: const InputDecoration(
                        hintText: "Start typing, calculate with 12*4= or link with >>...",
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                    ),
                  ],
                ),
              ),
            ),
            if (_showFormatToolbar) _buildFormatPanel(isDark),
            _buildKeyboardAccessoryToolbar(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyboardAccessoryToolbar(bool isDark) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : Colors.black12,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Text("Aa", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            tooltip: "Format",
            color: _showFormatToolbar ? AppColors.accentGold : null,
            onPressed: () => setState(() => _showFormatToolbar = !_showFormatToolbar),
          ),
          IconButton(
            icon: const Icon(Icons.format_list_bulleted_rounded),
            tooltip: "Bullet List",
            onPressed: () => _insertFormatting("- "),
          ),
          IconButton(
            icon: const Icon(Icons.checklist_rounded),
            tooltip: "Checklist",
            onPressed: () => _insertFormatting("- [ ] "),
          ),
          IconButton(
            icon: const Icon(Icons.table_chart_outlined),
            tooltip: "Table",
            onPressed: () => _insertFormatting("\n| Col 1 | Col 2 |\n|---|---|\n| Item 1 | Item 2 |\n"),
          ),
          IconButton(
            icon: const Icon(Icons.attach_file_rounded),
            tooltip: "Attachment",
            onPressed: () {
              // Attachment sheet
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFormatPanel(bool isDark) {
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton(
                onPressed: () => _insertFormatting("# "),
                child: const Text("Title", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () => _insertFormatting("## "),
                child: const Text("Heading", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () => _insertFormatting("### "),
                child: const Text("Subheading", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () => _insertFormatting(""),
                child: const Text("Body"),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.format_bold_rounded),
                onPressed: () => _insertFormatting("**", "**"),
              ),
              IconButton(
                icon: const Icon(Icons.format_italic_rounded),
                onPressed: () => _insertFormatting("*", "*"),
              ),
              IconButton(
                icon: const Icon(Icons.format_underlined_rounded),
                onPressed: () => _insertFormatting("<u>", "</u>"),
              ),
              IconButton(
                icon: const Icon(Icons.strikethrough_s_rounded),
                onPressed: () => _insertFormatting("~~", "~~"),
              ),
              IconButton(
                icon: const Icon(Icons.code_rounded),
                onPressed: () => _insertFormatting("`", "`"),
              ),
              IconButton(
                icon: const Icon(Icons.format_quote_rounded),
                onPressed: () => _insertFormatting("> "),
              ),
              IconButton(
                icon: const Icon(Icons.horizontal_rule_rounded),
                onPressed: () => _insertFormatting("\n---\n"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

