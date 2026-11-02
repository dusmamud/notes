import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/app_theme_controller.dart';
import '../../../../core/security/security_service.dart';
import '../../../../core/security/passcode_screen.dart';
import '../../../backup/data/repositories/backup_repository.dart';
import '../../../premium/presentation/screens/premium_sheet.dart';
import '../../../notes/domain/repositories/note_repository.dart';
import '../../../onboarding/presentation/whats_new_sheet.dart';
import 'appearance_screen.dart';

class SettingsScreen extends StatefulWidget {
  final NoteRepository? repository;

  const SettingsScreen({super.key, this.repository});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SecurityService _securityService = SecurityService();
  bool _hasPasscode = false;
  bool _secureRecents = false;
  String _currentLanguage = 'en-US';
  String _appVersion = "1.0.0";
  String _buildNumber = "1";
  bool _isLoading = true;
  String? _lastBackupTime;
  bool _dailyBackupEnabled = false;

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
    try {
      final info = await PackageInfo.fromPlatform();
      _appVersion = info.version;
      _buildNumber = info.buildNumber;
    } catch (_) {}

    final lastBackup = prefs.getString('last_backup_timestamp');
    final dailyBackup = prefs.getBool('daily_backup_enabled') ?? false;

    if (mounted) {
      setState(() {
        _currentLanguage = prefs.getString('app_language') ?? 'en-US';
        _secureRecents = prefs.getBool('secure_recents_policy') ?? false;
        _hasPasscode = hasPass;
        _lastBackupTime = lastBackup;
        _dailyBackupEnabled = dailyBackup;
        _isLoading = false;
      });
    }
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
    int totalNotesBytes = 0;

    for (var n in notes) {
      final str = "${n.title}\n${n.contentMarkdown}";
      totalWords += str.trim().isEmpty ? 0 : str.trim().split(RegExp(r'\s+')).length;
      totalNotesBytes += utf8.encode(str).length;
    }

    int photoScanBytes = 0;
    int audioBytes = 0;
    try {
      final docDir = await getApplicationDocumentsDirectory();
      if (docDir.existsSync()) {
        final entities = docDir.listSync(recursive: true);
        for (var entity in entities) {
          if (entity is File) {
            final p = entity.path.toLowerCase();
            final len = entity.lengthSync();
            if (p.endsWith('.jpg') || p.endsWith('.png') || p.endsWith('.jpeg') || p.endsWith('.pdf')) {
              photoScanBytes += len;
            } else if (p.endsWith('.m4a') || p.endsWith('.aac') || p.endsWith('.mp3') || p.endsWith('.wav')) {
              audioBytes += len;
            }
          }
        }
      }
    } catch (_) {}

