import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../notes/data/models/folder_entity.dart';
import '../../../notes/domain/repositories/note_repository.dart';

class MoveToFolderSheet extends StatefulWidget {
  final NoteRepository repository;
  final ValueChanged<int?> onFolderSelected;

  const MoveToFolderSheet({
    super.key,
    required this.repository,
    required this.onFolderSelected,
  });

  static Future<void> show(
    BuildContext context,
    NoteRepository repo,
    ValueChanged<int?> onSelect,
  ) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => MoveToFolderSheet(repository: repo, onFolderSelected: onSelect),
    );
  }

  @override
  State<MoveToFolderSheet> createState() => _MoveToFolderSheetState();
}

class _MoveToFolderSheetState extends State<MoveToFolderSheet> {
  List<FolderEntity> _folders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final folders = await widget.repository.getAllFolders();
    setState(() {
      _folders = folders;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusSheet),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
        vertical: AppDimensions.paddingMedium,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Move to Folder",
              style: AppTypography.headingSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: AppColors.accentGold))
            else
              Expanded(
                child: ListView(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.note_alt_rounded, color: AppColors.accentGold),
                      title: const Text("Main Notes (No Folder)"),
                      onTap: () {
                        widget.onFolderSelected(null);
                        Navigator.of(context).pop();
                      },
                    ),
                    const Divider(),
                    ..._folders.map((f) => ListTile(
                          leading: Icon(Icons.folder_rounded, color: Color(f.colorValue)),
                          title: Text(f.name),
                          onTap: () {
                            widget.onFolderSelected(f.id);
                            Navigator.of(context).pop();
                          },
                        )),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

