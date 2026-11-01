import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';

class AudioRecordingModal extends StatefulWidget {
  final ValueChanged<String> onRecordingComplete;

  const AudioRecordingModal({
    super.key,
    required this.onRecordingComplete,
  });

  static Future<void> show(BuildContext context, ValueChanged<String> onComplete) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AudioRecordingModal(onRecordingComplete: onComplete),
    );
  }

  @override
  State<AudioRecordingModal> createState() => _AudioRecordingModalState();
}

class _AudioRecordingModalState extends State<AudioRecordingModal> {
  bool _isRecording = true;
  int _secondsElapsed = 0;
  Timer? _timer;
  final List<double> _waveformData = [0.2, 0.4, 0.7, 0.9, 0.5, 0.3, 0.6, 0.8, 0.4, 0.2];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isRecording) {
        setState(() {
          _secondsElapsed++;
          // Shift and simulate active microphone levels
          _waveformData.removeAt(0);
          _waveformData.add(0.2 + (0.7 * ((_secondsElapsed % 5) / 5.0)));
        });
      }
    });
  }

  void _togglePause() {
    HapticFeedback.selectionClick();
    setState(() => _isRecording = !_isRecording);
  }

  void _saveRecording() {
    HapticFeedback.lightImpact();
    final durationStr = _formatDuration(_secondsElapsed);
    widget.onRecordingComplete("🎙️ Audio Memo ($durationStr)");
    Navigator.of(context).pop();
  }

  void _cancelRecording() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
  }

  String _formatDuration(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return "$m:$s";
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
        horizontal: AppDimensions.paddingLarge,
        vertical: AppDimensions.paddingMedium,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            SizedBox(height: AppDimensions.paddingMedium),
            Text(
              _isRecording ? "Recording Audio Memo" : "Recording Paused",
              style: AppTypography.headingSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _formatDuration(_secondsElapsed),
              style: AppTypography.headingLarge.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.tagCoral,
              ),
            ),
            const SizedBox(height: 24),
            // Live Waveform Visualizer
            SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _waveformData.map((heightFactor) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 6,
                    height: 50 * heightFactor,
                    decoration: BoxDecoration(
                      color: _isRecording ? AppColors.tagCoral : Colors.grey,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  iconSize: 32,
                  color: Colors.grey,
                  tooltip: "Discard",
                  onPressed: _cancelRecording,
                ),
                GestureDetector(
                  onTap: _togglePause,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.tagCoral.withValues(alpha: 0.15),
                      border: Border.all(color: AppColors.tagCoral, width: 2),
                    ),
                    child: Icon(
                      _isRecording ? Icons.pause_rounded : Icons.mic_rounded,
                      color: AppColors.tagCoral,
                      size: 32,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.check_circle_rounded),
                  iconSize: 36,
                  color: AppColors.accentTeal,
                  tooltip: "Save to Note",
                  onPressed: _saveRecording,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

