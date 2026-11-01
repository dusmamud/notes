import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../notes/data/models/note_entity.dart';
import '../../../notes/domain/repositories/note_repository.dart';

class TrashScreen extends StatefulWidget {
  final NoteRepository repository;

  const TrashScreen({super.key, required this.repository});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  List<NoteEntity> _trashNotes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrash();
  }

  Future<void> _loadTrash() async {
    setState(() => _isLoading = true);
    final notes = await widget.repository.getTrashNotes();
    setState(() {
      _trashNotes = notes;
      _isLoading = false;
    });
  }

  void _restoreNote(int id) async {
    HapticFeedback.lightImpact();
    await widget.repository.restoreNote(id);
    _loadTrash();
  }

  void _deletePermanently(int id) async {
    HapticFeedback.heavyImpact();
    await widget.repository.deleteNote(id, permanent: true);
    _loadTrash();
  }

  void _emptyTrashDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Empty Trash?"),
        content: const Text("All notes in Trash will be permanently deleted. This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tagCoral,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              for (var n in _trashNotes) {
                await widget.repository.deleteNote(n.id, permanent: true);
              }
              if (context.mounted) Navigator.of(ctx).pop();
              _loadTrash();
            },
            child: const Text("Empty Trash"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Trash"),
        actions: [
          if (_trashNotes.isNotEmpty)
            TextButton(
              onPressed: _emptyTrashDialog,
              child: const Text("Empty", style: TextStyle(color: AppColors.tagCoral, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Notes in Trash are deleted automatically after 30 days.",
                    style: AppTypography.captionSmall,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accentGold))
                : _trashNotes.isEmpty
                    ? Center(
                        child: Text("Trash is Empty", style: AppTypography.headingSmall.copyWith(color: Colors.grey)),
                      )
                    : ListView.builder(
                        itemCount: _trashNotes.length,
                        itemBuilder: (context, index) {
                          final note = _trashNotes[index];
                          return ListTile(
                            title: Text(note.title.isNotEmpty ? note.title : "Untitled Note"),
                            subtitle: Text(
                              note.contentMarkdown,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.captionSmall,
                            ),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert_rounded),
                              onSelected: (val) {
                                if (val == 'restore') {
                                  _restoreNote(note.id);
                                } else if (val == 'delete') {
                                  _deletePermanently(note.id);
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'restore',
                                  child: Row(
                                    children: [
                                      Icon(Icons.restore_rounded, size: 20, color: AppColors.tagBlue),
                                      SizedBox(width: 8),
                                      Text("Restore Note"),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_forever_rounded, size: 20, color: AppColors.tagCoral),
                                      SizedBox(width: 8),
                                      Text("Delete Permanently", style: TextStyle(color: AppColors.tagCoral)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

