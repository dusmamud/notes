import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';

class AppThemeController extends ChangeNotifier {
  static final AppThemeController instance = AppThemeController._internal();
  AppThemeController._internal();

  ThemeMode _themeMode = ThemeMode.system;
  String _uiStyle = 'classic'; // Default classic as evidenced for device compatibility
  bool _isOled = false;
  Color _accentColor = AppColors.brandPrimary;
  double _defaultFontSize = 16.0;
  bool _reduceTransparency = false;
  String _notesStartWith = 'title'; // 'title', 'heading', 'body'
  String _sortCheckedItems = 'manually'; // 'manually', 'automatically'
  String _sortNotesBy = 'edited'; // 'edited', 'created', 'title'
  bool _autoSave = true;
  String _mathResultsMode = 'suggest'; // 'suggest', 'insert', 'off'

  ThemeMode get themeMode => _themeMode;
  String get uiStyle => _uiStyle;
  bool get isGlass => _uiStyle == 'glass' && !_reduceTransparency;
  bool get isOled => _isOled;
  Color get accentColor => _accentColor;
  double get defaultFontSize => _defaultFontSize;
  bool get reduceTransparency => _reduceTransparency;
  String get notesStartWith => _notesStartWith;
  String get sortCheckedItems => _sortCheckedItems;
  String get sortNotesBy => _sortNotesBy;
  bool get autoSave => _autoSave;
  String get mathResultsMode => _mathResultsMode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final modeStr = prefs.getString('app_theme_mode') ?? 'system';
    if (modeStr == 'light') {
      _themeMode = ThemeMode.light;
    } else if (modeStr == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }

    _uiStyle = prefs.getString('ui_style') ?? 'classic';
    _isOled = prefs.getBool('oled_true_black') ?? false;
    final accentVal = prefs.getInt('accent_color_value');
    if (accentVal != null) {
      _accentColor = Color(accentVal);
    }
    _defaultFontSize = prefs.getDouble('note_font_size') ?? 16.0;
    _reduceTransparency = prefs.getBool('ui_style_reduce_transparency') ?? false;
    _notesStartWith = prefs.getString('new_notes_start_with') ?? 'title';
    _sortCheckedItems = prefs.getString('sort_checked_items') ?? 'manually';
    _sortNotesBy = prefs.getString('sort_notes_by') ?? 'edited';
    _autoSave = prefs.getBool('auto_save') ?? true;
    _mathResultsMode = prefs.getString('math_results_mode') ?? 'suggest';
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    String str = 'system';
    if (mode == ThemeMode.light) str = 'light';
    if (mode == ThemeMode.dark) str = 'dark';
    await prefs.setString('app_theme_mode', str);
  }

  Future<void> setUiStyle(String style) async {
    _uiStyle = style;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ui_style', style);
  }

  Future<void> setOled(bool oled) async {
    _isOled = oled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('oled_true_black', oled);
  }

  Future<void> setAccentColor(Color color) async {
    _accentColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('accent_color_value', color.toARGB32());
  }

  Future<void> setDefaultFontSize(double size) async {
    _defaultFontSize = size;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('note_font_size', size);
  }

  Future<void> setReduceTransparency(bool reduce) async {
    _reduceTransparency = reduce;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ui_style_reduce_transparency', reduce);
  }

  Future<void> setNotesStartWith(String val) async {
    _notesStartWith = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('new_notes_start_with', val);
  }

  Future<void> setSortCheckedItems(String val) async {
    _sortCheckedItems = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sort_checked_items', val);
  }

  Future<void> setSortNotesBy(String val) async {
    _sortNotesBy = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sort_notes_by', val);
  }

  Future<void> setAutoSave(bool val) async {
    _autoSave = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_save', val);
  }

  Future<void> setMathResultsMode(String val) async {
    _mathResultsMode = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('math_results_mode', val);
  }
}
