import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/app_theme_controller.dart';

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
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                onConfirm();
              },
              child: Text(
                "OK",
                style: TextStyle(color: themeCtrl.accentColor, fontWeight: FontWeight.bold),
              ),
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

    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_ios, color: themeCtrl.accentColor, size: 16),
              Text("Appearance", style: TextStyle(color: themeCtrl.accentColor, fontSize: 16)),
            ],
          ),
        ),
        leadingWidth: 120,
        title: const Text("Style", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: themeCtrl,
        builder: (context, _) {
          final isGlass = themeCtrl.uiStyle == 'glass';
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                "STYLE",
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
                      onTap: () {
                        if (!isGlass) {
                          _showUnsupportedDeviceDialog(context, () {
                            themeCtrl.setUiStyle('glass');
                          });
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
          );
        },
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
    Widget cardContent = Container(
      height: 160,
      decoration: BoxDecoration(
        color: isGlassMode
            ? (isDark
                ? const Color(0xB32C2C2E)
                : const Color(0xB3FFFFFF))
            : (isDark
                ? const Color(0xFF2C2C2E)
                : const Color(0xFFF2F2F7)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? accentColor : (isDark ? Colors.white12 : const Color(0xFFE9E9E9)),
          width: isSelected ? 2.5 : 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected ? accentColor : Colors.grey,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 28,
            decoration: BoxDecoration(
              color: isDark ? Colors.white12 : Colors.black12,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 28,
            decoration: BoxDecoration(
              color: isDark ? Colors.white12 : Colors.black12,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );

    if (isGlassMode) {
      cardContent = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: cardContent,
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          cardContent,
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
