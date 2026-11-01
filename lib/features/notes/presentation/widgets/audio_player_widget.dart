import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String label;
  final Duration totalDuration;
  final VoidCallback? onDelete;

  const AudioPlayerWidget({
    super.key,
    required this.label,
    this.totalDuration = const Duration(seconds: 45),
    this.onDelete,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  bool _isPlaying = false;
  double _progress = 0.0;

  void _togglePlay() {
    HapticFeedback.lightImpact();
    setState(() => _isPlaying = !_isPlaying);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            onPressed: _togglePlay,
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
                    Text(
                      widget.label,
                      style: AppTypography.headingSmall.copyWith(fontSize: 14),
                    ),
                    Text(
                      "${(_progress * widget.totalDuration.inSeconds).toInt()}s / ${widget.totalDuration.inSeconds}s",
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
                    value: _progress,
                    onChanged: (val) {
                      setState(() => _progress = val);
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

