import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String label;
  final String? filePath;
  final VoidCallback? onDelete;

  const AudioPlayerWidget({
    super.key,
    required this.label,
    this.filePath,
    this.onDelete,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late final AudioPlayer _player;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = const Duration(seconds: 1);
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initAudio();
  }

  Future<void> _initAudio() async {
    if (widget.filePath != null && File(widget.filePath!).existsSync()) {
      try {
        final d = await _player.setFilePath(widget.filePath!);
        if (d != null) {
          setState(() {
            _duration = d;
            _isReady = true;
          });
        }
      } catch (_) {}
    }

    _player.positionStream.listen((pos) {
      if (mounted) {
        setState(() => _position = pos);
      }
    });

    _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing && state.processingState != ProcessingState.completed;
          if (state.processingState == ProcessingState.completed) {
            _position = Duration.zero;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _togglePlay() {
    HapticFeedback.lightImpact();
    if (_isPlaying) {
      _player.pause();
    } else {
      if (_position >= _duration) {
        _player.seek(Duration.zero);
      }
      _player.play();
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalSec = _duration.inSeconds > 0 ? _duration.inSeconds : 1;
    final currentSec = _position.inSeconds.clamp(0, totalSec);
    final progress = currentSec / totalSec;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(AppDimensions.paddingSmall),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232326) : const Color(0xFFF0F0F5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded),
            iconSize: 38,
            color: AppColors.accentGold,
            onPressed: _isReady ? _togglePlay : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.label,
                        style: AppTypography.headingSmall.copyWith(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      "${_formatDuration(_position)} / ${_formatDuration(_duration)}",
                      style: AppTypography.captionSmall,
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    activeTrackColor: AppColors.accentGold,
                    inactiveTrackColor: isDark ? Colors.white24 : Colors.black12,
                    thumbColor: AppColors.accentGold,
                  ),
                  child: Slider(
                    value: progress.clamp(0.0, 1.0),
                    onChanged: (val) {
                      final seekTo = Duration(seconds: (val * totalSec).toInt());
                      _player.seek(seekTo);
                    },
                  ),
                ),
              ],
            ),
          ),
          if (widget.onDelete != null)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              color: Colors.grey,
              onPressed: widget.onDelete,
            ),
        ],
      ),
    );
  }
}
