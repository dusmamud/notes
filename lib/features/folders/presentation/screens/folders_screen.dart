import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/app_theme_controller.dart';
import '../../../notes/data/models/folder_entity.dart';
import '../../../notes/domain/repositories/note_repository.dart';
import 'trash_screen.dart';

class FoldersScreen extends StatefulWidget {
  final NoteRepository repository;

  const FoldersScreen({super.key, required this.repository});

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  List<FolderEntity> _folders = [];
  int _totalNotesCount = 0;
  int _pinnedCount = 0;
  int _lockedCount = 0;
  int _mathNotesCount = 0;
  int _trashCount = 0;
  Map<String, int> _tagCounts = {};
  Map<int, int> _folderNoteCounts = {};
  bool _isEditMode = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final allNotes = await widget.repository.getAllNotes();
    final trashNotes = await widget.repository.getTrashNotes();
    final folders = await widget.repository.getAllFolders();

    int pinned = 0;
    int locked = 0;
    int mathNotes = 0;
    final tags = <String, int>{};
    final folderCounts = <int, int>{};

    for (var n in allNotes) {
      if (n.isPinned) pinned++;
      if (n.isLocked) locked++;
      if (n.contentMarkdown.contains('=') || n.mathResultsMode != 'off') mathNotes++;

      final fId = n.folder.targetId;
      if (fId > 0) {
        folderCounts[fId] = (folderCounts[fId] ?? 0) + 1;
      }

      // Extract #tags
      final matches = RegExp(r'#\w+').allMatches(n.contentMarkdown);
      for (var m in matches) {
        final tag = m.group(0)!;
        tags[tag] = (tags[tag] ?? 0) + 1;
      }
    }