    final totalUsedBytes = totalNotesBytes + photoScanBytes + audioBytes;
    final totalKb = (totalUsedBytes / 1024).toStringAsFixed(1);
    final notesKb = (totalNotesBytes / 1024).toStringAsFixed(1);
    final photoKb = (photoScanBytes / 1024).toStringAsFixed(1);
    final audioKb = (audioBytes / 1024).toStringAsFixed(1);

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
                    Icon(Icons.storage_rounded, color: AppThemeController.instance.accentColor),
                    const SizedBox(width: 8),
                    Text("Storage Breakdown", style: AppTypography.headingMedium),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.note_alt_outlined),
                  title: const Text("Notes & Texts"),
                  subtitle: Text("$totalNotes notes · $totalWords words"),
                  trailing: Text("$notesKb KB", style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                if (photoScanBytes > 0)
                  ListTile(
                    leading: const Icon(Icons.image_outlined),
                    title: const Text("Photos & Scans"),
                    subtitle: const Text("Embedded images & documents"),
                    trailing: Text("$photoKb KB", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                if (audioBytes > 0)
                  ListTile(
                    leading: const Icon(Icons.mic_none_outlined),
                    title: const Text("Audio Recordings"),
                    subtitle: const Text("Voice memos & waveforms"),
                    trailing: Text("$audioKb KB", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                const Divider(),
                ListTile(
                  title: const Text("Total Storage Used", style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Text("$totalKb KB", style: TextStyle(fontWeight: FontWeight.bold, color: AppThemeController.instance.accentColor)),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(backgroundColor: AppThemeController.instance.accentColor),
                  child: const Text("Close", style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCloudSyncInfo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cloud_off_rounded, color: Colors.grey),
            SizedBox(width: 8),
            Text("Cloud Sync"),
          ],
        ),
        content: const Text(
          "Cloud Sync is currently not connected. Notes are securely stored locally on this device.\n\n"
          "Multi-device cloud synchronization requires configuring a remote sync provider or cloud storage backend.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showBackupManagerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
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
                        Icon(Icons.archive_outlined, color: AppThemeController.instance.accentColor),
                        const SizedBox(width: 8),
                        Text("Local Backup & Restore", style: AppTypography.headingMedium),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _lastBackupTime != null
                          ? "Last backup: $_lastBackupTime"
                          : "No local backups recorded yet",
                      style: AppTypography.captionMedium.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.archive_rounded),
                      title: const Text("Create Local ZIP Backup"),
                      subtitle: const Text("Save standalone ZIP archive in app documents"),
                      onTap: () async {
                        Navigator.pop(sheetCtx);
                        if (widget.repository == null) return;
                        try {
                          final backupRepo = BackupRepository(repository: widget.repository!);
                          final file = await backupRepo.createPersistentBackup();
                          final now = DateTime.now();
                          final formatted = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('last_backup_timestamp', formatted);
                          if (mounted) {
                            setState(() => _lastBackupTime = formatted);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Backup created: ${file.path.split('/').last}")),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Failed to create backup: $e")),
                            );
                          }
                        }
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.unarchive_rounded),
                      title: const Text("Restore from ZIP Backup"),
                      subtitle: const Text("Select and restore notes from a backup ZIP"),
                      onTap: () async {
                        Navigator.pop(sheetCtx);
                        if (widget.repository == null) return;
                        try {
                          final picked = await FilePicker.pickFile(
                            type: FileType.custom,
                            allowedExtensions: ['zip'],
                          );
                          if (picked != null && picked.path != null) {
                            final backupRepo = BackupRepository(repository: widget.repository!);
                            final ok = await backupRepo.restoreFromZip(File(picked.path!));
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(ok ? "Backup restored successfully" : "Failed to restore backup: Invalid ZIP"),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error restoring backup: $e")),
                            );
                          }
                        }
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.schedule_rounded),
                      title: const Text("Daily Auto-Backup Schedule"),
                      subtitle: const Text("Run daily background backup using Workmanager"),
                      value: _dailyBackupEnabled,
                      activeThumbColor: AppThemeController.instance.accentColor,
                      onChanged: (val) async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('daily_backup_enabled', val);
                        if (widget.repository != null) {
                          await BackupRepository(repository: widget.repository!).scheduleDailyBackup(val);
                        }
                        setSheetState(() => _dailyBackupEnabled = val);
                        if (mounted) {
                          setState(() => _dailyBackupEnabled = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
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
              Text("Select Language", style: AppTypography.headingMedium),
              const SizedBox(height: 16),
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
                      trailing: isSelected ? Icon(Icons.check_rounded, color: AppThemeController.instance.accentColor) : null,
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('app_language', key);
                        if (!mounted) return;
                        try {
                          final parts = key.split('-');
                          final locale = parts.length == 2 ? Locale(parts[0], parts[1]) : Locale(parts[0]);
                          await context.setLocale(locale);
                        } catch (_) {}
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

  void _showMathExamples() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
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
              Text("Math Notes Examples", style: AppTypography.headingMedium),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: const [
                    ListTile(title: Text("125 * 4 ="), trailing: Text("500", style: TextStyle(fontWeight: FontWeight.bold))),
                    ListTile(title: Text("1500 - 20% ="), trailing: Text("1200", style: TextStyle(fontWeight: FontWeight.bold))),
                    ListTile(title: Text("sqrt(144) ="), trailing: Text("12", style: TextStyle(fontWeight: FontWeight.bold))),
                    ListTile(title: Text("price = 45\nprice * 3 ="), trailing: Text("135", style: TextStyle(fontWeight: FontWeight.bold))),
                    ListTile(title: Text("Total ="), trailing: Text("Sums list above", style: TextStyle(color: Colors.grey))),
                  ],
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
    final themeCtrl = AppThemeController.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentGold))
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 100,
                  leading: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.only(left: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_ios, color: themeCtrl.accentColor, size: 16),
                        Text("Notes", style: TextStyle(color: themeCtrl.accentColor, fontSize: 16)),
                      ],
                    ),
                  ),
                  leadingWidth: 110,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 20, bottom: 12),
                    title: Text(
                      "Settings",
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                    // 1. Upgrade to Premium Card (Honest Preview)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B2500), Color(0xFFD4AF37)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () => PremiumSheet.show(context),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.star, color: Colors.amber, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    "Notes Premium (Preview)",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    "Store purchases disabled pending billing setup",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.white70),
                          ],
                        ),
                      ),
                    ),

                    // 2. Writing & Organizing Group
                    _buildSectionHeader("WRITING & ORGANIZING"),
                    _buildCard([
                      ListTile(
                        leading: const Icon(Icons.sort_rounded),
                        title: const Text("Sort Notes By"),
                        trailing: DropdownButton<String>(
                          value: themeCtrl.sortNotesBy,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: 'edited', child: Text("Date Edited")),
                            DropdownMenuItem(value: 'created', child: Text("Date Created")),
                            DropdownMenuItem(value: 'title', child: Text("Title")),
                          ],
                          onChanged: (val) {
                            if (val != null) themeCtrl.setSortNotesBy(val);
                          },
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.title_rounded),
                        title: const Text("Notes Start With"),
                        trailing: DropdownButton<String>(
                          value: themeCtrl.notesStartWith,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: 'title', child: Text("Title (H1)")),
                            DropdownMenuItem(value: 'heading', child: Text("Heading (H2)")),
                            DropdownMenuItem(value: 'body', child: Text("Body")),
                          ],
                          onChanged: (val) {
                            if (val != null) themeCtrl.setNotesStartWith(val);
                          },
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.checklist_rounded),
                        title: const Text("Sort Checked Items"),
                        subtitle: const Text("Automatically move checklist items to bottom"),
                        trailing: DropdownButton<String>(
                          value: themeCtrl.sortCheckedItems,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: 'manually', child: Text("Manually")),
                            DropdownMenuItem(value: 'automatically', child: Text("Automatically")),
                          ],
                          onChanged: (val) {
                            if (val != null) themeCtrl.setSortCheckedItems(val);
                          },
                        ),
                      ),
                    ]),

                    // 3. Sync & Storage Group (Honest Local-First State)
                    _buildSectionHeader("SYNC & STORAGE"),
                    _buildCard([
                      ListTile(
                        leading: const Icon(Icons.cloud_off_rounded, color: Colors.grey),
                        title: const Text("Cloud Sync (Not Connected)"),
                        subtitle: const Text("Notes stored locally on device · Cloud sync not configured"),
                        trailing: const Icon(Icons.info_outline_rounded, color: Colors.grey),
                        onTap: _showCloudSyncInfo,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.archive_outlined),
                        title: const Text("Local Backup & Restore"),
                        subtitle: Text(
                          _lastBackupTime != null
                              ? "Last backup: $_lastBackupTime"
                              : "Create or restore local ZIP archives",
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: _showBackupManagerSheet,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.pie_chart_outline_rounded),
                        title: const Text("Storage"),
                        subtitle: const Text("Manage and back up your notes"),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: _showStorageManager,
                      ),
                    ]),

                    // 4. Security & Vault Group
                    _buildSectionHeader("SECURITY & VAULT"),
                    _buildCard([
                      ListTile(
                        leading: const Icon(Icons.lock_outline_rounded),
                        title: const Text("App Lock"),
                        subtitle: Text(_hasPasscode ? "Passcode Enabled" : "Off"),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PasscodeScreen(
                                mode: PasscodeMode.setup,
                                onSuccess: _loadSettings,
                              ),
                            ),
                          );
                          _loadSettings();
                        },
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: const Icon(Icons.remove_red_eye_outlined),
                        title: const Text("Hide in Recents"),
                        subtitle: const Text("Blur notes in Android task switcher"),
                        value: _secureRecents,
                        activeThumbColor: themeCtrl.accentColor,
                        onChanged: _toggleSecureRecents,
                      ),
                    ]),

                    // 5. Appearance Group
                    _buildSectionHeader("APPEARANCE"),
                    _buildCard([
                      ListTile(
                        leading: Icon(Icons.palette_outlined, color: themeCtrl.accentColor),
                        title: const Text("Appearance", style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text("Customize the app's look and text size."),
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
                            MaterialPageRoute(builder: (_) => const AppearanceScreen()),
                          );
                        },
                      ),
                    ]),

                    // 6. Writing & Calculations
                    _buildSectionHeader("WRITING & CALCULATIONS"),
                    _buildCard([
                      SwitchListTile(
                        secondary: const Icon(Icons.save_outlined),
                        title: const Text("Auto Save"),
                        subtitle: const Text("Automatically save notes as you type"),
                        value: themeCtrl.autoSave,
                        activeThumbColor: themeCtrl.accentColor,
                        onChanged: (val) => themeCtrl.setAutoSave(val),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.calculate_outlined),
                        title: const Text("Math Results"),
                        trailing: DropdownButton<String>(
                          value: themeCtrl.mathResultsMode,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: 'suggest', child: Text("Suggest Result")),
                            DropdownMenuItem(value: 'insert', child: Text("Insert Result")),
                            DropdownMenuItem(value: 'off', child: Text("Off")),
                          ],
                          onChanged: (val) {
                            if (val != null) themeCtrl.setMathResultsMode(val);
                          },
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.functions_rounded),
                        title: const Text("Math Examples"),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: _showMathExamples,
                      ),
                    ]),

                    // 7. Support & Feedback (Honest Billing Gate)
                    _buildSectionHeader("SUPPORT & FEEDBACK"),
                    _buildCard([
                      ListTile(
                        leading: const Icon(Icons.star_outline_rounded),
                        title: const Text("Rate Us"),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () {},
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.share_outlined),
                        title: const Text("Share App"),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () {
                          SharePlus.instance.share(ShareParams(
                            text: "Check out Notes app on Android!",
                          ));
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.help_outline_rounded),
                        title: const Text("App Support"),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () {},
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.restore_rounded),
                        title: const Text("Restore Purchases"),
                        subtitle: const Text("Store billing not configured"),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Restore Purchases"),
                              content: const Text(
                                "Purchase restoration is currently disabled because Google Play Billing is not configured in this build.",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text("OK"),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ]),

                    // 8. General & About
                    _buildSectionHeader("GENERAL & ABOUT"),
                    _buildCard([
                      ListTile(
                        leading: const Icon(Icons.language_rounded),
                        title: const Text("Language"),
                        subtitle: Text(_languages[_currentLanguage] ?? _currentLanguage),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: _showLanguageSelector,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.new_releases_outlined),
                        title: const Text("What's New"),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () => WhatsNewSheet.show(context),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.info_outline_rounded),
                        title: const Text("About & Legal"),
                        subtitle: const Text("Notes (com.dusrel.note)"),
                        trailing: Text("$_appVersion ($_buildNumber)", style: const TextStyle(color: Colors.grey)),
                      ),
                    ]),

                    const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 16),
      child: Text(
        title,
        style: AppTypography.captionSmall.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
          color: isDark ? Colors.white54 : Colors.black54,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(children: children),
    );
  }
}
