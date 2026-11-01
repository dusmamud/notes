package com.dusrel.note

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.provider.CalendarContract
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL_CLIPBOARD = "inotes/clipboard"
        private const val CHANNEL_RECENTS = "inotes/recents"
        private const val CHANNEL_CALENDAR = "inotes/calendar"
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
    }
}
