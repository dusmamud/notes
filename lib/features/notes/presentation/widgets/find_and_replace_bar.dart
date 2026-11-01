import 'package:flutter/material.dart';
import '../../../../core/constants/app_typography.dart';

class FindAndReplaceBar extends StatefulWidget {
  final TextEditingController contentController;
  final VoidCallback onClose;

  const FindAndReplaceBar({
    super.key,
    required this.contentController,
    required this.onClose,
  });

  @override
  State<FindAndReplaceBar> createState() => _FindAndReplaceBarState();
}

class _FindAndReplaceBarState extends State<FindAndReplaceBar> {
  final TextEditingController _findController = TextEditingController();
  final TextEditingController _replaceController = TextEditingController();
  int _matchCount = 0;
  int _currentMatchIndex = 0;

  @override
  void initState() {
    super.initState();
    _findController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _findController.dispose();
    _replaceController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _findController.text;
    if (query.isEmpty) {
      setState(() {
        _matchCount = 0;
        _currentMatchIndex = 0;
      });
      return;
    }
    final text = widget.contentController.text;
    final matches = RegExp(RegExp.escape(query), caseSensitive: false).allMatches(text);
    setState(() {
      _matchCount = matches.length;
      _currentMatchIndex = _matchCount > 0 ? 1 : 0;
    });
  }

  void _replaceFirst() {
    final find = _findController.text;
    final replace = _replaceController.text;
    if (find.isEmpty) return;
    final text = widget.contentController.text;
    final match = RegExp(RegExp.escape(find), caseSensitive: false).firstMatch(text);
    if (match != null) {
      final newText = text.replaceRange(match.start, match.end, replace);
      widget.contentController.text = newText;
      _onSearchChanged();
    }
  }

  void _replaceAll() {
    final find = _findController.text;
    final replace = _replaceController.text;
    if (find.isEmpty) return;
    final text = widget.contentController.text;
    final newText = text.replaceAll(RegExp(RegExp.escape(find), caseSensitive: false), replace);
    widget.contentController.text = newText;
    _onSearchChanged();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        border: Border(
          bottom: BorderSide(color: isDark ? Colors.white10 : Colors.black12, width: 0.5),
        ),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _findController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: "Find in note",
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text("$_currentMatchIndex/$_matchCount", style: AppTypography.captionSmall),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: widget.onClose,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _replaceController,
                  decoration: InputDecoration(
                    hintText: "Replace with",
                    prefixIcon: const Icon(Icons.find_replace_rounded, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _matchCount > 0 ? _replaceFirst : null,
                child: const Text("Replace"),
              ),
              TextButton(
                onPressed: _matchCount > 0 ? _replaceAll : null,
                child: const Text("All"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

