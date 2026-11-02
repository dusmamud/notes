import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/app_theme_controller.dart';

/// Ground-truth hardware capability check for Glass style.
/// Native hardware blur (RenderEffect) was introduced in Android 10 (API level 29).
/// On non-Android platforms (iOS, macOS, Windows, Linux), hardware blur is natively supported.
/// On Android devices with API < 29 or when hardware blur is not supported, the "Unsupported Device"
/// dialog is displayed to allow the user to Cancel (retain Classic) or proceed with OK (force Glass).
class GlassCapabilityChecker {
  static const MethodChannel channel = MethodChannel('inotes/device');
  static bool? _mockSupported;

  @visibleForTesting
  static void setMockSupported(bool? supported) {
    _mockSupported = supported;
  }

  static Future<bool> isSupported() async {
    if (_mockSupported != null) return _mockSupported!;
    if (!Platform.isAndroid) return true;
    try {
      final int? sdkInt = await channel.invokeMethod<int>('getAndroidSdkInt');
      return (sdkInt ?? 0) >= 29;
    } catch (_) {
      return false; // Fail-closed on error
    }
  }
}

class StyleScreen extends StatelessWidget {
  const StyleScreen({super.key});

  void _showUnsupportedDeviceDialog(BuildContext context, VoidCallback onConfirm) {
    final themeCtrl = AppThemeController.instance;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text(
            "Unsupported Device",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Switch to Glass anyway?",
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "Cancel",
                style: TextStyle(color: themeCtrl.accentColor, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: themeCtrl.accentColor,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                onConfirm();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeCtrl = AppThemeController.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isGlass = themeCtrl.uiStyle == 'glass';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Style",
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: themeCtrl.accentColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "UI STYLE VARIANT",
              style: AppTypography.captionSmall.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Classic Preview Card
                Expanded(
                  child: _StyleCard(
                    title: "Classic",
                    description: "Solid Apple Notes style with clean borders",
                    isSelected: !isGlass,
                    accentColor: themeCtrl.accentColor,
                    isDark: isDark,
                    isGlassMode: false,
                    onTap: () => themeCtrl.setUiStyle('classic'),
                  ),
                ),
                const SizedBox(width: 16),
                // Glass Preview Card
                Expanded(
                  child: _StyleCard(
                    title: "Glass",
                    description: "Frosted blur and translucent floating surfaces",
                    isSelected: isGlass,
                    accentColor: themeCtrl.accentColor,
                    isDark: isDark,
                    isGlassMode: true,
                    onTap: () async {
                      if (!isGlass) {
                        final supported = await GlassCapabilityChecker.isSupported();
                        if (supported) {
                          themeCtrl.setUiStyle('glass');
                        } else {
                          if (context.mounted) {
                            _showUnsupportedDeviceDialog(context, () {
                              themeCtrl.setUiStyle('glass');
                            });
                          }
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 0,
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: themeCtrl.accentColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Glass style uses real-time backdrop blur and liquid shaders. On devices with limited GPU memory, Classic style provides smoother 120 FPS scrolling and extends battery life.",
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StyleCard extends StatelessWidget {
  final String title;
  final String description;
  final bool isSelected;
  final Color accentColor;
  final bool isDark;
  final bool isGlassMode;
  final VoidCallback onTap;

  const _StyleCard({
    required this.title,
    required this.description,
    required this.isSelected,
    required this.accentColor,
    required this.isDark,
    required this.isGlassMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : (isDark ? Colors.white12 : Colors.black12),
            width: isSelected ? 2.5 : 1.0,
          ),
          color: isGlassMode
              ? (isDark ? const Color(0xFF2C2C2E).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.7))
              : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7)),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: accentColor.withValues(alpha: 0.25),
                blurRadius: 12,
                spreadRadius: 2,
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: isGlassMode ? 16 : 0,
              sigmaY: isGlassMode ? 16 : 0,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        isGlassMode ? Icons.blur_on_rounded : Icons.crop_square_rounded,
                        color: isSelected ? accentColor : Colors.grey,
                        size: 28,
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: accentColor, size: 22),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
