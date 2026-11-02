import 'dart:io';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sliver_tools/sliver_tools.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/app_theme_controller.dart';
import '../../../../core/security/security_service.dart';
import '../../../../core/security/passcode_screen.dart';
import '../../../../core/services/widget_sync_service.dart';
import '../../../folders/presentation/screens/folders_screen.dart';
import '../../../folders/presentation/screens/trash_screen.dart';
import '../../../folders/presentation/widgets/move_to_folder_sheet.dart';
import '../../../onboarding/presentation/whats_new_sheet.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../widgets/presentation/screens/widget_configurator_screen.dart';
import '../../data/models/note_entity.dart';
import '../../domain/repositories/note_repository.dart';
import '../widgets/audio_recording_modal.dart';
import '../widgets/capture_bar.dart';
import '../widgets/note_card.dart';
import 'note_editor_screen.dart';

class NotesFeedScreen extends StatefulWidget {
  final NoteRepository repository;

  const NotesFeedScreen({super.key, required this.repository});

  @override
  State<NotesFeedScreen> createState() => _NotesFeedScreenState();
}

class _NotesFeedScreenState extends State<NotesFeedScreen> {
  List<NoteEntity> _notes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _isSelectionMode = false;
  final Set<int> _selectedIds = {};
  NoteEntity? _selectedTabletNote;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadNotes();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WhatsNewSheet.showIfNeeded(context);
      _checkInitialIntent();
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkInitialIntent() async {
    final data = await WidgetSyncService.getInitialIntent();
    if (data == null || !mounted) return;

    final noteId = data['note_id'];
    if (noteId != null && noteId is num && noteId > 0) {
      final note = await widget.repository.getNoteById(noteId.toInt());
      if (note != null && mounted) {
        _openEditor(note);
        return;
      }
    }

    final mode = data['capture_mode'];
    if (mode == 'checklist') {
      _openEditor(null, '- [ ] ');
    } else if (mode == 'audio') {
      if (!mounted) return;
      AudioRecordingModal.show(context, (memo) {
        _openEditor(null, "\n$memo\n");
      });
    } else if (mode == 'math_notes') {
      _openEditor(null, '# Math Notes\n\n');
    } else if (mode == 'new_note' || mode == 'quick_note' || mode == 'text') {
      _openEditor();
    }
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    final notes = await widget.repository.getAllNotes();
    setState(() {
      _notes = notes;
      if (_selectedTabletNote != null) {
        // Refresh reference
        final match = notes.where((n) => n.id == _selectedTabletNote!.id);
        _selectedTabletNote = match.isNotEmpty ? match.first : (notes.isNotEmpty ? notes.first : null);
      } else if (notes.isNotEmpty) {
        _selectedTabletNote = notes.first;
      }
      _isLoading = false;
    });
  }

  List<NoteEntity> get _filteredNotes {
    if (_searchQuery.trim().isEmpty) return _notes;
    final q = _searchQuery.toLowerCase().trim();
    return _notes.where((n) {
      final titleMatch = n.title.toLowerCase().contains(q);
      final bodyMatch = n.contentMarkdown.toLowerCase().contains(q);
      final tags = RegExp(r'#\w+')
          .allMatches(n.contentMarkdown)
          .map((m) => m.group(0)!.toLowerCase());
      final tagMatch = tags.any((tag) => tag.contains(q));
      final isAudioQuery = q.contains('audio') || q.contains('voice') || q.contains('mic');
      final hasAudio = n.contentMarkdown.contains('🎙️ Voice Memo');
      final isPdfQuery = q.contains('pdf') || q.contains('scan');
      final hasPdf = n.contentMarkdown.contains('📄') || n.contentMarkdown.contains('.pdf');
      final attachmentMatch = (isAudioQuery && hasAudio) || (isPdfQuery && hasPdf);
      return titleMatch || bodyMatch || tagMatch || attachmentMatch;
    }).toList();
  }

  List<NoteEntity> get _pinnedNotes =>
      _filteredNotes.where((n) => n.isPinned).toList();

