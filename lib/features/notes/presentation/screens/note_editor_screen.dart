import 'dart:io';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pull_down_button/pull_down_button.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/services/markdown_table_helper.dart';
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
  String? _suggestedMathResult;
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
    _titleController.addListener(_onTitleChanged);
  }

  @override
  void dispose() {
    EasyDebounce.cancel('note_editor_save');
    EasyDebounce.cancel('note_editor_undo');
    _contentController.removeListener(_onContentChanged);
    _titleController.removeListener(_onTitleChanged);
    _titleController.dispose();
    _contentController.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  void _onTitleChanged() {
    EasyDebounce.debounce('note_editor_save', const Duration(milliseconds: 400), () {
      _autoSave();
    });
  }

  void _onContentChanged() {
    final text = _contentController.text;
    _checkTypingTriggers(text);
    _checkMathTriggers(text);
    // Track typing in undo stack with debounce coalescing
    EasyDebounce.debounce('note_editor_undo', const Duration(milliseconds: 800), () {
      _recordUndoState();
    });
    // Auto-save with 400ms debounce
    EasyDebounce.debounce('note_editor_save', const Duration(milliseconds: 400), () {
      _autoSave();
    });
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
        if (widget.note.mathResultsMode == 'insert') {
          final newText = "$text $result";
          _contentController.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: newText.length),
          );
        } else {
          // Suggest mode: show ghost badge
          setState(() => _suggestedMathResult = result);
        }
      }
    } else {
      if (_suggestedMathResult != null) {
        setState(() => _suggestedMathResult = null);
      }
    }
  }

  void _acceptMathResult() {
    if (_suggestedMathResult == null) return;
    final text = _contentController.text;
    final newText = "$text $_suggestedMathResult";
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
    setState(() => _suggestedMathResult = null);
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
    AttachmentSelectorSheet.show(context, (action) async {
      switch (action) {
        case AttachmentAction.scanDocument:
          try {
            final pictures = await CunningDocumentScanner.getPictures(
              noOfPages: 50,
              asPdf: true,
            );
            if (pictures != null && pictures.isNotEmpty) {
              final dir = await getApplicationDocumentsDirectory();
              final dest = File('${dir.path}/scanned_${DateTime.now().millisecondsSinceEpoch}.pdf');
              await File(pictures.first).copy(dest.path);
              _insertFormatting("\n[📄 Scanned Document (${dest.path.split(Platform.pathSeparator).last})](${dest.path})\n");
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Document Scanner: $e")),
              );
            }
          }
          break;
        case AttachmentAction.takePhoto:
          try {
            final picker = ImagePicker();
            final photo = await picker.pickImage(source: ImageSource.camera);
            if (photo != null) {
              final dir = await getApplicationDocumentsDirectory();
              final dest = File('${dir.path}/photo_${DateTime.now().millisecondsSinceEpoch}.jpg');
              await File(photo.path).copy(dest.path);
              _insertFormatting("\n![Camera Photo](${dest.path})\n");
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Camera: $e")),
              );
            }
          }
          break;
        case AttachmentAction.photoLibrary:
          try {
            final picker = ImagePicker();
            final image = await picker.pickImage(source: ImageSource.gallery);
            if (image != null) {
              final dir = await getApplicationDocumentsDirectory();
              final dest = File('${dir.path}/gallery_${DateTime.now().millisecondsSinceEpoch}.jpg');
              await File(image.path).copy(dest.path);
              _insertFormatting("\n![Photo Gallery](${dest.path})\n");
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Gallery: $e")),
              );
            }
          }
          break;
        case AttachmentAction.recordAudio:
          AudioRecordingModal.show(context, (memo) {
            _insertFormatting(memo);
          });
          break;
        case AttachmentAction.chooseFile:
          try {
            // file_picker 12+ breaking change: pickFiles() now returns
            // List<PlatformFile> (no FilePickerResult wrapper), and this
            // call site only ever used a single file. pickFile() is the
            // single-file API in 13.x. Upgrade reason (CI run #25):
            // file_picker 10.2.4 compiles against android-34, but its
            // dependencies require compileSdk 35/36 (AAR metadata check).
            final picked = await FilePicker.pickFile();
            if (picked != null && picked.path != null) {
              final src = File(picked.path!);
              final dir = await getApplicationDocumentsDirectory();
              final name = picked.name;
              final dest = File('${dir.path}/file_${DateTime.now().millisecondsSinceEpoch}_$name');
              await src.copy(dest.path);
              _insertFormatting("\n[📁 $name](${dest.path})\n");
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("File Picker: $e")),
              );
            }
          }
          break;
      }
    });
  }

  void _handleTableAction(TableActionType type) {
    _recordUndoState();
    final text = _contentController.text;
    final cursor = _contentController.selection.baseOffset;
    switch (type) {
      case TableActionType.addColumnLeft:
      case TableActionType.addColumnRight:
        final newText = MarkdownTableHelper.addColumn(text, cursor);
        _contentController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: cursor.clamp(0, newText.length)),
        );
        break;
      case TableActionType.addRowAbove:
        final newText = MarkdownTableHelper.addRow(text, cursor, below: false);
        _contentController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: cursor.clamp(0, newText.length)),
        );
        break;
      case TableActionType.addRowBelow:
        final newText = MarkdownTableHelper.addRow(text, cursor, below: true);
        _contentController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: cursor.clamp(0, newText.length)),
        );
        break;
      case TableActionType.deleteColumn:
        final newText = MarkdownTableHelper.deleteCurrentColumn(text, cursor);
        _contentController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: cursor.clamp(0, newText.length)),
        );
        break;
      case TableActionType.deleteRow:
        final newText = MarkdownTableHelper.deleteCurrentRow(text, cursor);
        _contentController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: cursor.clamp(0, newText.length)),
        );
        break;
      case TableActionType.reverseDirection:
        setState(() {
          _textDirection = _textDirection == TextDirection.ltr ? TextDirection.rtl : TextDirection.ltr;
        });
        break;
      case TableActionType.convertToText:
        final newText = MarkdownTableHelper.convertTableToText(text, cursor);
        _contentController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: cursor.clamp(0, newText.length)),
        );
        break;
      case TableActionType.copyTable:
        final tableText = MarkdownTableHelper.copyTableOnly(text, cursor);
        if (tableText != null) {
          Clipboard.setData(ClipboardData(text: tableText));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Table copied to clipboard")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Cursor is not inside a table")),
          );
        }
        break;
      case TableActionType.shareTable:
        final tableText = MarkdownTableHelper.copyTableOnly(text, cursor);
        if (tableText != null) {
          SharePlus.instance.share(ShareParams(
            text: tableText,
            subject: "${widget.note.title} Table",
          ));
        } else {
          SharePlus.instance.share(ShareParams(
            text: _contentController.text,
            subject: widget.note.title,
          ));
        }
        break;
      case TableActionType.deleteTable:
        final newText = MarkdownTableHelper.deleteEntireTable(text, cursor);
        _contentController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: cursor.clamp(0, newText.length)),
        );
        break;
    }
    _autoSave();
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

  String _colorToHex(Color c) {
    final rgb = (c.toARGB32() & 0x00FFFFFF).toRadixString(16).padLeft(6, '0');
    return "#$rgb";
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

  Future<void> _exportAsPdf() async {
    try {
      final pdf = pw.Document();
      final titleText = widget.note.title.isNotEmpty ? widget.note.title : 'Untitled Note';
      final content = _contentController.text;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context ctx) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                titleText,
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Text(
              "Updated: ${widget.note.updatedAt.toString().split('.')[0]}",
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.Divider(thickness: 0.5),
            pw.SizedBox(height: 12),
            pw.Paragraph(
              text: content,
              style: const pw.TextStyle(fontSize: 12, lineSpacing: 1.4),
            ),
          ],
        ),
      );

      final bytes = await pdf.save();
      final dir = await getTemporaryDirectory();
      final safeTitle = titleText.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final file = File('${dir.path}/$safeTitle.pdf');
      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        subject: "$safeTitle.pdf",
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("PDF Export Error: $e")),
        );
      }
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
                SharePlus.instance.share(ShareParams(
                  text: _contentController.text,
                  subject: "${widget.note.title}.md",
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_rounded),
              title: const Text("Export as PDF (Real Compiled Document)"),
              onTap: () {
                Navigator.pop(ctx);
                _exportAsPdf();
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_snippet_outlined),
              title: const Text("Export as Plain Text"),
              onTap: () {
                Navigator.pop(ctx);
                SharePlus.instance.share(ShareParams(
                  text: _contentController.text,
                  subject: "${widget.note.title}.txt",
                ));
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

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyB, control: true): () => _handleInlineFormat('bold'),
        const SingleActivator(LogicalKeyboardKey.keyI, control: true): () => _handleInlineFormat('italic'),
        const SingleActivator(LogicalKeyboardKey.keyU, control: true): () => _handleInlineFormat('underline'),
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): _undo,
        const SingleActivator(LogicalKeyboardKey.keyY, control: true): _redo,
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true): _redo,
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
          setState(() => _showFindAndReplace = true);
        },
      },
      child: KeyboardListener(
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
              PullDownButton(
                itemBuilder: (context) => [
                  PullDownMenuItem(
                    title: 'Summarize Note',
                    icon: CupertinoIcons.chart_bar,
                    onTap: () => NoteSummaryModal.show(context, widget.note),
                  ),
                  PullDownMenuItem(
                    title: 'Find in Note',
                    icon: CupertinoIcons.search,
                    onTap: () => setState(() => _showFindAndReplace = true),
                  ),
                  PullDownMenuItem(
                    title: 'Page Appearance',
                    icon: CupertinoIcons.paintbrush,
                    onTap: () => PageAppearanceSheet.show(context, widget.note, () {
                      setState(() {});
                      _autoSave();
                    }),
                  ),
                  PullDownMenuItem(
                    title: 'Export Note',
                    icon: CupertinoIcons.share,
                    onTap: _exportNote,
                  ),
                  PullDownMenuItem(
                    title: widget.note.isPinned ? 'Unpin Note' : 'Pin Note',
                    icon: widget.note.isPinned ? CupertinoIcons.pin_slash : CupertinoIcons.pin,
                    onTap: () async {
                      widget.note.isPinned = !widget.note.isPinned;
                      await _autoSave();
                      setState(() {});
                    },
                  ),
                  PullDownMenuItem(
                    title: widget.note.isLocked ? 'Unlock Note' : 'Lock Note',
                    icon: widget.note.isLocked ? CupertinoIcons.lock_open : CupertinoIcons.lock,
                    onTap: () async {
                      widget.note.isLocked = !widget.note.isLocked;
                      await _autoSave();
                      setState(() {});
                    },
                  ),
                  PullDownMenuItem(
                    title: 'Move to Trash',
                    isDestructive: true,
                    icon: CupertinoIcons.delete,
                    onTap: () async {
                      await widget.repository.deleteNote(widget.note.id);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
                ],
                buttonBuilder: (context, showMenu) => IconButton(
                  icon: const Icon(Icons.more_horiz_rounded),
                  onPressed: showMenu,
                ),
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
                  onTextColor: (c) => _insertFormatting("<span style='color:${_colorToHex(c)}'>", "</span>"),
                  onHighlightColor: (c) {
                    if (c == null) {
                      _insertFormatting("");
                    } else {
                      _insertFormatting("<mark style='background-color:${_colorToHex(c)}'>", "</mark>");
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

              if (_suggestedMathResult != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                    border: Border(
                      top: BorderSide(color: isDark ? Colors.white12 : Colors.black12, width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calculate_outlined, size: 16, color: AppColors.accentGold),
                      const SizedBox(width: 8),
                      Text(
                        "= $_suggestedMathResult",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentGold),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.check, size: 14),
                        label: const Text("Insert Answer", style: TextStyle(fontSize: 12)),
                        onPressed: _acceptMathResult,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 14),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => setState(() => _suggestedMathResult = null),
                      ),
                    ],
                  ),
                ),

              _buildKeyboardAccessoryToolbar(isDark),
            ],
          ),
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
