import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/security/security_service.dart';
import '../../../../core/security/passcode_screen.dart';
import '../../../premium/presentation/screens/premium_sheet.dart';
import '../../../notes/domain/repositories/note_repository.dart';

class SettingsScreen extends StatefulWidget {
  final NoteRepository? repository;

  const SettingsScreen({super.key, this.repository});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SecurityService _securityService = SecurityService();
  String _mathMode = 'suggest';
  String _themeMode = 'system';
  String _uiStyle = 'glass';
  String _newNotesStartWith = 'title';
  String _currentLanguage = 'en-US';
  bool _hasPasscode = false;
  bool _secureRecents = false;
  bool _isLoading = true;

  static const Map<String, String> _languages = {
    'en-US': 'English (United States)',
    'de-DE': 'Deutsch (German)',
    'es-ES': 'Español (Spanish)',
    'fr-FR': 'Français (French)',
    'it-IT': 'Italiano (Italian)',
    'ja-JP': '日本語 (Japanese)',
    'ko-KR': '한국어 (Korean)',
    'pt-BR': 'Português (Brazil)',
    'ru-RU': 'Русский (Russian)',
    'zh-CN': '简体中文 (Chinese)',
    'ar': 'العربية (Arabic)',
    'id-ID': 'Bahasa Indonesia',
    'ms-MY': 'Bahasa Melayu',
    'th-TH': 'ไทย (Thai)',
    'tr-TR': 'Türkçe (Turkish)',
    'vi-VN': 'Tiếng Việt (Vietnamese)',
    'uk-UA': 'Українська (Ukrainian)',
    'fi-FI': 'Suomi (Finnish)',
    'fil-PH': 'Filipino',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final hasPass = await _securityService.hasPasscode();
    setState(() {
      _mathMode = prefs.getString('math_results_mode') ?? 'suggest';
      _themeMode = prefs.getString('app_theme_mode') ?? 'system';
      _uiStyle = prefs.getString('ui_style') ?? 'glass';
      _newNotesStartWith = prefs.getString('new_notes_start_with') ?? 'title';
      _currentLanguage = prefs.getString('app_language') ?? 'en-US';
      _secureRecents = prefs.getBool('secure_recents_policy') ?? false;
      _hasPasscode = hasPass;
      _isLoading = false;
    });
  }

