import 'package:flutter/material.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/app_theme_controller.dart';

class FontSizeScreen extends StatefulWidget {
  const FontSizeScreen({super.key});

  @override
  State<FontSizeScreen> createState() => _FontSizeScreenState();
}

class _FontSizeScreenState extends State<FontSizeScreen> {
  double _currentSize = 16.0;

  @override
  void initState() {
    super.initState();
    _currentSize = AppThemeController.instance.defaultFontSize;
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
        title: const Text("Font & Size", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Live Preview Card
              Expanded(
                child: Center(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? Colors.white12 : const Color(0xFFE9E9E9),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Your notes will look like this",
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: _currentSize * 1.3,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Drag the slider below until this paragraph is easy to read. Titles, headings and lists follow the same size.",
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: _currentSize,
                            height: 1.5,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Font Selector Card
              Card(
                elevation: 0,
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    ListTile(
                      title: const Text("Font"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text("Default (pretenda)", style: TextStyle(color: Colors.grey)),
                          SizedBox(width: 4),
                          Icon(Icons.unfold_more, color: Colors.grey),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Text("A", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                          Expanded(
                            child: Slider(
                              value: _currentSize,
                              min: 12,
                              max: 28,
                              divisions: 16,
                              activeColor: themeCtrl.accentColor,
                              label: "${_currentSize.toInt()} sp",
                              onChanged: (val) {
                                setState(() => _currentSize = val);
                                themeCtrl.setDefaultFontSize(val);
                              },
                            ),
                          ),
                          const Text("A", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() => _currentSize = 16.0);
                    themeCtrl.setDefaultFontSize(16.0);
                  },
                  child: Text(
                    "Reset to App Default (16 sp)",
                    style: TextStyle(color: themeCtrl.accentColor),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Choose the font and size for your notes. It does not affect the rest of the application.",
                style: AppTypography.captionMedium.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

