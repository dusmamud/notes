package com.dusrel.note

import android.appwidget.AppWidgetManager
import android.content.ClipData
import android.content.ClipboardManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.provider.CalendarContract
import android.view.WindowManager
import com.dusrel.note.widget.CaptureBarWidgetProvider
import com.dusrel.note.widget.FolderWidgetProvider
import com.dusrel.note.widget.NewNoteWidgetProvider
import com.dusrel.note.widget.NoteWidgetProvider
import com.dusrel.note.widget.PlainNoteWidgetProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL_CLIPBOARD = "inotes/clipboard"
        private const val CHANNEL_RECENTS = "inotes/recents"
        private const val CHANNEL_CALENDAR = "inotes/calendar"
        private const val CHANNEL_HOME_WIDGET = "inotes/home_widget"
        private const val CHANNEL_QUICK_NOTE = "inotes/quick_note"
    }

    private var initialIntentData: Map<String, Any?>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        extractIntentData(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        extractIntentData(intent)
    }

    private fun extractIntentData(intent: Intent?) {
        if (intent == null) return
        val map = mutableMapOf<String, Any?>()
        if (intent.hasExtra("capture_mode")) {
            map["capture_mode"] = intent.getStringExtra("capture_mode")
        }
        if (intent.hasExtra("note_id")) {
            map["note_id"] = intent.getLongExtra("note_id", -1L)
        }
        if (intent.hasExtra("folder_id")) {
            map["folder_id"] = intent.getLongExtra("folder_id", -1L)
        }
        if (intent.action == "com.dusrel.note.action.OPEN_MATH_NOTES") {
            map["capture_mode"] = "math_notes"
        }
        if (map.isNotEmpty()) {
            initialIntentData = map
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Specialized Clipboard Channel (copy_without_spaces, IBAN, tracking)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_CLIPBOARD)
            .setMethodCallHandler { call, result ->
                val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                when (call.method) {
                    "copyWithoutSpaces" -> {
                        val text = call.argument<String>("text") ?: ""
                        val cleaned = text.replace("\\s+".toRegex(), "")
                        clipboard.setPrimaryClip(ClipData.newPlainText("note_cleaned", cleaned))
                        result.success(true)
                    }
                    "copyFormatted" -> {
                        val text = call.argument<String>("text") ?: ""
                        val label = call.argument<String>("label") ?: "note_copy"
                        clipboard.setPrimaryClip(ClipData.newPlainText(label, text))
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // 2. Task Switcher Privacy / Recents Blur Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_RECENTS)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "applyRecentsScreenshotPolicy" -> {
                        val hideInRecents = call.argument<Boolean>("hideInRecents") ?: false
                        if (hideInRecents) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        }
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // 3. Android Calendar Sync Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_CALENDAR)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "createEvent" -> {
                        val title = call.argument<String>("title") ?: ""
                        val beginTime = call.argument<Long>("beginTime") ?: System.currentTimeMillis()
                        val intent = Intent(Intent.ACTION_INSERT)
                            .setData(CalendarContract.Events.CONTENT_URI)
                            .putExtra(CalendarContract.Events.TITLE, title)
                            .putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, beginTime)
                        startActivity(intent)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // 4. Homescreen Widgets Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_HOME_WIDGET)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "updateWidget" -> {
                        val appWidgetManager = AppWidgetManager.getInstance(this)

                        val noteWidgetIds = appWidgetManager.getAppWidgetIds(ComponentName(this, NoteWidgetProvider::class.java))
                        if (noteWidgetIds.isNotEmpty()) {
                            NoteWidgetProvider().onUpdate(this, appWidgetManager, noteWidgetIds)
                        }

                        val plainWidgetIds = appWidgetManager.getAppWidgetIds(ComponentName(this, PlainNoteWidgetProvider::class.java))
                        if (plainWidgetIds.isNotEmpty()) {
                            PlainNoteWidgetProvider().onUpdate(this, appWidgetManager, plainWidgetIds)
                        }

                        val folderWidgetIds = appWidgetManager.getAppWidgetIds(ComponentName(this, FolderWidgetProvider::class.java))
                        if (folderWidgetIds.isNotEmpty()) {
                            FolderWidgetProvider().onUpdate(this, appWidgetManager, folderWidgetIds)
                        }

                        val captureWidgetIds = appWidgetManager.getAppWidgetIds(ComponentName(this, CaptureBarWidgetProvider::class.java))
                        if (captureWidgetIds.isNotEmpty()) {
                            CaptureBarWidgetProvider().onUpdate(this, appWidgetManager, captureWidgetIds)
                        }

                        val newNoteWidgetIds = appWidgetManager.getAppWidgetIds(ComponentName(this, NewNoteWidgetProvider::class.java))
                        if (newNoteWidgetIds.isNotEmpty()) {
                            NewNoteWidgetProvider().onUpdate(this, appWidgetManager, newNoteWidgetIds)
                        }

                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // 5. Quick Note Intent Receiver Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_QUICK_NOTE)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialIntent" -> {
                        result.success(initialIntentData)
                        initialIntentData = null
                    }
                    else -> result.notImplemented()
                }
            }

        // 6. Hardware & Platform Capability Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "inotes/device")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAndroidSdkInt" -> {
                        result.success(android.os.Build.VERSION.SDK_INT)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
