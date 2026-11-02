import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
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
  int _trashCount = 0;
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
    setState(() {
      _totalNotesCount = allNotes.length;
      _trashCount = trashNotes.length;
      _folders = folders;
      _isLoading = false;
    });
  }

  void _showNewFolderDialog() {
    final controller = TextEditingController();
    int selectedColor = AppColors.brandPrimary.toARGB32();
    String selectedEmoji = "📁";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("New Folder"),
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
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white12
                              : Colors.black12,
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
                  children: [
                    _ColorChoice(
                      color: AppColors.accentGold,
                      isSelected: selectedColor == AppColors.accentGold.toARGB32(),
                      onTap: () => setDialogState(() => selectedColor = AppColors.accentGold.toARGB32()),
                    ),
                    _ColorChoice(
                      color: AppColors.tagBlue,
                      isSelected: selectedColor == AppColors.tagBlue.toARGB32(),
                      onTap: () => setDialogState(() => selectedColor = AppColors.tagBlue.toARGB32()),
                    ),
                    _ColorChoice(
                      color: AppColors.tagTeal,
                      isSelected: selectedColor == AppColors.tagTeal.toARGB32(),
                      onTap: () => setDialogState(() => selectedColor = AppColors.tagTeal.toARGB32()),
                    ),
                    _ColorChoice(
                      color: AppColors.tagPurple,
                      isSelected: selectedColor == AppColors.tagPurple.toARGB32(),
                      onTap: () => setDialogState(() => selectedColor = AppColors.tagPurple.toARGB32()),
                    ),
                    _ColorChoice(
                      color: AppColors.tagCoral,
                      isSelected: selectedColor == AppColors.tagCoral.toARGB32(),
                      onTap: () => setDialogState(() => selectedColor = AppColors.tagCoral.toARGB32()),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = controller.text.trim();
                  if (name.isNotEmpty) {
                    final folder = FolderEntity(
                      uuid: const Uuid().v4(),
                      name: name,
                      emoji: selectedEmoji,
                      colorValue: selectedColor,
                    );
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

    return Scaffold(
      appBar: AppBar(
        title: const Text("Folders"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentGold))
          : ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.note_alt_rounded, color: AppColors.accentGold),
                  title: const Text("All Notes", style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: Text("$_totalNotesCount", style: AppTypography.captionMedium),
                  onTap: () => Navigator.of(context).pop(),
                ),
                ListTile(
                  leading: const Icon(Icons.flash_on_rounded, color: AppColors.accentOrange),
                  title: const Text("Quick Notes", style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: Text("$_totalNotesCount", style: AppTypography.captionMedium),
                  onTap: () => Navigator.of(context).pop(),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("MY FOLDERS", style: AppTypography.captionSmall.copyWith(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.create_new_folder_outlined, color: AppColors.accentGold, size: 22),
                        tooltip: "New Folder",
                        onPressed: _showNewFolderDialog,
                      ),
                    ],
                  ),
                ),
                if (_folders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Text("No custom folders created", style: AppTypography.captionMedium),
                    ),
                  )
                else
                  ..._folders.map((f) {
                    return ListTile(
                      leading: Text(
                        f.emoji ?? '📁',
                        style: const TextStyle(fontSize: 22),
                      ),
                      title: Text(f.name),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        onPressed: () async {
                          await widget.repository.deleteFolder(f.id);
                          _loadData();
                        },
                      ),
                    );
                  }),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: AppColors.tagCoral),
                  title: const Text("Trash", style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: Text("$_trashCount", style: AppTypography.captionMedium),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TrashScreen(repository: widget.repository),
                      ),
                    );
                    _loadData();
                  },
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.add_rounded, color: AppColors.accentGold),
                label: const Text("New Folder", style: TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold)),
                onPressed: _showNewFolderDialog,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorChoice extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorChoice({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
          boxShadow: isSelected
              ? [const BoxShadow(color: Colors.black26, blurRadius: 4)]
              : null,
        ),
      ),
    );
  }
}