  List<NoteEntity> get _unpinnedNotes =>
      _filteredNotes.where((n) => !n.isPinned).toList();

  void _openEditor([NoteEntity? note, String initialContent = '', bool isTablet = false]) async {
    final noteToEdit = note ??
        NoteEntity(
          title: '',
          contentMarkdown: initialContent,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

    // Enforce per-note security challenge
    if (note != null && note.isLocked) {
      final sec = SecurityService();
      final hasPasscode = await sec.hasPasscode();
      if (!mounted) return;
      if (hasPasscode) {
        final authorized = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => PasscodeScreen(
              mode: PasscodeMode.unlockNote,
              customTitle: "Enter Passcode to View Locked Note",
              onSuccess: () => Navigator.of(context).pop(true),
              onCancel: () => Navigator.of(context).pop(false),
            ),
          ),
        );
        if (authorized != true) return;
      } else {
        final bioOk = await sec.authenticateWithBiometrics(reason: "Unlock Note");
        if (!bioOk) return;
      }
    }

    if (isTablet) {
      if (noteToEdit.id == 0) {
        await widget.repository.saveNote(noteToEdit);
      }
      setState(() => _selectedTabletNote = noteToEdit);
      _loadNotes();
      return;
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(
          note: noteToEdit,
          repository: widget.repository,
        ),
      ),
    );
    _loadNotes();
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _deleteNote(NoteEntity note) async {
    await widget.repository.deleteNote(note.id);
    _loadNotes();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: const Text("Note moved to Trash"),
        action: SnackBarAction(
          label: "Undo",
          textColor: AppColors.accentGold,
          onPressed: () async {
            await widget.repository.restoreNote(note.id);
            _loadNotes();
          },
        ),
      ),
    );
  }

  void _batchDelete() async {
    final deleted = List<int>.from(_selectedIds);
    for (var id in deleted) {
      await widget.repository.deleteNote(id);
    }
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });
    _loadNotes();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text("${deleted.length} notes moved to Trash"),
        action: SnackBarAction(
          label: "Undo",
          textColor: AppColors.accentGold,
          onPressed: () async {
            for (var id in deleted) {
              await widget.repository.restoreNote(id);
            }
            _loadNotes();
          },
        ),
      ),
    );
  }

  void _toggleBatchPin() {
    final anyPinned = _pinnedNotes.any((n) => _selectedIds.contains(n.id));
    _batchPin(!anyPinned);
  }

  void _batchPin(bool pin) async {
    for (var id in _selectedIds) {
      await widget.repository.pinNote(id, pin);
    }
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });
    _loadNotes();
  }

  void _batchMoveToFolder() {
    MoveToFolderSheet.show(context, widget.repository, (folderId) async {
      for (var id in _selectedIds) {
        final note = await widget.repository.getNoteById(id);
        if (note != null) {
          if (folderId != null) {
            note.folder.targetId = folderId;
          } else {
            note.folder.target = null;
          }
          await widget.repository.saveNote(note);
        }
      }
      setState(() {
        _selectedIds.clear();
        _isSelectionMode = false;
      });
      _loadNotes();
    });
  }

  void _batchToggleLock() async {
    final anyLocked = _notes.any((n) => _selectedIds.contains(n.id) && n.isLocked);
    final newLockState = !anyLocked;
    for (var id in _selectedIds) {
      final note = await widget.repository.getNoteById(id);
      if (note != null) {
        note.isLocked = newLockState;
        await widget.repository.saveNote(note);
      }
    }
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });
    _loadNotes();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(newLockState ? "Notes locked" : "Notes unlocked"),
      ),
    );
  }

  void _batchExport() {
    final selectedNotes = _notes.where((n) => _selectedIds.contains(n.id)).toList();
    if (selectedNotes.isEmpty) return;

    final hasLocked = selectedNotes.any((n) => n.isLocked);
    final exportableNotes = selectedNotes.where((n) => !n.isLocked).toList();

    if (exportableNotes.isEmpty && hasLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: const Text(
            "The selected notes are locked and can't be exported. Please unlock them before exporting.",
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Text(
                "Export Notes",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.code_rounded),
              title: const Text("Markdown + Assets"),
              onTap: () {
                Navigator.of(ctx).pop();
                final text = exportableNotes
                    .map((n) => "# ${n.title}\n\n${n.contentMarkdown}")
                    .join("\n\n---\n\n");
                SharePlus.instance.share(ShareParams(
                  text: text,
                  subject: "Exported Notes (${exportableNotes.length})",
                ));
                _finishBatchExport(exportableNotes.length);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text("PDF"),
              onTap: () {
                Navigator.of(ctx).pop();
                final text = exportableNotes
                    .map((n) => "${n.title}\n\n${n.contentMarkdown}")
                    .join("\n\n---\n\n");
                SharePlus.instance.share(ShareParams(
                  text: text,
                  subject: "Exported Notes PDF (${exportableNotes.length})",
                ));
                _finishBatchExport(exportableNotes.length);
              },
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text("Plain Text + Assets"),
              onTap: () {
                Navigator.of(ctx).pop();
                final text = exportableNotes
                    .map((n) => "${n.title}\n\n${n.contentMarkdown}")
                    .join("\n\n---\n\n");
                SharePlus.instance.share(ShareParams(
                  text: text,
                  subject: "Exported Notes (${exportableNotes.length})",
                ));
                _finishBatchExport(exportableNotes.length);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _finishBatchExport(int count) {
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text("Exported $count notes"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;

        if (!isTablet) {
          return Scaffold(
            appBar: _buildAppBar(context, false),
            drawer: _buildDrawer(context, isDark),
            body: Stack(
              children: [
                _buildNotesList(isDark, false),
                _buildBottomBar(isDark, false),
              ],
            ),
          );
        }

        // Dual Pane Layout (Tablet & Foldable: 35% List / 65% Editor)
        final listWidth = constraints.maxWidth * 0.35;
        return Scaffold(
          appBar: _buildAppBar(context, true),
          drawer: _buildDrawer(context, isDark),
          body: Row(
            children: [
              SizedBox(
                width: listWidth,
                child: Stack(
                  children: [
                    _buildNotesList(isDark, true),
                    _buildBottomBar(isDark, true),
                  ],
                ),
              ),
              const VerticalDivider(width: 1, thickness: 1),
              Expanded(
                child: _selectedTabletNote != null
                    ? NoteEditorScreen(
                        key: ValueKey(_selectedTabletNote!.id),
                        note: _selectedTabletNote!,
                        repository: widget.repository,
                      )
                    : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_note_rounded, size: 72, color: isDark ? Colors.white24 : Colors.black26),
                            const SizedBox(height: 12),
                            Text("Select a note to view or edit", style: AppTypography.headingSmall),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context, bool isDark) {
    final themeCtrl = AppThemeController.instance;
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_note_rounded, size: 44, color: themeCtrl.accentColor),
                  const SizedBox(height: 8),
                  const Text("Notes", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const Text("com.dusrel.note", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            ListTile(
              leading: const Text("📝", style: TextStyle(fontSize: 20)),
              title: const Text("All Notes"),
              trailing: Text("${_notes.length}", style: const TextStyle(color: Colors.grey)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Text("⭐️", style: TextStyle(fontSize: 20)),
              title: const Text("Pinned"),
              trailing: Text("${_pinnedNotes.length}", style: const TextStyle(color: Colors.grey)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Text("📁", style: TextStyle(fontSize: 20)),
              title: const Text("Unlimited Folders"),
              trailing: Icon(Icons.star, color: themeCtrl.accentColor, size: 16),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FoldersScreen(repository: widget.repository),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Text("🗑️", style: TextStyle(fontSize: 20)),
              title: const Text("Recently Deleted"),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TrashScreen(repository: widget.repository),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text("Settings"),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(repository: widget.repository),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isTablet) {
    final themeCtrl = AppThemeController.instance;
    return AppBar(
      title: Text(
        _isSelectionMode ? "${_selectedIds.length} Selected" : "Notes",
        style: AppTypography.headingLarge,
      ),
      leading: _isSelectionMode
          ? IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => setState(() {
                _isSelectionMode = false;
                _selectedIds.clear();
              }),
            )
          : TextButton(
              onPressed: () async {
                final res = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FoldersScreen(repository: widget.repository),
                  ),
                );
                if (res == 'new_note') {
                  _openEditor(null, '', isTablet);
                }
                _loadNotes();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_ios, color: themeCtrl.accentColor, size: 16),
                  Text(
                    "Folders",
                    style: TextStyle(
                      color: themeCtrl.accentColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
      leadingWidth: _isSelectionMode ? 56 : 100,
      actions: [
        if (_isSelectionMode)
          TextButton(
            onPressed: () {
              setState(() {
                final allIds = {..._notes.map((n) => n.id), ..._pinnedNotes.map((n) => n.id)};
                if (_selectedIds.length == allIds.length) {
                  _selectedIds.clear();
                } else {
                  _selectedIds.addAll(allIds);
                }
              });
            },
            child: Text(
              _selectedIds.length == (_notes.length + _pinnedNotes.length) && (_notes.length + _pinnedNotes.length) > 0
                  ? "Deselect All"
                  : "Select All",
              style: TextStyle(
                color: themeCtrl.accentColor,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          )
        else ...[
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: "Search",
            onPressed: () {
              _searchFocusNode.requestFocus();
            },
          ),
          PullDownButton(
            itemBuilder: (context) => [
              PullDownMenuItem(
                title: 'Select Notes',
                icon: CupertinoIcons.checkmark_circle,
                onTap: () => setState(() => _isSelectionMode = true),
              ),
              PullDownMenuItem(
                title: 'Widget Options',
                icon: CupertinoIcons.square_grid_2x2,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WidgetConfiguratorScreen(repository: widget.repository),
                    ),
                  );
                },
              ),
              PullDownMenuItem(
                title: 'Settings',
                icon: CupertinoIcons.settings,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SettingsScreen(repository: widget.repository),
                    ),
                  );
                },
              ),
            ],
            buttonBuilder: (context, showMenu) => IconButton(
              icon: Icon(Icons.more_horiz_rounded, color: themeCtrl.accentColor),
              onPressed: showMenu,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNotesList(bool isDark, bool isTablet) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingMedium,
              vertical: AppDimensions.paddingSmall,
            ),
            child: TextField(
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: "Search notes, tags, attachments...",
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusInput),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
        ),
        if (_isLoading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator(color: AppColors.accentGold)),
          )
        else if (_filteredNotes.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.note_alt_outlined, size: 64, color: isDark ? Colors.white24 : Colors.black26),
                  const SizedBox(height: 12),
                  Text(
                    _searchQuery.isEmpty ? "No Notes" : "No result found",
                    style: AppTypography.headingSmall.copyWith(
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          if (_pinnedNotes.isNotEmpty)
            MultiSliver(
              pushPinnedChildren: true,
              children: [
                SliverPinnedHeader(
                  child: Container(
                    color: isDark ? AppColors.darkScaffold : AppColors.lightScaffold,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: Text(
                      "PINNED",
                      style: AppTypography.captionSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: AppColors.accentGold,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final note = _pinnedNotes[index];
                      return NoteCard(
                        note: note,
                        isSelectionMode: _isSelectionMode,
                        isSelected: _selectedIds.contains(note.id),
                        onSelectToggle: (_) => _toggleSelection(note.id),
                        onTap: () => _openEditor(note, '', isTablet),
                        onLongPress: () {
                          HapticFeedback.heavyImpact();
                          _toggleSelection(note.id);
                          setState(() {
                            _isSelectionMode = true;
                          });
                        },
                        onPinToggle: (pin) async {
                          await widget.repository.pinNote(note.id, pin);
                          _loadNotes();
                        },
                        onMoveToFolder: () {
                          MoveToFolderSheet.show(context, widget.repository, (folderId) async {
                            note.folder.targetId = folderId;
                            await widget.repository.saveNote(note);
                            _loadNotes();
                          });
                        },
                        onDelete: () => _deleteNote(note),
                      );
                    },
                    childCount: _pinnedNotes.length,
                  ),
                ),
              ],
            ),
          if (_unpinnedNotes.isNotEmpty)
            MultiSliver(
              pushPinnedChildren: true,
              children: [
                if (_pinnedNotes.isNotEmpty)
                  SliverPinnedHeader(
                    child: Container(
                      color: isDark ? AppColors.darkScaffold : AppColors.lightScaffold,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                      child: Text(
                        "NOTES",
                        style: AppTypography.captionSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final note = _unpinnedNotes[index];
                      return NoteCard(
                        note: note,
                        isSelectionMode: _isSelectionMode,
                        isSelected: _selectedIds.contains(note.id),
                        onSelectToggle: (_) => _toggleSelection(note.id),
                        onTap: () => _openEditor(note, '', isTablet),
                        onLongPress: () {
                          HapticFeedback.heavyImpact();
                          _toggleSelection(note.id);
                          setState(() {
                            _isSelectionMode = true;
                          });
                        },
                        onPinToggle: (pin) async {
                          await widget.repository.pinNote(note.id, pin);
                          _loadNotes();
                        },
                        onMoveToFolder: () {
                          MoveToFolderSheet.show(context, widget.repository, (folderId) async {
                            note.folder.targetId = folderId;
                            await widget.repository.saveNote(note);
                            _loadNotes();
                          });
                        },
                        onDelete: () => _deleteNote(note),
                      );
                    },
                    childCount: _unpinnedNotes.length,
                  ),
                ),
              ],
            ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ],
    );
  }

  Widget _buildBottomBar(bool isDark, bool isTablet) {
    if (_isSelectionMode) {
      return Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: Container(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.folder_outlined),
                  tooltip: "Move to Folder",
                  onPressed: _selectedIds.isNotEmpty ? _batchMoveToFolder : null,
                ),
                IconButton(
                  icon: Icon(_notes.any((n) => _selectedIds.contains(n.id) && n.isLocked)
                      ? Icons.lock_open_rounded
                      : Icons.lock_outline_rounded),
                  tooltip: "Lock Notes",
                  onPressed: _selectedIds.isNotEmpty ? _batchToggleLock : null,
                ),
                IconButton(
                  icon: Icon(_pinnedNotes.any((n) => _selectedIds.contains(n.id))
                      ? Icons.push_pin_outlined
                      : Icons.push_pin_rounded),
                  tooltip: "Pin / Unpin",
                  onPressed: _selectedIds.isNotEmpty ? _toggleBatchPin : null,
                ),
                IconButton(
                  icon: const Icon(Icons.ios_share_rounded),
                  tooltip: "Batch Export",
                  onPressed: _selectedIds.isNotEmpty ? _batchExport : null,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.tagCoral),
                  tooltip: "Trash",
                  onPressed: _selectedIds.isNotEmpty ? _batchDelete : null,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 24,
      child: CaptureBar(
        onNewNote: () => _openEditor(null, '', isTablet),
        onNewChecklist: () => _openEditor(null, "- [ ] ", isTablet),
        onRecordAudio: () {
          AudioRecordingModal.show(context, (memo) {
            _openEditor(null, "\n$memo\n", isTablet);
          });
        },
        onScanDocument: () async {
          try {
            final pictures = await CunningDocumentScanner.getPictures(noOfPages: 50, asPdf: true);
            if (pictures != null && pictures.isNotEmpty) {
              final dir = await getApplicationDocumentsDirectory();
              final dest = File('${dir.path}/scan_${DateTime.now().millisecondsSinceEpoch}.pdf');
              await File(pictures.first).copy(dest.path);
              _openEditor(null, "\n[📄 Scanned Document (${dest.path.split(Platform.pathSeparator).last})](${dest.path})\n", isTablet);
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Scan Error: $e")));
            }
          }
        },
      ),
    );
  }
}
