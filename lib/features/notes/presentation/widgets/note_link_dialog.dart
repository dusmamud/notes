import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/models/note_entity.dart';
import '../../domain/repositories/note_repository.dart';

class NoteLinkDialog extends StatefulWidget {
  final NoteRepository repository;
  final ValueChanged<String> onLinkSelected;

  const NoteLinkDialog({
    super.key,
    required this.repository,
    required this.onLinkSelected,
  });

  static Future<void> show(
    BuildContext context,
    NoteRepository repository,
    ValueChanged<String> onLinkSelected,
  ) {
    return showDialog(
      context: context,
      builder: (_) => NoteLinkDialog(
        repository: repository,
        onLinkSelected: onLinkSelected,
      ),
    );
  }

  @override
  State<NoteLinkDialog> createState() => _NoteLinkDialogState();
}

class _NoteLinkDialogState extends State<NoteLinkDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<NoteEntity> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    final allNotes = await widget.repository.getAllNotes();
    setState(() {
      _notes = allNotes;
      _isLoading = false;
    });
  }

  List<NoteEntity> get _filteredNotes {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _notes;
    return _notes.where((n) => n.title.toLowerCase().contains(query)).toList();
  }

  void _selectNote(NoteEntity note) {
    // Check if there are headings to link
    final headings = <String>[];
    final lines = note.contentMarkdown.split('\n');
    for (final line in lines) {
      if (line.startsWith('# ') || line.startsWith('## ') || line.startsWith('### ')) {
        headings.add(line.replaceFirst(RegExp(r'^#+\s*'), ''));
      }
    }

    if (headings.isEmpty) {
      widget.onLinkSelected(">>${note.title.isEmpty ? 'Untitled' : note.title}");
      Navigator.pop(context);
    } else {
      // Show section picker
      showModalBottomSheet(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text("Link Entire Note", style: AppTypography.bodyLarge),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onLinkSelected(">>${note.title.isEmpty ? 'Untitled' : note.title}");
                  Navigator.pop(context);
                },
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("LINK TO SECTION (/) :", style: AppTypography.captionSmall),
              ),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: headings.length,
                  itemBuilder: (_, idx) => ListTile(
                    leading: const Icon(Icons.tag_rounded, size: 20),
                    title: Text(headings[idx]),
                    onTap: () {
                      Navigator.pop(ctx);
                      widget.onLinkSelected(">>${note.title.isEmpty ? 'Untitled' : note.title}/${headings[idx]}");
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _createNoteOnTheFly() async {
    final title = _searchController.text.trim();
    if (title.isEmpty) return;

    final newNote = NoteEntity(
      title: title,
      contentMarkdown: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await widget.repository.saveNote(newNote);
    widget.onLinkSelected(">>$title");
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim();

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.link_rounded, color: AppColors.accentGold),
          const SizedBox(width: 8),
          const Text("Add Note Link (>>)"),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search note or type title to create...",
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => setState(() => _searchController.clear()),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _filteredNotes.length + (query.isNotEmpty ? 1 : 0),
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    if (index == _filteredNotes.length && query.isNotEmpty) {
                      return ListTile(
                        leading: const Icon(Icons.add_rounded, color: AppColors.accentGold),
                        title: Text('Create Note "$query"', style: const TextStyle(color: AppColors.accentGold)),
                        onTap: _createNoteOnTheFly,
                      );
                    }
                    final note = _filteredNotes[index];
                    return ListTile(
                      title: Text(note.title.isEmpty ? "Untitled Note" : note.title),
                      subtitle: note.contentMarkdown.isNotEmpty
                          ? Text(
                              note.contentMarkdown,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.captionSmall,
                            )
                          : null,
                      onTap: () => _selectNote(note),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
      ],
    );
  }
}

