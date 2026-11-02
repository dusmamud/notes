import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/app_theme_controller.dart';
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
    if (mounted) {
      setState(() {
        _trashNotes = notes;
        _isLoading = false;
      });
    }
  }

  void _restoreNote(int id) async {
    HapticFeedback.lightImpact();
    await widget.repository.restoreNote(id);
    _loadTrash();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Note restored"), duration: Duration(seconds: 2)),
      );
    }
  }

  void _deletePermanently(int id) async {
    HapticFeedback.heavyImpact();
    await widget.repository.deleteNote(id, permanent: true);
    _loadTrash();
  }

  void _emptyTrashDialog() {
    final themeCtrl = AppThemeController.instance;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Empty Trash?"),
        content: const Text("All notes in Recently Deleted will be permanently deleted. This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text("Cancel", style: TextStyle(color: themeCtrl.accentColor)),
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

  int _calculateDaysLeft(NoteEntity note) {
    if (note.deletedAt == null) return 30;
    final elapsed = DateTime.now().difference(note.deletedAt!).inDays;
    final left = 30 - elapsed;
    return left > 0 ? left : 0;
  }

  @override
  Widget build(BuildContext context) {
    final themeCtrl = AppThemeController.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentGold))
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 100,
                  leading: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_ios, color: themeCtrl.accentColor, size: 16),
                        Text("Folders", style: TextStyle(color: themeCtrl.accentColor, fontSize: 16)),
                      ],
                    ),
                  ),
                  leadingWidth: 95,
                  actions: [
                    if (_trashNotes.isNotEmpty)
                      TextButton(
                        onPressed: _emptyTrashDialog,
                        child: const Text(
                          "Empty",
                          style: TextStyle(color: AppColors.tagCoral, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 20, bottom: 12),
                    title: Text(
                      "Recently Deleted",
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),

                // 30-Day Notice Banner
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 20, color: themeCtrl.accentColor),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            "Notes are permanently deleted after 30 days. You can recover or permanently delete them.",
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_trashNotes.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 64, color: isDark ? Colors.white24 : Colors.black26),
                          const SizedBox(height: 16),
                          Text("No Deleted Notes", style: AppTypography.headingMedium),
                          const SizedBox(height: 6),
                          Text(
                            "Deleted notes wait here for 30 days before being purged.",
                            style: AppTypography.captionMedium.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final note = _trashNotes[index];
                          final daysLeft = _calculateDaysLeft(note);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Slidable(
                              key: ValueKey(note.id),
                              startActionPane: ActionPane(
                                motion: const ScrollMotion(),
                                children: [
                                  SlidableAction(
                                    onPressed: (_) => _restoreNote(note.id),
                                    backgroundColor: themeCtrl.accentColor,
                                    foregroundColor: Colors.white,
                                    icon: Icons.restore_rounded,
                                    label: 'Restore',
                                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                                  ),
                                ],
                              ),
                              endActionPane: ActionPane(
                                motion: const ScrollMotion(),
                                children: [
                                  SlidableAction(
                                    onPressed: (_) => _deletePermanently(note.id),
                                    backgroundColor: AppColors.tagCoral,
                                    foregroundColor: Colors.white,
                                    icon: Icons.delete_forever_rounded,
                                    label: 'Delete',
                                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                                  ),
                                ],
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark ? Colors.white12 : const Color(0xFFE9E9E9),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            note.title.isEmpty ? "Untitled Note" : note.title,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.tagCoral.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            "$daysLeft days left",
                                            style: const TextStyle(
                                              color: AppColors.tagCoral,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (note.contentMarkdown.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        note.contentMarkdown,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDark ? Colors.white70 : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: _trashNotes.length,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
