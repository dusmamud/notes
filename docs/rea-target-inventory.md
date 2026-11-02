# REA Target Inventory & Parity Checklist

> **Target App Package:** `com.inotesapp.inotes` (Target APK: [`base.apk`](file:///D:/0/dusrel/notes/file-apk/base.apk), [`split_config.arm64_v8a.apk`](file:///D:/0/dusrel/notes/file-apk/split_config.arm64_v8a.apk))  
> **Rebuild App Package:** `com.dusrel.note`  
> **Evidence Sources:** REA MCP (`identify_flutter_build`, `inspect_dart_aot`, `inspect_android_package`, `decode_android_resources`, `inspect_apk_signature`), Decompiled JADX (`docs/analysis/01_STACK_AND_FRAMEWORK.md` - `10_TARGET_APP_EXACT_FEATURE_SPEC.md`, `EXTRACTED_DART_SYMBOLS_FROM_SO.txt`, `notices.txt`).  
> **Audit Status:** Ground truth verified; strictly inventory-only (no self-additions).

---

## 1. Flutter Packages & Core Plugins

| Category | Package / Dependency | Target Evidence Source | Status in `com.dusrel.note` | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **UI & Theming** | `cupertino_icons` | `02_DEPENDENCIES_AND_PLUGINS.md`, `notices.txt` | **PRESENT** | Configured in `pubspec.yaml` |
| **UI & Theming** | `flex_color_scheme` | `02_DEPENDENCIES_AND_PLUGINS.md`, `notices.txt` | **PRESENT** | Multi-palette dynamic themes |
| **UI & Theming** | `flex_seed_scheme` | `02_DEPENDENCIES_AND_PLUGINS.md`, `notices.txt` | **PRESENT** | Seed color harmonic palettes |
| **UI & Theming** | `flutter_slidable` | `02_DEPENDENCIES_AND_PLUGINS.md`, `notices.txt` | **PRESENT** | Swipe to Pin / Delete |
| **UI & Theming** | `pull_down_button` | `02_DEPENDENCIES_AND_PLUGINS.md`, `notices.txt` | **PRESENT** | iOS glass popup menus |
| **UI & Theming** | `smooth_sheets` | `02_DEPENDENCIES_AND_PLUGINS.md`, `notices.txt` | **PRESENT** | Modal physics sheets |
| **UI & Theming** | `emoji_picker_flutter`| `02_DEPENDENCIES_AND_PLUGINS.md`, `notices.txt` | **PRESENT** | Emoji selector for folders |
| **UI & Theming** | `sliver_tools` | `STATUS.md`, `notices.txt` | **PRESENT** | Sticky pinned section headers |
| **UI & Theming** | `cupertino_lists_enhanced`| `STATUS.md`, `notices.txt` | **PRESENT** | Grouped iOS lists |
| **UI & Theming** | `navigator_resizable`| `STATUS.md`, `notices.txt` | **PRESENT** | Foldable/Tablet multi-column |
| **Editor** | `appflowy_editor` | `02_DEPENDENCIES_AND_PLUGINS.md`, `libapp.so` | **PARTIAL** | Custom rich-text editor with markdown & math engine |
| **Editor** | `markdown` | `02_DEPENDENCIES_AND_PLUGINS.md` | **PRESENT** | Note export & format parsing |
| **Database** | `objectbox` | `02_DEPENDENCIES_AND_PLUGINS.md`, `libobjectbox-jni.so` | **PARTIAL** | In `pubspec.yaml`, repository currently backed by encrypted SharedPreferences |
| **Database** | `shared_preferences` | `02_DEPENDENCIES_AND_PLUGINS.md`, `notices.txt` | **PRESENT** | Settings & preferences |
| **Media & Audio**| `record` | `02_DEPENDENCIES_AND_PLUGINS.md`, `notices.txt` | **PRESENT** | Real AAC/M4A mic recording |
| **Media & Audio**| `just_audio` | `02_DEPENDENCIES_AND_PLUGINS.md`, `notices.txt` | **PRESENT** | Audio player with scrubbing |
| **Media & Audio**| `audio_session` | `02_DEPENDENCIES_AND_PLUGINS.md`, `notices.txt` | **PRESENT** | Audio session configuration |
| **Scanner & PDF**| `cunning_document_scanner`| `02_DEPENDENCIES_AND_PLUGINS.md`, `notices.txt` | **PRESENT** | Edge-detection camera scanner |
| **Scanner & PDF**| `pdf` & `printing` | `02_DEPENDENCIES_AND_PLUGINS.md`, `notices.txt` | **PRESENT** | PDF export engine |
| **Scanner & PDF**| `pdfrx` | `02_DEPENDENCIES_AND_PLUGINS.md`, `notices.txt` | **PRESENT** | High-performance PDF viewing |
| **Scanner & PDF**| `html_to_pdf` | `02_DEPENDENCIES_AND_PLUGINS.md` | **MISSING** | Note HTML to PDF bridge |
| **Security** | `local_auth` | `02_DEPENDENCIES_AND_PLUGINS.md`, `notices.txt` | **PRESENT** | Biometric fingerprint/face |
| **Security** | `encrypt` & `pointycastle`| `02_DEPENDENCIES_AND_PLUGINS.md`, `notices.txt` | **PRESENT** | AES-256 encryption engine |
| **Security** | `crypto` | `02_DEPENDENCIES_AND_PLUGINS.md` | **PRESENT** | SHA-256 salted PIN hashing |
| **Localization** | `intl` | `02_DEPENDENCIES_AND_PLUGINS.md`, `notices.txt` | **PRESENT** | Date/time localization |
| **Localization** | `easy_localization` | `02_DEPENDENCIES_AND_PLUGINS.md`, `03_ASSETS_AND_TRANSLATIONS.md` | **PARTIAL** | 21 JSON translations loaded directly |
| **Cloud & Auth** | `firebase_auth` & `core` | `02_DEPENDENCIES_AND_PLUGINS.md` | **MISSING** | Deferred for future release |
| **Cloud & Auth** | `google_sign_in` | `02_DEPENDENCIES_AND_PLUGINS.md` | **MISSING** | Deferred for future release |
| **Monetization** | `purchases_flutter`| `02_DEPENDENCIES_AND_PLUGINS.md` | **MISSING** | Deferred for future release |
| **Monetization** | `google_mobile_ads`| `02_DEPENDENCIES_AND_PLUGINS.md` | **MISSING** | Deferred for future release |
| **Hardware** | `image_picker` | `02_DEPENDENCIES_AND_PLUGINS.md` | **PRESENT** | Photo/camera picker |
| **Hardware** | `share_plus` | `02_DEPENDENCIES_AND_PLUGINS.md` | **PRESENT** | Android share intent |
| **Hardware** | `url_launcher` | `02_DEPENDENCIES_AND_PLUGINS.md` | **PRESENT** | Hyperlink dispatch |
| **Hardware** | `workmanager` | `02_DEPENDENCIES_AND_PLUGINS.md` | **MISSING** | Background worker |
| **Hardware** | `connectivity_plus`| `02_DEPENDENCIES_AND_PLUGINS.md` | **PRESENT** | Real-time network watcher |
| **Hardware** | `permission_handler`| `02_DEPENDENCIES_AND_PLUGINS.md` | **PRESENT** | Runtime permissions |
| **Utility** | `file_picker` | `02_DEPENDENCIES_AND_PLUGINS.md` | **PRESENT** | File import/export |

---

## 2. Android Homescreen Widgets & Tiles

| Component Name | Type | Target Class / Evidence | Status in `com.dusrel.note` | Evidence File |
| :--- | :--- | :--- | :--- | :--- |
| **`CaptureBarWidgetProvider`** | AppWidgetProvider | `06_DECOMPILED_NATIVE_CHANNELS_AND_WIDGETS.md` | **PRESENT** | [`CaptureBarWidgetProvider.kt`](file:///D:/0/dusrel/notes/note/android/app/src/main/kotlin/com/dusrel/note/widget/CaptureBarWidgetProvider.kt) |
| **`HomeWidgetProvider`** | AppWidgetProvider | `06_DECOMPILED_NATIVE_CHANNELS_AND_WIDGETS.md` | **PRESENT** | [`NoteWidgetProvider.kt`](file:///D:/0/dusrel/notes/note/android/app/src/main/kotlin/com/dusrel/note/widget/NoteWidgetProvider.kt) |
| **`FolderWidgetProvider`** | AppWidgetProvider | `06_DECOMPILED_NATIVE_CHANNELS_AND_WIDGETS.md` | **PRESENT** | [`FolderWidgetProvider.kt`](file:///D:/0/dusrel/notes/note/android/app/src/main/kotlin/com/dusrel/note/widget/FolderWidgetProvider.kt) |
| **`NewNoteWidgetProvider`** | AppWidgetProvider | `06_DECOMPILED_NATIVE_CHANNELS_AND_WIDGETS.md` | **PRESENT** | [`NewNoteWidgetProvider.kt`](file:///D:/0/dusrel/notes/note/android/app/src/main/kotlin/com/dusrel/note/widget/NewNoteWidgetProvider.kt) |
| **`NoteWidgetProvider`** | AppWidgetProvider | `06_DECOMPILED_NATIVE_CHANNELS_AND_WIDGETS.md` | **PRESENT** | [`NoteWidgetProvider.kt`](file:///D:/0/dusrel/notes/note/android/app/src/main/kotlin/com/dusrel/note/widget/NoteWidgetProvider.kt) |
| **`PlainNoteWidgetProvider`**| AppWidgetProvider | `06_DECOMPILED_NATIVE_CHANNELS_AND_WIDGETS.md` | **PRESENT** | [`PlainNoteWidgetProvider.kt`](file:///D:/0/dusrel/notes/note/android/app/src/main/kotlin/com/dusrel/note/widget/PlainNoteWidgetProvider.kt) |
| **`WidgetConfigureActivity`**| Activity | `06_DECOMPILED_NATIVE_CHANNELS_AND_WIDGETS.md` | **PRESENT** | [`WidgetConfigureActivity.kt`](file:///D:/0/dusrel/notes/note/android/app/src/main/kotlin/com/dusrel/note/widget/WidgetConfigureActivity.kt) |
| **`QuickNoteTileService`** | Quick Settings Tile | `06_DECOMPILED_NATIVE_CHANNELS_AND_WIDGETS.md` | **PRESENT** | [`QuickNoteTileService.kt`](file:///D:/0/dusrel/notes/note/android/app/src/main/kotlin/com/dusrel/note/QuickNoteTileService.kt) |

---

## 3. Shaders

| Shader Asset | Purpose | Target Evidence Source | Status in `com.dusrel.note` |
| :--- | :--- | :--- | :--- |
| **`ink_sparkle.frag`** | Sparkle particle effect for AI & highlights | `assets/shaders/ink_sparkle.frag` | **PRESENT** (`note/shaders/ink_sparkle.frag`) |
| **`stretch_effect.frag`**| Overscroll rubber-band stretch physics | `assets/shaders/stretch_effect.frag` | **PRESENT** (`note/shaders/stretch_effect.frag`) |

---

## 4. Fonts & Typography

| Font Asset | Family | Target Evidence Source | Status in `com.dusrel.note` |
| :--- | :--- | :--- | :--- |
| **`fonts/variable.ttf`** | `pretenda` Variable Font | `03_ASSETS_AND_TRANSLATIONS.md` | **PRESENT** (`note/assets/fonts/variable.ttf`) |
| **`MaterialIcons-Regular.otf`**| Material Icons | `03_ASSETS_AND_TRANSLATIONS.md` | **PRESENT** (Flutter standard) |
| **`CupertinoIcons.ttf`** | iOS Cupertino Icons | `03_ASSETS_AND_TRANSLATIONS.md` | **PRESENT** (`package:cupertino_icons`) |

---

## 5. Translations & Localization

| Locale Code | Language | Target Evidence Source | Status in `com.dusrel.note` |
| :--- | :--- | :--- | :--- |
| `en-US` | English (United States) | `03_ASSETS_AND_TRANSLATIONS.md` | **PRESENT** (`assets/translations/en-US.json`) |
| `hi` | Hindi | `03_ASSETS_AND_TRANSLATIONS.md` | **PRESENT** (`assets/translations/hi.json`) |
| `es-ES` | Spanish (Spain) | `03_ASSETS_AND_TRANSLATIONS.md` | **PRESENT** (`assets/translations/es-ES.json`) |
| `fr-FR` | French (France) | `03_ASSETS_AND_TRANSLATIONS.md` | **PRESENT** (`assets/translations/fr-FR.json`) |
| `de-DE` | German (Germany) | `03_ASSETS_AND_TRANSLATIONS.md` | **PRESENT** (`assets/translations/de-DE.json`) |
| `it-IT` | Italian (Italy) | `03_ASSETS_AND_TRANSLATIONS.md` | **PRESENT** (`assets/translations/it-IT.json`) |
| `pt-BR` | Portuguese (Brazil) | `03_ASSETS_AND_TRANSLATIONS.md` | **PRESENT** (`assets/translations/pt-BR.json`) |
| `ru-RU` | Russian | `03_ASSETS_AND_TRANSLATIONS.md` | **PRESENT** (`assets/translations/ru-RU.json`) |
| `zh-CN` | Simplified Chinese | `03_ASSETS_AND_TRANSLATIONS.md` | **PRESENT** (`assets/translations/zh-CN.json`) |
| `ja-JP` | Japanese | `03_ASSETS_AND_TRANSLATIONS.md` | **PRESENT** (`assets/translations/ja-JP.json`) |
| `ko-KR` | Korean | `03_ASSETS_AND_TRANSLATIONS.md` | **PRESENT** (`assets/translations/ko-KR.json`) |
| `ar` | Arabic (RTL) | `03_ASSETS_AND_TRANSLATIONS.md` | **PRESENT** (`assets/translations/ar.json`) |
| `id-ID` | Indonesian | `03_ASSETS_AND_TRANSLATIONS.md` | **PRESENT** (`assets/translations/id-ID.json`) |
| `ms-MY` | Malay | `03_ASSETS_AND_TRANSLATIONS.md` | **PRESENT** (`assets/translations/ms-MY.json`) |
| `th-TH` | Thai | `03_ASSETS_AND_TRANSLATIONS.md` | **PRESENT** (`assets/translations/th-TH.json`) |
| `vi-VN` | Vietnamese | `03_ASSETS_AND_TRANSLATIONS.md` | **PRESENT** (`assets/translations/vi-VN.json`) |
| `tr-TR` | Turkish | `03_ASSETS_AND_TRANSLATIONS.md` | **PRESENT** (`assets/translations/tr-TR.json`) |
| `uk-UA` | Ukrainian | `03_ASSETS_AND_TRANSLATIONS.md` | **PRESENT** (`assets/translations/uk-UA.json`) |
| `fi-FI` | Finnish | `03_ASSETS_AND_TRANSLATIONS.md` | **PRESENT** (`assets/translations/fi-FI.json`) |
| `fil-PH` | Filipino | `03_ASSETS_AND_TRANSLATIONS.md` | **PRESENT** (`assets/translations/fil-PH.json`) |

---

## 6. Native MethodChannels

| Channel Name | Purpose / Handler | Target Evidence Source | Status in `com.dusrel.note` | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **`inotes/quick_note`** | Quick Settings Tile launch | `06_DECOMPILED_NATIVE_CHANNELS_AND_WIDGETS.md` | **PARTIAL** | Native tile service registered |
| **`inotes/math_notes`** | Inline calculation engine | `06_DECOMPILED_NATIVE_CHANNELS_AND_WIDGETS.md` | **PARTIAL** | High-precision Dart engine wired |
| **`inotes/home_widget`** | Homescreen widget data sync | `06_DECOMPILED_NATIVE_CHANNELS_AND_WIDGETS.md` | **PRESENT** | Synced via SharedPreferences |
| **`inotes/note_lock_kdf`**| Salted Key Derivation | `06_DECOMPILED_NATIVE_CHANNELS_AND_WIDGETS.md` | **PARTIAL** | Dart PBKDF2/SHA-256 implementation |
| **`inotes/backup_zip`** | Full ZIP export/import | `06_DECOMPILED_NATIVE_CHANNELS_AND_WIDGETS.md` | **MISSING** | Backup ZIP engine |
| **`inotes/calendar`** | System calendar sync | `06_DECOMPILED_NATIVE_CHANNELS_AND_WIDGETS.md` | **PARTIAL** | Native channel defined in MainActivity |
| **`inotes/capture`** | Camera & document capture | `06_DECOMPILED_NATIVE_CHANNELS_AND_WIDGETS.md` | **PARTIAL** | Document scanner & image picker wired |
| **`inotes/clipboard`** | System clipboard copy/paste | `06_DECOMPILED_NATIVE_CHANNELS_AND_WIDGETS.md` | **PARTIAL** | Native channel defined in MainActivity |
| **`inotes/share_intent`**| Share receiver | `06_DECOMPILED_NATIVE_CHANNELS_AND_WIDGETS.md` | **PARTIAL** | Share_plus integration |
| **`inotes/recents`** | Privacy screen blur / FLAG_SECURE | `06_DECOMPILED_NATIVE_CHANNELS_AND_WIDGETS.md` | **PRESENT** | `hideInRecents` boolean synchronized with native `FLAG_SECURE` |
| **`inotes/physical_keyboard`** | Hardware keyboard detection | `06_DECOMPILED_NATIVE_CHANNELS_AND_WIDGETS.md` | **PRESENT** | `CallbackShortcuts` & `KeyboardListener` |
| **`inotes/font_scale`** | Independent text scaler | `06_DECOMPILED_NATIVE_CHANNELS_AND_WIDGETS.md` | **PRESENT** | Multi-level textScale in editor & preview |
| **`inotes/review`** | In-app Play Store review | `06_DECOMPILED_NATIVE_CHANNELS_AND_WIDGETS.md` | **MISSING** | Play In-App Review |
| **`inotes/native_ad_events`**| AdMob inline card events | `06_DECOMPILED_NATIVE_CHANNELS_AND_WIDGETS.md` | **MISSING** | Monetization deferred |
| **`inotes/edge_guard`** | Custom squircle framing | `06_DECOMPILED_NATIVE_CHANNELS_AND_WIDGETS.md` | **MISSING** | Native view |
| **`inotes/keyboards`** | Real-time keyboard height | `06_DECOMPILED_NATIVE_CHANNELS_AND_WIDGETS.md` | **PARTIAL** | `keyboard_height_plugin` in pubspec |
| **`inotes/ad_region`** | GDPR / CCPA geo policy | `06_DECOMPILED_NATIVE_CHANNELS_AND_WIDGETS.md` | **MISSING** | Monetization deferred |
| **`inotes/device_info`** | Device specs & biometric hardware | `06_DECOMPILED_NATIVE_CHANNELS_AND_WIDGETS.md` | **PRESENT** | `device_info_plus` & `local_auth` |
| **`inotes/network`** | Real-time network watcher | `06_DECOMPILED_NATIVE_CHANNELS_AND_WIDGETS.md` | **PRESENT** | `connectivity_plus` integration |