    if (mounted) {
      setState(() {
        _totalNotesCount = allNotes.length;
        _pinnedCount = pinned;
        _lockedCount = locked;
        _mathNotesCount = mathNotes;
        _trashCount = trashNotes.length;
        _tagCounts = tags;
        _folderNoteCounts = folderCounts;
        _folders = folders;
        _isLoading = false;
      });
    }
  }

  void _showNewFolderDialog({FolderEntity? parent}) {
    final controller = TextEditingController();
    int selectedColor = AppThemeController.instance.accentColor.toARGB32();
    String selectedEmoji = "📁";

    final accents = [
      AppColors.brandPrimary,
      AppColors.accentBlue,
      AppColors.accentTeal,
      AppColors.accentPurple,
      AppColors.accentRed,
      AppColors.accentOrange,
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            title: Text(parent != null ? "New Subfolder" : "New Folder"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (bCtx) => SizedBox(
                            height: 280,
                            child: EmojiPicker(
                              onEmojiSelected: (category, emoji) {
                                setDialogState(() => selectedEmoji = emoji.emoji);
                                Navigator.of(bCtx).pop();
                              },
                              config: const Config(
                                height: 256,
                                checkPlatformCompatibility: true,
                              ),
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white12 : Colors.black12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(selectedEmoji, style: const TextStyle(fontSize: 26)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: "Folder Name",
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: accents.map((col) {
                    final isSel = selectedColor == col.toARGB32();
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = col.toARGB32()),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: col,
                          shape: BoxShape.circle,
                          border: isSel ? Border.all(color: Colors.white, width: 2.5) : null,
                        ),
                        child: isSel ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemeController.instance.accentColor,
                  foregroundColor: Colors.black,
                ),
                onPressed: () async {
                  final name = controller.text.trim();
                  if (name.isNotEmpty) {
                    final folder = FolderEntity(
                      uuid: const Uuid().v4(),
                      name: name,
                      emoji: selectedEmoji,
                      colorValue: selectedColor,
                    );
                    if (parent != null) {
                      folder.parentFolder.targetId = parent.id;
                    }
                    await widget.repository.saveFolder(folder);
                    if (context.mounted) Navigator.of(ctx).pop();
                    _loadData();
                  }
                },
                child: const Text("Create"),
              ),
            ],
          );
        },
      ),
    );
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
                        Text("Notes", style: TextStyle(color: themeCtrl.accentColor, fontSize: 16)),
                      ],
                    ),
                  ),
                  leadingWidth: 90,
                  actions: [
                    IconButton(
                      icon: Icon(Icons.create_new_folder_outlined, color: themeCtrl.accentColor),
                      onPressed: () => _showNewFolderDialog(),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _isEditMode = !_isEditMode),
                      child: Text(
                        _isEditMode ? "Done" : "Edit",
                        style: TextStyle(color: themeCtrl.accentColor, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 20, bottom: 12),
                    title: Text(
                      "Folders",
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // SYSTEM FOLDERS
                      _buildSectionHeader("SYSTEM FOLDERS"),
                      _buildCard([
                        _buildRow(
                          icon: const Text("📝", style: TextStyle(fontSize: 20)),
                          title: "All Notes",
                          count: _totalNotesCount,
                          onTap: () => Navigator.pop(context),
                        ),
                        const Divider(height: 1),
                        _buildRow(
                          icon: const Text("⭐️", style: TextStyle(fontSize: 20)),
                          title: "Pinned Notes",
                          count: _pinnedCount,
                          onTap: () => Navigator.pop(context, 'pinned'),
                        ),
                        const Divider(height: 1),
                        _buildRow(
                          icon: const Text("🔒", style: TextStyle(fontSize: 20)),
                          title: "Locked Notes",
                          count: _lockedCount,
                          onTap: () => Navigator.pop(context, 'locked'),
                        ),
                        const Divider(height: 1),
                        _buildRow(
                          icon: const Text("∑", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.accentGold)),
                          title: "Math Notes",
                          count: _mathNotesCount,
                          onTap: () => Navigator.pop(context, 'math'),
                        ),
                      ]),

                      // CUSTOM FOLDERS
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionHeader("CUSTOM FOLDERS"),
                          IconButton(
                            icon: Icon(Icons.add, color: themeCtrl.accentColor, size: 20),
                            onPressed: () => _showNewFolderDialog(),
                          ),
                        ],
                      ),
                      if (_folders.isEmpty)
                        Card(
                          elevation: 0,
                          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          child: const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Center(
                              child: Text("No custom folders created", style: TextStyle(color: Colors.grey)),
                            ),
                          ),
                        )
                      else
                        _buildCard(
                          _folders.map((f) {
                            final count = _folderNoteCounts[f.id] ?? 0;
                            return Column(
                              children: [
                                ListTile(
                                  leading: Text(f.emoji ?? "📁", style: const TextStyle(fontSize: 22)),
                                  title: Text(f.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text("$count", style: const TextStyle(color: Colors.grey, fontSize: 14)),
                                      if (_isEditMode) ...[
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline, size: 18, color: Colors.blue),
                                          tooltip: "Add subfolder",
                                          onPressed: () => _showNewFolderDialog(parent: f),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                          onPressed: () async {
                                            await widget.repository.deleteFolder(f.id);
                                            _loadData();
                                          },
                                        ),
                                      ] else ...[
                                        const SizedBox(width: 4),
                                        const Icon(Icons.chevron_right, color: Colors.grey),
                                      ],
                                    ],
                                  ),
                                  onTap: () {
                                    if (!_isEditMode) {
                                      Navigator.pop(context, f.id);
                                    }
                                  },
                                ),
                                const Divider(height: 1),
                              ],
                            );
                          }).toList(),
                        ),

                      // TAGS
                      const SizedBox(height: 16),
                      _buildSectionHeader("TAGS"),
                      Card(
                        elevation: 0,
                        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _tagCounts.isEmpty
                              ? Text(
                                  "No tags yet. Add #tags to notes to categorize them automatically.",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  ),
                                )
                              : Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _tagCounts.entries.map((entry) {
                                    return ActionChip(
                                      label: Text("${entry.key} (${entry.value})"),
                                      backgroundColor: isDark ? Colors.white12 : Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      onPressed: () {
                                        Navigator.pop(context, entry.key);
                                      },
                                    );
                                  }).toList(),
                                ),
                        ),
                      ),

                      // TRASH & ARCHIVE
                      const SizedBox(height: 16),
                      _buildSectionHeader("TRASH & ARCHIVE"),
                      _buildCard([
                        _buildRow(
                          icon: const Text("🗑️", style: TextStyle(fontSize: 20)),
                          title: "Recently Deleted",
                          count: _trashCount,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TrashScreen(repository: widget.repository),
                              ),
                            );
                            _loadData();
                          },
                        ),
                      ]),

                      const SizedBox(height: 60),
                    ]),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          border: Border(top: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE9E9E9))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () => _showNewFolderDialog(),
              icon: Icon(Icons.add_circle, color: themeCtrl.accentColor),
              label: Text("New Folder", style: TextStyle(color: themeCtrl.accentColor, fontWeight: FontWeight.bold)),
            ),
            IconButton(
              icon: Icon(Icons.edit_note_rounded, color: themeCtrl.accentColor, size: 28),
              onPressed: () => Navigator.pop(context, 'new_note'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
      child: Text(
        title,
        style: AppTypography.captionSmall.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
          color: isDark ? Colors.white54 : Colors.black54,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(children: children),
    );
  }

  Widget _buildRow({
    required Widget icon,
    required String title,
    required int count,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: icon,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("$count", style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
      onTap: onTap,
    );
  }
}
