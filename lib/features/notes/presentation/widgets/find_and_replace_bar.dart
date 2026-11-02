import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
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
  List<Match> _matches = [];
  int _currentMatchIndex = 0; // 0 means no match, 1-based index when matched

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
        _matches = [];
        _currentMatchIndex = 0;
      });
      return;
    }
    final text = widget.contentController.text;
    final all = RegExp(RegExp.escape(query), caseSensitive: false).allMatches(text).toList();
    setState(() {
      _matches = all;
      _currentMatchIndex = all.isNotEmpty ? 1 : 0;
    });
    if (all.isNotEmpty) {
      _highlightMatch(0);
    }
  }

  void _highlightMatch(int matchIdx) {
    if (matchIdx < 0 || matchIdx >= _matches.length) return;
    final m = _matches[matchIdx];
    widget.contentController.selection = TextSelection(
      baseOffset: m.start,
      extentOffset: m.end,
    );
  }

  void _nextMatch() {
    if (_matches.isEmpty) return;
    int nextIdx = _currentMatchIndex; // 1-based to 0-based is current - 1 + 1 = current
    if (nextIdx >= _matches.length) nextIdx = 0;
    setState(() {
      _currentMatchIndex = nextIdx + 1;
    });
    _highlightMatch(nextIdx);
  }

  void _prevMatch() {
    if (_matches.isEmpty) return;
    int prevIdx = _currentMatchIndex - 2;
    if (prevIdx < 0) prevIdx = _matches.length - 1;
    setState(() {
      _currentMatchIndex = prevIdx + 1;
    });
    _highlightMatch(prevIdx);
  }

  void _replaceCurrent() {
    if (_matches.isEmpty || _currentMatchIndex < 1) return;
    final replace = _replaceController.text;
    final text = widget.contentController.text;
    final match = _matches[_currentMatchIndex - 1];
    final newText = text.replaceRange(match.start, match.end, replace);
    widget.contentController.text = newText;
    _onSearchChanged();
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
              Text(
                "$_currentMatchIndex/${_matches.length}",
                style: AppTypography.captionSmall.copyWith(
                  color: _matches.isNotEmpty ? AppColors.accentGold : null,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up_rounded),
                tooltip: "Previous match",
                onPressed: _matches.length > 1 ? _prevMatch : null,
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                tooltip: "Next match",
                onPressed: _matches.length > 1 ? _nextMatch : null,
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: "Close",
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
              FilledButton.tonal(
                onPressed: _matches.isNotEmpty ? _replaceCurrent : null,
                child: const Text("Replace"),
              ),
              const SizedBox(width: 6),
              FilledButton.tonal(
                onPressed: _matches.isNotEmpty ? _replaceAll : null,
                child: const Text("All"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
