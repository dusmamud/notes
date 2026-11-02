package com.dusrel.note.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import com.dusrel.note.MainActivity
import com.dusrel.note.R

class PlainNoteWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_plain_page)
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

            val noteId = prefs.getLong("flutter.widget_${appWidgetId}_note_id", -1L)
            val noteTitle = prefs.getString("flutter.widget_${appWidgetId}_title", "") ?: "Quick Memo"
            val noteBody = prefs.getString("flutter.widget_${appWidgetId}_body", "") ?: "Tap to write note..."
            val noteDate = prefs.getString("flutter.widget_${appWidgetId}_date", "") ?: ""

            views.setImageViewBitmap(
                R.id.widget_page_title,
                WidgetBitmapHelper.renderText(noteTitle, 44f, Color.BLACK, true)
            )
            views.setImageViewBitmap(
                R.id.widget_page_body,
                WidgetBitmapHelper.renderText(noteBody, 34f, Color.DKGRAY)
            )
            if (noteDate.isNotEmpty()) {
                views.setImageViewBitmap(
                    R.id.widget_page_date,
                    WidgetBitmapHelper.renderText(noteDate, 26f, Color.GRAY)
                )
            }

            val intent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                if (noteId != -1L) {
                    putExtra("note_id", noteId)
                }
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                400 + appWidgetId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