  Future<void> _updateSetting(String key, String val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, val);
    setState(() {});
  }

  Future<void> _toggleSecureRecents(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('secure_recents_policy', val);
    await _securityService.setRecentsScreenshotPolicy(val);
    setState(() => _secureRecents = val);
  }

  void _showStorageManager() async {
    final notes = widget.repository != null ? await widget.repository!.getAllNotes() : [];
    int totalNotes = notes.length;
    int totalWords = 0;
    int totalBytes = 0;

    for (var n in notes) {
      final str = "${n.title}\n${n.contentMarkdown}";
      totalWords += str.trim().isEmpty ? 0 : str.trim().split(RegExp(r'\s+')).length;
      totalBytes += utf8.encode(str).length;
    }

    final kb = (totalBytes / 1024).toStringAsFixed(1);

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                Row(
                  children: [
                    const Icon(Icons.storage_rounded, color: AppColors.accentGold),
                    const SizedBox(width: 8),
                    Text("Storage Breakdown", style: AppTypography.headingMedium),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.note_alt_outlined),
                  title: const Text("Notes & Texts"),
                  subtitle: Text("$totalNotes notes · $totalWords words"),
                  trailing: Text("$kb KB", style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                const ListTile(
                  leading: Icon(Icons.image_outlined),
                  title: Text("Photos & Scans"),
                  subtitle: Text("Embedded images"),
                  trailing: Text("0.0 KB", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const ListTile(
                  leading: Icon(Icons.mic_none_outlined),
                  title: Text("Audio Recordings"),
                  subtitle: Text("Voice memos & waveforms"),
                  trailing: Text("0.0 KB", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const Divider(),
                ListTile(
                  title: const Text("Total Storage Used", style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Text("$kb KB", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentGold)),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.accentGold),
                  child: const Text("Close", style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _exportAllNotes() async {
    if (widget.repository == null) return;
    final notes = await widget.repository!.getAllNotes();
    if (notes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No notes to export")),
        );
      }
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln("# Notes Backup Archive");
    buffer.writeln("Export Date: ${DateTime.now().toIso8601String()}\n");
    for (var n in notes) {
      buffer.writeln("## ${n.title.isEmpty ? 'Untitled' : n.title}");
      buffer.writeln("Created: ${n.createdAt}");
      buffer.writeln(n.contentMarkdown);
      buffer.writeln("\n---\n");
    }

    await Share.share(buffer.toString(), subject: "Notes_Backup_${DateTime.now().millisecondsSinceEpoch}.md");
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.75,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.language_rounded, color: AppColors.accentGold),
                    const SizedBox(width: 8),
                    Text("Select App Language", style: AppTypography.headingMedium),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  itemCount: _languages.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final key = _languages.keys.elementAt(index);
                    final name = _languages[key]!;
                    final isSelected = _currentLanguage == key;
                    return ListTile(
                      title: Text(name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      trailing: isSelected ? const Icon(Icons.check_rounded, color: AppColors.accentGold) : null,
                      onTap: () async {
                        await _updateSetting('app_language', key);
                        if (!mounted) return;
                        setState(() => _currentLanguage = key);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentGold))
          : ListView(
              children: [
                // Premium Banner
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2C2518), Color(0xFF1E1E1E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, color: AppColors.accentGold, size: 36),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Notes Premium",
                              style: AppTypography.headingMedium.copyWith(color: AppColors.accentGold),
                            ),
                            const Text(
                              "Unlock unlimited audio transcription, document scans and sync",
                              style: TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accentGold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onPressed: () => PremiumSheet.show(context),
                        child: const Text("Upgrade", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

                _buildSectionHeader("PERSONALIZATION & THEMES"),
                ListTile(
                  leading: const Icon(Icons.brightness_medium_rounded),
                  title: const Text("Theme Mode"),
                  subtitle: Text(_themeMode.toUpperCase()),
                  trailing: DropdownButton<String>(
                    value: _themeMode,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'light', child: Text("Light")),
                      DropdownMenuItem(value: 'dark', child: Text("Dark")),
                      DropdownMenuItem(value: 'system', child: Text("System")),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        _updateSetting('app_theme_mode', val);
                        setState(() => _themeMode = val);
                      }
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.auto_awesome_rounded),
                  title: const Text("UI Style"),
                  subtitle: Text(_uiStyle == 'glass' ? "Glass Style (Frosted Blurs)" : "Classic Style (Solid Cards)"),
                  trailing: DropdownButton<String>(
                    value: _uiStyle,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'glass', child: Text("Glass")),
                      DropdownMenuItem(value: 'classic', child: Text("Classic")),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        _updateSetting('ui_style', val);
                        setState(() => _uiStyle = val);
                      }
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.language_rounded),
                  title: const Text("App Language"),
                  subtitle: Text(_languages[_currentLanguage] ?? _currentLanguage),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _showLanguageSelector,
                ),

                const Divider(),
                _buildSectionHeader("WRITING & SMART FEATURES"),
                ListTile(
                  leading: const Icon(Icons.calculate_outlined),
                  title: const Text("Math Calculation Results"),
                  subtitle: Text(_getMathSubtitle(_mathMode)),
                  trailing: DropdownButton<String>(
                    value: _mathMode,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'suggest', child: Text("Suggest")),
                      DropdownMenuItem(value: 'insert', child: Text("Insert")),
                      DropdownMenuItem(value: 'off', child: Text("Off")),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        _updateSetting('math_results_mode', val);
                        setState(() => _mathMode = val);
                      }
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.title_rounded),
                  title: const Text("New Notes Start With"),
                  subtitle: Text(_newNotesStartWith.toUpperCase()),
                  trailing: DropdownButton<String>(
                    value: _newNotesStartWith,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'title', child: Text("Title")),
                      DropdownMenuItem(value: 'heading', child: Text("Heading")),
                      DropdownMenuItem(value: 'subheading', child: Text("Subheading")),
                      DropdownMenuItem(value: 'body', child: Text("Body")),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        _updateSetting('new_notes_start_with', val);
                        setState(() => _newNotesStartWith = val);
                      }
                    },
                  ),
                ),

                const Divider(),
                _buildSectionHeader("SECURITY & PRIVACY"),
                ListTile(
                  leading: const Icon(Icons.lock_outline_rounded),
                  title: const Text("App Passcode"),
                  subtitle: Text(_hasPasscode ? "Passcode Enabled" : "Passcode Disabled"),
                  trailing: Switch(
                    value: _hasPasscode,
                    activeThumbColor: AppColors.accentGold,
                    onChanged: (enable) async {
                      if (enable) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PasscodeScreen(
                              mode: PasscodeMode.setup,
                              onSuccess: () {
                                Navigator.of(context).pop();
                                _loadSettings();
                              },
                            ),
                          ),
                        );
                      } else {
                        await _securityService.removePasscode();
                        _loadSettings();
                      }
                    },
                  ),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.visibility_off_outlined),
                  title: const Text("Hide in Recent Apps"),
                  subtitle: const Text("Protects note previews from task switcher"),
                  value: _secureRecents,
                  activeThumbColor: AppColors.accentGold,
                  onChanged: _toggleSecureRecents,
                ),

                const Divider(),
                _buildSectionHeader("STORAGE & BACKUP"),
                ListTile(
                  leading: const Icon(Icons.pie_chart_outline_rounded, color: AppColors.accentGold),
                  title: const Text("Storage Breakdown"),
                  subtitle: const Text("View space used by notes and media"),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _showStorageManager,
                ),
                ListTile(
                  leading: const Icon(Icons.file_upload_outlined, color: AppColors.tagBlue),
                  title: const Text("Export All Notes"),
                  subtitle: const Text("Save Markdown backup archive"),
                  onTap: _exportAllNotes,
                ),

                const Divider(),
                _buildSectionHeader("ABOUT"),
                const ListTile(
                  leading: Icon(Icons.info_outline_rounded),
                  title: Text("Version"),
                  trailing: Text("1.0.0 (Build 1)"),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: AppTypography.captionSmall.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.1),
      ),
    );
  }

  String _getMathSubtitle(String mode) {
    switch (mode) {
      case 'insert':
        return "Automatically inserts result after '='";
      case 'off':
        return "Calculations disabled";
      default:
        return "Shows suggested ghost result badge";
    }
  }
}