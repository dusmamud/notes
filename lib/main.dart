import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/security/security_service.dart';
import 'core/security/passcode_screen.dart';
import 'features/notes/data/repositories/note_repository_impl.dart';
import 'features/notes/presentation/screens/notes_feed_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  final repository = NoteRepositoryImpl();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('hi'),
        Locale('ar'),
        Locale('de', 'DE'),
        Locale('es', 'ES'),
        Locale('fr', 'FR'),
        Locale('ja', 'JP'),
        Locale('zh', 'CN'),
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
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAppSecurityAndTheme();
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

  Future<void> _initAppSecurityAndTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final hasCode = await _securityService.hasPasscode();

    // Sync recents policy with native WindowManager.FLAG_SECURE
    final hideRecents = prefs.getBool('secure_recents_policy') ?? false;
    if (hideRecents) {
      await _securityService.setRecentsScreenshotPolicy(true);
    }

    // Load saved theme
    final savedTheme = prefs.getString('app_theme_mode') ?? 'system';
    ThemeMode mode = ThemeMode.system;
    if (savedTheme == 'light') mode = ThemeMode.light;
    if (savedTheme == 'dark') mode = ThemeMode.dark;

    if (mounted) {
      setState(() {
        _requiresAuth = hasCode;
        _isAuthenticated = !hasCode;
        _themeMode = mode;
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
    return MaterialApp(
      title: 'Notes',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      home: _isCheckingAuth
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : (!_isAuthenticated && _requiresAuth)
              ? PasscodeScreen(
                  mode: PasscodeMode.unlockApp,
                  onSuccess: _onAuthenticationSuccess,
                )
              : NotesFeedScreen(repository: widget.repository),
    );
  }
}
