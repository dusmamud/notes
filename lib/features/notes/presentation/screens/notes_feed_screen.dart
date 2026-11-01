import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../folders/presentation/screens/folders_screen.dart';
import '../../../folders/presentation/widgets/move_to_folder_sheet.dart';
import '../../../onboarding/presentation/whats_new_sheet.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../widgets/presentation/screens/widget_configurator_screen.dart';
import '../../data/models/note_entity.dart';
import '../../domain/repositories/note_repository.dart';
import '../widgets/audio_recording_modal.dart';
import '../widgets/capture_bar.dart';
import '../widgets/note_card.dart';
import '../widgets/note_context_menu_dialog.dart';
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

  @override
  void initState() {
    super.initState();
    _loadNotes();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WhatsNewSheet.showIfNeeded(context);
    });
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    final notes = await widget.repository.getAllNotes();
    setState(() {
      _notes = notes;
      _isLoading = false;
    });
  }

  List<NoteEntity> get _filteredNotes {
    if (_searchQuery.isEmpty) return _notes;
    final q = _searchQuery.toLowerCase();
    return _notes.where((n) {
      return n.title.toLowerCase().contains(q) ||
          n.contentMarkdown.toLowerCase().contains(q);
    }).toList();
  }

  List<NoteEntity> get _pinnedNotes =>
      _filteredNotes.where((n) => n.isPinned).toList();

  List<NoteEntity> get _unpinnedNotes =>
      _filteredNotes.where((n) => !n.isPinned).toList();

  void _openEditor([NoteEntity? note, String initialContent = '']) async {
    final noteToEdit = note ??
        NoteEntity(
          title: '',
          contentMarkdown: initialContent,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

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

  void _batchDelete() async {
    for (var id in _selectedIds) {
      await widget.repository.deleteNote(id);
    }
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });
    _loadNotes();
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

  void _openContextMenu(NoteEntity note) {
    HapticFeedback.heavyImpact();
    NoteContextMenuDialog.show(context, note, (action) async {
      switch (action) {
        case NoteContextAction.pin:
          await widget.repository.pinNote(note.id, !note.isPinned);
          _loadNotes();
          break;
        case NoteContextAction.lock:
          note.isLocked = !note.isLocked;
          await widget.repository.saveNote(note);
          _loadNotes();
          break;
        case NoteContextAction.duplicate:
          final clone = NoteEntity(
            title: "${note.title} (Copy)",
            contentMarkdown: note.contentMarkdown,
            contentJson: note.contentJson,
            colorValue: note.colorValue,
            mathResultsMode: note.mathResultsMode,
          );
          await widget.repository.saveNote(clone);
          _loadNotes();
          break;
        case NoteContextAction.moveToFolder:
          MoveToFolderSheet.show(context, widget.repository, (folderId) async {
            if (folderId != null) {
              note.folder.targetId = folderId;
            } else {
              note.folder.target = null;
            }
            await widget.repository.saveNote(note);
            _loadNotes();
          });
          break;
        case NoteContextAction.share:
          // Share preview
          break;
        case NoteContextAction.trash:
          await widget.repository.deleteNote(note.id);
          _loadNotes();
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
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
            : IconButton(
                icon: const Icon(Icons.folder_outlined),
                tooltip: "Folders",
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FoldersScreen(repository: widget.repository),
                    ),
                  );
                  _loadNotes();
                },
              ),
        actions: [
          if (!_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.checklist_rounded),
              tooltip: "Select Notes",
              onPressed: () => setState(() => _isSelectionMode = true),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz_rounded),
              onSelected: (val) {
                if (val == 'select') {
                  setState(() => _isSelectionMode = true);
                } else if (val == 'widgets') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WidgetConfiguratorScreen(repository: widget.repository),
                    ),
                  );
                } else if (val == 'settings') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SettingsScreen(repository: widget.repository),
                    ),
                  );
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'select',
                  child: Row(
                    children: [
                      Icon(Icons.checklist_rounded, size: 20),
                      SizedBox(width: 8),
                      Text("Select Notes"),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'widgets',
                  child: Row(
                    children: [
                      Icon(Icons.widgets_outlined, size: 20),
                      SizedBox(width: 8),
                      Text("Widget Options"),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings_outlined, size: 20),
                      SizedBox(width: 8),
                      Text("Settings"),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingMedium,
                    vertical: AppDimensions.paddingSmall,
                  ),
                  child: TextField(
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
                          _searchQuery.isEmpty ? "No Notes Yet" : "No Matching Notes",
                          style: AppTypography.headingSmall.copyWith(
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                if (_pinnedNotes.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
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
                          onTap: () => _openEditor(note),
                          onLongPress: () {
                            if (_isSelectionMode) {
                              _toggleSelection(note.id);
                            } else {
                              _openContextMenu(note);
                            }
                          },
                          onPinToggle: (pin) async {
                            await widget.repository.pinNote(note.id, pin);
                            _loadNotes();
                          },
                          onDelete: () async {
                            await widget.repository.deleteNote(note.id);
                            _loadNotes();
                          },
                        );
                      },
                      childCount: _pinnedNotes.length,
                    ),
                  ),
                ],
                if (_unpinnedNotes.isNotEmpty) ...[
                  if (_pinnedNotes.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: Text(
                          "NOTES",
                          style: AppTypography.captionSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
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
                          onTap: () => _openEditor(note),
                          onLongPress: () {
                            if (_isSelectionMode) {
                              _toggleSelection(note.id);
                            } else {
                              _openContextMenu(note);
                            }
                          },
                          onPinToggle: (pin) async {
                            await widget.repository.pinNote(note.id, pin);
                            _loadNotes();
                          },
                          onDelete: () async {
                            await widget.repository.deleteNote(note.id);
                            _loadNotes();
                          },
                        );
                      },
                      childCount: _unpinnedNotes.length,
                    ),
                  ),
                ],
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ],
          ),
          if (_isSelectionMode)
            Positioned(
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
                        icon: const Icon(Icons.push_pin_rounded),
                        tooltip: "Pin / Unpin",
                        onPressed: _selectedIds.isNotEmpty ? () => _batchPin(true) : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.folder_outlined),
                        tooltip: "Move to Folder",
                        onPressed: _selectedIds.isNotEmpty ? _batchMoveToFolder : null,
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
            )
          else
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: CaptureBar(
                onNewNote: () => _openEditor(),
                onNewChecklist: () => _openEditor(null, "- [ ] "),
                onRecordAudio: () {
                  AudioRecordingModal.show(context, (memo) {
                    _openEditor(null, "\n$memo\n");
                  });
                },
                onScanDocument: () => _openEditor(null, "\n📄 [Scanned Document PDF]\n"),
              ),
            ),
        ],
      ),
    );
  }
}
