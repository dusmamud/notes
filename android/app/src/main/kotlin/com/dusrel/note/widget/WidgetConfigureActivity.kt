package com.dusrel.note.widget

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.TextView
import com.dusrel.note.R

class WidgetConfigureActivity : Activity() {

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(RESULT_CANCELED)

        val intent = intent
        val extras = intent.extras
        if (extras != null) {
            appWidgetId = extras.getInt(
                AppWidgetManager.EXTRA_APPWIDGET_ID,
                AppWidgetManager.INVALID_APPWIDGET_ID
            )
        }

        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        setContentView(R.layout.widget_edit_card)

        findViewById<TextView>(R.id.edit_title)?.text = getString(R.string.widget_note_label)
        findViewById<TextView>(R.id.edit_app)?.text = getString(R.string.app_name)
        findViewById<TextView>(R.id.edit_description)?.text = "Display quick capture and sticky notes on your home screen."

        findViewById<TextView>(R.id.edit_target_label)?.text = "Selected Note"
        findViewById<TextView>(R.id.edit_target_value)?.text = "All Notes"

        findViewById<TextView>(R.id.edit_theme_label)?.text = "Theme"
        findViewById<TextView>(R.id.edit_theme_value)?.text = "System"

        val doneButton = findViewById<TextView>(R.id.edit_done)
        doneButton?.visibility = View.VISIBLE
        doneButton?.text = "Done"
        doneButton?.setOnClickListener {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            prefs.edit()
                .putLong("flutter.widget_${appWidgetId}_note_id", 1L)
                .putString("flutter.widget_${appWidgetId}_title", "My Notes")
                .putString("flutter.widget_${appWidgetId}_body", "Tap here to open notes...")
                .apply()

            val appWidgetManager = AppWidgetManager.getInstance(this)
            NoteWidgetProvider.updateAppWidget(this, appWidgetManager, appWidgetId)
            PlainNoteWidgetProvider.updateAppWidget(this, appWidgetManager, appWidgetId)
            FolderWidgetProvider.updateAppWidget(this, appWidgetManager, appWidgetId)

            val resultValue = Intent().apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            }
            setResult(RESULT_OK, resultValue)
            finish()
        }
    }
}

