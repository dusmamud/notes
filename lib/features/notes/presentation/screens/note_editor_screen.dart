import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/services/math_notes_engine.dart';
import '../../data/models/note_entity.dart';
import '../../domain/repositories/note_repository.dart';
import '../widgets/attachment_sheet.dart';
import '../widgets/audio_recording_modal.dart';
import '../widgets/editor_format_panel.dart';
import '../widgets/find_and_replace_bar.dart';
import '../widgets/lists_structure_panel.dart';
import '../widgets/note_link_dialog.dart';
import '../widgets/note_summary_modal.dart';
import '../widgets/page_appearance_sheet.dart';
import '../widgets/table_actions_bar.dart';

enum ActiveToolboxPanel { none, format, lists, table }

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
  final FocusNode _editorFocusNode = FocusNode();
  final MathNotesEngine _mathEngine = MathNotesEngine();

  ActiveToolboxPanel _activePanel = ActiveToolboxPanel.none;
  bool _showFindAndReplace = false;
  String _saveStatus = "Saved";
  final List<String> _undoHistory = [];
  final List<String> _redoHistory = [];

  TextAlign _textAlign = TextAlign.left;
  TextDirection _textDirection = TextDirection.ltr;

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
    _editorFocusNode.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    final text = _contentController.text;
    _checkTypingTriggers(text);
    _checkMathTriggers(text);
    _autoSave();
  }

  void _checkTypingTriggers(String text) {
    // Check for note link trigger '>>'
    final sel = _contentController.selection;
    if (sel.isValid && sel.isCollapsed && sel.start >= 2) {
      final substring = text.substring(sel.start - 2, sel.start);
      if (substring == '>>') {
        _openNoteLinkPicker();
      }
    }
  }

  void _openNoteLinkPicker() {
    NoteLinkDialog.show(context, widget.repository, (link) {
      final sel = _contentController.selection;
      final text = _contentController.text;
      if (sel.isValid && sel.isCollapsed && sel.start >= 2) {
        // Replace the '>>' with the link
        final newText = text.replaceRange(sel.start - 2, sel.start, "$link ");
        _contentController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: sel.start - 2 + link.length + 1),
        );
      } else {
        _insertFormatting("$link ");
      }
    });
  }

  void _checkMathTriggers(String text) {
    if (widget.note.mathResultsMode == 'off') return;
    final lines = text.split('\n');
    if (lines.isEmpty) return;
    final lastLine = lines.last.trim();
    if (lastLine.endsWith('=')) {
      final result = _mathEngine.evaluateLine(lastLine);
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

  void _recordUndoState() {
    _undoHistory.add(_contentController.text);
    if (_undoHistory.length > 50) _undoHistory.removeAt(0);
    _redoHistory.clear();
  }

  void _insertFormatting(String prefix, [String suffix = '']) {
    _recordUndoState();
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

  void _handleHardwareKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isControl = HardwareKeyboard.instance.isControlPressed;
      final isShift = HardwareKeyboard.instance.isShiftPressed;

      if (isControl && event.logicalKey == LogicalKeyboardKey.keyB) {
        _insertFormatting("**", "**");
      } else if (isControl && event.logicalKey == LogicalKeyboardKey.keyI) {
        _insertFormatting("*", "*");
      } else if (isControl && event.logicalKey == LogicalKeyboardKey.keyU) {
        _insertFormatting("<u>", "</u>");
      } else if (isControl && isShift && event.logicalKey == LogicalKeyboardKey.keyX) {
        _insertFormatting("~~", "~~");
      } else if (isControl && event.logicalKey == LogicalKeyboardKey.keyZ) {
        if (isShift) {
          _redo();
        } else {
          _undo();
        }
      } else if (isControl && event.logicalKey == LogicalKeyboardKey.keyY) {
        _redo();
      } else if (isControl && event.logicalKey == LogicalKeyboardKey.keyF) {
        setState(() => _showFindAndReplace = true);
      } else if (event.logicalKey == LogicalKeyboardKey.tab) {
        if (isShift) {
          _outdent();
        } else {
          _indent();
        }
      }
    }
  }

  void _indent() {
    _insertFormatting("    ");
  }

  void _outdent() {
    final val = _contentController.value;
    final text = val.text;
    final sel = val.selection;
    if (sel.start >= 4 && text.substring(sel.start - 4, sel.start) == "    ") {
      final newText = text.replaceRange(sel.start - 4, sel.start, "");
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: sel.start - 4),
      );
    }
  }

  void _openAttachmentSheet() {
    AttachmentSelectorSheet.show(context, (action) {
      switch (action) {
        case AttachmentAction.scanDocument:
          _insertFormatting("\n📄 [Scanned Document PDF]\n");
          break;
        case AttachmentAction.takePhoto:
          _insertFormatting("\n📷 [Camera Photo]\n");
          break;
        case AttachmentAction.photoLibrary:
          _insertFormatting("\n🖼️ [Photo Gallery Attachment]\n");
          break;
        case AttachmentAction.recordAudio:
          AudioRecordingModal.show(context, (memo) {
            _insertFormatting("\n$memo\n");
          });
          break;
        case AttachmentAction.chooseFile:
          _insertFormatting("\n📁 [Attached Document]\n");
          break;
      }
    });
  }

  void _handleTableAction(TableActionType type) {
    switch (type) {
      case TableActionType.addColumnLeft:
      case TableActionType.addColumnRight:
        _insertFormatting(" | Col New");
        break;
      case TableActionType.addRowAbove:
      case TableActionType.addRowBelow:
        _insertFormatting("\n| Item | Item |");
        break;
      case TableActionType.deleteColumn:
      case TableActionType.deleteRow:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Selected column/row removed")),
        );
        break;
      case TableActionType.reverseDirection:
        setState(() {
          _textDirection = _textDirection == TextDirection.ltr ? TextDirection.rtl : TextDirection.ltr;
        });
        break;
      case TableActionType.convertToText:
        final current = _contentController.text;
        final converted = current.replaceAll('|', ' ').replaceAll('---', '');
        _contentController.text = converted;
        break;
      case TableActionType.copyTable:
        Clipboard.setData(ClipboardData(text: _contentController.text));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Table copied to clipboard")),
        );
        break;
      case TableActionType.shareTable:
        Share.share(_contentController.text, subject: widget.note.title);
        break;
      case TableActionType.deleteTable:
        _insertFormatting("");
        break;
    }
  }

  void _handleListStructure(ListStructureType type) {
    switch (type) {
      case ListStructureType.bulletList:
        _insertFormatting("\n• ");
        break;
      case ListStructureType.dashList:
        _insertFormatting("\n- ");
        break;
      case ListStructureType.numberedList:
        _insertFormatting("\n1. ");
        break;
      case ListStructureType.blockquote:
        _insertFormatting("\n> ");
        break;
      case ListStructureType.codeBlock:
        _insertFormatting("\n```\n", "\n```\n");
        break;
      case ListStructureType.divider:
        _insertFormatting("\n---\n");
        break;
      case ListStructureType.noteLink:
        _openNoteLinkPicker();
        break;
    }
  }

  void _handleParagraphStyle(ParagraphStyle style) {
    switch (style) {
      case ParagraphStyle.title:
        _insertFormatting("# ");
        break;
      case ParagraphStyle.heading:
        _insertFormatting("## ");
        break;
      case ParagraphStyle.subheading:
        _insertFormatting("### ");
        break;
      case ParagraphStyle.body:
        break;
    }
  }

  void _handleInlineFormat(String format) {
    switch (format) {
      case 'bold':
        _insertFormatting("**", "**");
        break;
      case 'italic':
        _insertFormatting("*", "*");
        break;
      case 'underline':
        _insertFormatting("<u>", "</u>");
        break;
      case 'strikethrough':
        _insertFormatting("~~", "~~");
        break;
      case 'code':
        _insertFormatting("`", "`");
        break;
    }
  }

  void _exportNote() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.code_rounded),
              title: const Text("Export as Markdown"),
              onTap: () {
                Navigator.pop(ctx);
                Share.share(_contentController.text, subject: "${widget.note.title}.md");
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_rounded),
              title: const Text("Export as PDF"),
              onTap: () {
                Navigator.pop(ctx);
                Share.share("${widget.note.title}\n\n${_contentController.text}", subject: "${widget.note.title}.pdf");
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_snippet_outlined),
              title: const Text("Export as Plain Text"),
              onTap: () {
                Navigator.pop(ctx);
                Share.share(_contentController.text, subject: "${widget.note.title}.txt");
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wordCount = _contentController.text.trim().isEmpty
        ? 0
        : _contentController.text.trim().split(RegExp(r'\s+')).length;

    final backgroundColor = widget.note.colorValue != null
        ? Color(widget.note.colorValue!)
        : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);

    return KeyboardListener(
      focusNode: _editorFocusNode,
      onKeyEvent: _handleHardwareKey,
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) {
            await _autoSave();
          }
        },
        child: Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: backgroundColor,
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
                  if (val == 'summary') {
                    NoteSummaryModal.show(context, widget.note);
                  } else if (val == 'find') {
                    setState(() => _showFindAndReplace = true);
                  } else if (val == 'appearance') {
                    PageAppearanceSheet.show(context, widget.note, () {
                      setState(() {});
                      _autoSave();
                    });
                  } else if (val == 'export') {
                    _exportNote();
                  } else if (val == 'pin') {
                    widget.note.isPinned = !widget.note.isPinned;
                    await _autoSave();
                    setState(() {});
                  } else if (val == 'lock') {
                    widget.note.isLocked = !widget.note.isLocked;
                    await _autoSave();
                    setState(() {});
                  } else if (val == 'delete') {
                    await widget.repository.deleteNote(widget.note.id);
                    if (context.mounted) Navigator.of(context).pop();
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'summary',
                    child: Row(
                      children: [
                        Icon(Icons.analytics_outlined, size: 20),
                        SizedBox(width: 8),
                        Text("Summarize Note"),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'find',
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, size: 20),
                        SizedBox(width: 8),
                        Text("Find in Note"),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'appearance',
                    child: Row(
                      children: [
                        Icon(Icons.palette_outlined, size: 20),
                        SizedBox(width: 8),
                        Text("Page Appearance"),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.ios_share_rounded, size: 20),
                        SizedBox(width: 8),
                        Text("Export Note"),
                      ],
                    ),
                  ),
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
                  PopupMenuItem(
                    value: 'lock',
                    child: Row(
                      children: [
                        Icon(widget.note.isLocked ? Icons.lock_open_rounded : Icons.lock_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(widget.note.isLocked ? "Unlock Note" : "Lock Note"),
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
              if (_showFindAndReplace)
                FindAndReplaceBar(
                  contentController: _contentController,
                  onClose: () => setState(() => _showFindAndReplace = false),
                ),
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
                          fontSize: 26 * widget.note.textScale,
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
                        textAlign: _textAlign,
                        textDirection: _textDirection,
                        style: AppTypography.bodyLarge.copyWith(
                          fontSize: 16 * widget.note.textScale,
                          height: 1.5,
                        ),
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

              // Dynamic Contextual Toolbox Panels
              if (_activePanel == ActiveToolboxPanel.format)
                EditorFormatPanel(
                  onParagraphStyle: _handleParagraphStyle,
                  onInlineFormat: _handleInlineFormat,
                  onTextColor: (c) => _insertFormatting("<span style='color:${c.toARGB32()}'>", "</span>"),
                  onHighlightColor: (c) {
                    if (c == null) {
                      _insertFormatting("");
                    } else {
                      _insertFormatting("<mark style='background:${c.toARGB32()}'>", "</mark>");
                    }
                  },
                  onTextAlign: (align) {
                    setState(() {
                      _textAlign = switch (align) {
                        TextAlignType.left => TextAlign.left,
                        TextAlignType.center => TextAlign.center,
                        TextAlignType.right => TextAlign.right,
                      };
                    });
                  },
                  onTextDirection: (dir) {
                    setState(() {
                      _textDirection = switch (dir) {
                        TextDirectionType.auto => TextDirection.ltr,
                        TextDirectionType.ltr => TextDirection.ltr,
                        TextDirectionType.rtl => TextDirection.rtl,
                      };
                    });
                  },
                  onIndent: _indent,
                  onOutdent: _outdent,
                  onStylusScribe: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Stylus Scribe active: write anywhere with S-Pen")),
                    );
                  },
                  onClose: () => setState(() => _activePanel = ActiveToolboxPanel.none),
                ),

              if (_activePanel == ActiveToolboxPanel.lists)
                ListsStructurePanel(
                  onSelect: _handleListStructure,
                  onClose: () => setState(() => _activePanel = ActiveToolboxPanel.none),
                ),

              if (_activePanel == ActiveToolboxPanel.table)
                TableActionsBar(
                  onAction: _handleTableAction,
                  onClose: () => setState(() => _activePanel = ActiveToolboxPanel.none),
                ),

              _buildKeyboardAccessoryToolbar(isDark),
            ],
          ),
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
            color: _activePanel == ActiveToolboxPanel.format ? AppColors.accentGold : null,
            onPressed: () {
              setState(() {
                _activePanel = _activePanel == ActiveToolboxPanel.format
                    ? ActiveToolboxPanel.none
                    : ActiveToolboxPanel.format;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.format_list_bulleted_rounded),
            tooltip: "Lists & Structure",
            color: _activePanel == ActiveToolboxPanel.lists ? AppColors.accentGold : null,
            onPressed: () {
              setState(() {
                _activePanel = _activePanel == ActiveToolboxPanel.lists
                    ? ActiveToolboxPanel.none
                    : ActiveToolboxPanel.lists;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.checklist_rounded),
            tooltip: "Checklist",
            onPressed: () => _insertFormatting("- [ ] "),
          ),
          IconButton(
            icon: const Icon(Icons.table_chart_outlined),
            tooltip: "Table",
            color: _activePanel == ActiveToolboxPanel.table ? AppColors.accentGold : null,
            onPressed: () {
              setState(() {
                if (_activePanel == ActiveToolboxPanel.table) {
                  _activePanel = ActiveToolboxPanel.none;
                } else {
                  _insertFormatting("\n| Col 1 | Col 2 |\n|---|---|\n| Item 1 | Item 2 |\n");
                  _activePanel = ActiveToolboxPanel.table;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.attach_file_rounded),
            tooltip: "Attachment",
            onPressed: _openAttachmentSheet,
          ),
        ],
      ),
    );
  }
}
