import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/app_theme_controller.dart';
import 'style_screen.dart';
import 'font_size_screen.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  void _showAccentPicker(BuildContext context) {
    final themeCtrl = AppThemeController.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final accents = [
      {'name': 'Gold', 'color': AppColors.brandPrimary},
      {'name': 'Blue', 'color': AppColors.accentBlue},
      {'name': 'Teal', 'color': AppColors.accentTeal},
      {'name': 'Purple', 'color': AppColors.accentPurple},
      {'name': 'Coral', 'color': AppColors.accentRed},
      {'name': 'Orange', 'color': AppColors.accentOrange},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text("Select Accent Color", style: AppTypography.headingMedium),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: accents.map((acc) {
                    final col = acc['color'] as Color;
                    final isSelected = themeCtrl.accentColor.toARGB32() == col.toARGB32();
                    return GestureDetector(
                      onTap: () {
                        themeCtrl.setAccentColor(col);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: col,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: col.withValues(alpha: 0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 22)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
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
              Text("Settings", style: TextStyle(color: themeCtrl.accentColor, fontSize: 16)),
            ],
          ),
        ),
        leadingWidth: 100,
        title: const Text("Appearance", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: themeCtrl,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                "THEME",
                style: AppTypography.captionSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              const SizedBox(height: 12),
              // Phone Mock Cards (Light vs Dark)
              Row(
                children: [
                  Expanded(
                    child: _ThemePreviewCard(
                      title: "Light",
                      isDarkPreview: false,
                      isSelected: themeCtrl.themeMode == ThemeMode.light,
                      accentColor: themeCtrl.accentColor,
                      onTap: () => themeCtrl.setThemeMode(ThemeMode.light),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ThemePreviewCard(
                      title: "Dark",
                      isDarkPreview: true,
                      isSelected: themeCtrl.themeMode == ThemeMode.dark,
                      accentColor: themeCtrl.accentColor,
                      onTap: () => themeCtrl.setThemeMode(ThemeMode.dark),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text("Auto"),
                      subtitle: const Text("Follow system brightness"),
                      value: themeCtrl.themeMode == ThemeMode.system,
                      activeThumbColor: themeCtrl.accentColor,
                      onChanged: (val) {
                        if (val) {
                          themeCtrl.setThemeMode(ThemeMode.system);
                        } else {
                          themeCtrl.setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
                        }
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text("True Black (OLED)"),
                      subtitle: const Text("Pure black background in dark mode"),
                      value: themeCtrl.isOled,
                      activeThumbColor: themeCtrl.accentColor,
                      onChanged: (val) => themeCtrl.setOled(val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Text(
                "STYLING & TYPOGRAPHY",
                style: AppTypography.captionSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    ListTile(
                      title: const Text("Color"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: themeCtrl.accentColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                      onTap: () => _showAccentPicker(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text("Style"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            themeCtrl.uiStyle == 'glass' ? "Glass" : "Classic",
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const StyleScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text("Font & Size"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${themeCtrl.defaultFontSize.toInt()} sp",
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FontSizeScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text("Reduce Transparency"),
                      subtitle: const Text("Draw solid bars and menus instead of blur"),
                      value: themeCtrl.reduceTransparency,
                      activeThumbColor: themeCtrl.accentColor,
                      onChanged: (val) => themeCtrl.setReduceTransparency(val),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ThemePreviewCard extends StatelessWidget {
  final String title;
  final bool isDarkPreview;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _ThemePreviewCard({
    required this.title,
    required this.isDarkPreview,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: isDarkPreview ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? accentColor : (isDarkPreview ? Colors.white12 : Colors.black12),
                width: isSelected ? 2.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isDarkPreview ? Colors.white38 : Colors.black38,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isDarkPreview ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isDarkPreview ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected ? accentColor : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

