import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_theme_controller.dart';
import 'core/constants/app_colors.dart';
import 'core/security/security_service.dart';
import 'core/security/passcode_screen.dart';
import 'features/notes/data/repositories/note_repository_impl.dart';
import 'features/notes/presentation/screens/notes_feed_screen.dart';
import 'features/onboarding/presentation/welcome_tour_screen.dart';
import 'features/onboarding/presentation/whats_new_sheet.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Initialize theme controller before UI renders
  await AppThemeController.instance.load();

  // Initializing repository
  final repository = NoteRepositoryImpl();
  await repository.initialize();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('de', 'DE'),
        Locale('es', 'ES'),
        Locale('fr', 'FR'),
        Locale('it', 'IT'),
        Locale('ja', 'JP'),
        Locale('ko', 'KR'),
        Locale('pt', 'BR'),
        Locale('ru', 'RU'),
        Locale('zh', 'CN'),
        Locale('ar'),
        Locale('id', 'ID'),
        Locale('ms', 'MY'),
        Locale('th', 'TH'),
        Locale('tr', 'TR'),
        Locale('vi', 'VN'),
        Locale('uk', 'UA'),
        Locale('fi', 'FI'),
        Locale('fil', 'PH'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en', 'US'),
      child: NotesApp(repository: repository),
    ),
  );
}

class NotesApp extends StatefulWidget {
  final NoteRepositoryImpl repository;

  const NotesApp({super.key, required this.repository});

  @override
  State<NotesApp> createState() => _NotesAppState();
}

class _NotesAppState extends State<NotesApp> with WidgetsBindingObserver {
  final SecurityService _securityService = SecurityService();
  bool _isCheckingAuth = true;
  bool _requiresAuth = false;
  bool _isAuthenticated = false;
  bool _hasSeenOnboarding = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAppSecurity();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (_requiresAuth) {
        setState(() {
          _isAuthenticated = false;
        });
      }
    }
  }

  Future<void> _initAppSecurity() async {
    final prefs = await SharedPreferences.getInstance();
    final hasCode = await _securityService.hasPasscode();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    // Sync recents policy with native WindowManager.FLAG_SECURE
    final hideRecents = prefs.getBool('secure_recents_policy') ?? false;
    if (hideRecents) {
      await _securityService.setRecentsScreenshotPolicy(true);
    }

    if (mounted) {
      setState(() {
        _requiresAuth = hasCode;
        _isAuthenticated = !hasCode;
        _hasSeenOnboarding = hasSeenOnboarding;
        _isCheckingAuth = false;
      });
    }
  }

  void _onAuthenticationSuccess() {
    setState(() {
      _isAuthenticated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppThemeController.instance,
      builder: (context, _) {
        final themeCtrl = AppThemeController.instance;
        return MaterialApp(
          title: 'Notes',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          theme: AppTheme.light(accent: themeCtrl.accentColor),
          darkTheme: AppTheme.dark(oled: themeCtrl.isOled, accent: themeCtrl.accentColor),
          themeMode: themeCtrl.themeMode,
          home: _isCheckingAuth
              ? const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(color: AppColors.accentGold),
                  ),
                )
              : (!_isAuthenticated && _requiresAuth)
                  ? PasscodeScreen(
                      mode: PasscodeMode.unlockApp,
                      onSuccess: _onAuthenticationSuccess,
                    )
                  : (!_hasSeenOnboarding)
                      ? WelcomeTourScreen(
                          onComplete: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('has_seen_onboarding', true);
                            await prefs.setInt('last_seen_version_code', WhatsNewSheet.currentVersionCode);
                            if (mounted) {
                              setState(() {
                                _hasSeenOnboarding = true;
                              });
                            }
                          },
                        )
                      : NotesFeedScreen(repository: widget.repository),
        );
      },
    );
  }
}
