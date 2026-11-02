import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
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
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isPaused = false;
  String? _recordingPath;
  int _secondsElapsed = 0;
  Timer? _timer;
  Timer? _ampTimer;
  final List<double> _waveformData = List.filled(15, 0.1);
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startActualRecording();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ampTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startActualRecording() async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          setState(() {
            _errorMessage = "Microphone permission required for audio recording.";
          });
        }
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/audio_memo_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _recordingPath = path;

      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
        path: path,
      );

      if (mounted) {
        setState(() {
          _isRecording = true;
          _isPaused = false;
        });
        _startTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Could not start audio recorder: $e";
        });
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isRecording && !_isPaused) {
        setState(() => _secondsElapsed++);
      }
    });

    _ampTimer?.cancel();
    _ampTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) async {
      if (_isRecording && !_isPaused) {
        try {
          final amp = await _audioRecorder.getAmplitude();
          final currentDb = amp.current; // typically -60 to 0 dB
          final normalized = ((currentDb + 50) / 50).clamp(0.1, 1.0);
          if (mounted) {
            setState(() {
              _waveformData.removeAt(0);
              _waveformData.add(normalized);
            });
          }
        } catch (_) {}
      }
    });
  }

  Future<void> _togglePause() async {
    HapticFeedback.selectionClick();
    if (_isPaused) {
      await _audioRecorder.resume();
      setState(() => _isPaused = false);
    } else {
      await _audioRecorder.pause();
      setState(() => _isPaused = true);
    }
  }

  Future<void> _saveRecording() async {
    HapticFeedback.lightImpact();
    _timer?.cancel();
    _ampTimer?.cancel();
    final path = await _audioRecorder.stop();
    final finalPath = path ?? _recordingPath;
    if (finalPath != null && mounted) {
      final durationStr = _formatDuration(_secondsElapsed);
      widget.onRecordingComplete("\n[🎙️ Voice Memo ($durationStr)]($finalPath)\n");
      Navigator.of(context).pop();
    }
  }

  Future<void> _cancelRecording() async {
    HapticFeedback.lightImpact();
    _timer?.cancel();
    _ampTimer?.cancel();
    try {
      await _audioRecorder.cancel();
      if (_recordingPath != null) {
        final f = File(_recordingPath!);
        if (await f.exists()) await f.delete();
      }
    } catch (_) {}
    if (mounted) {
      Navigator.of(context).pop();
    }
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
          children: [
            // Handle Bar
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Text(
              "Voice Memo",
              style: AppTypography.headingSmall,
            ),
            const SizedBox(height: 8),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _errorMessage!,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.tagCoral),
                  textAlign: TextAlign.center,
                ),
              )
            else
              Text(
                _formatDuration(_secondsElapsed),
                style: AppTypography.headingLarge.copyWith(
                  fontSize: 36,
                  color: AppColors.accentGold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            const SizedBox(height: 24),

            // Live Waveform Visualizer
            SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: _waveformData.map((amp) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 4,
                    height: 60 * amp,
                    decoration: BoxDecoration(
                      color: _isPaused ? Colors.grey : AppColors.accentGold,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 32),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 28),
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
                      color: AppColors.accentGold,
                    ),
                    child: Icon(
                      _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      size: 36,
                      color: Colors.black,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.check_circle_rounded, size: 32),
                  color: AppColors.tagForest,
                  tooltip: "Save",
                  onPressed: _secondsElapsed > 0 ? _saveRecording : null,
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
