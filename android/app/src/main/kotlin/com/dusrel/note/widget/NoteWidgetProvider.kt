package com.dusrel.note.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import com.dusrel.note.MainActivity
import com.dusrel.note.R

class NoteWidgetProvider : AppWidgetProvider() {

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
            val views = RemoteViews(context.packageName, R.layout.widget_note)
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

            val noteId = prefs.getLong("flutter.widget_${appWidgetId}_note_id", -1L)
            val noteTitle = prefs.getString("flutter.widget_${appWidgetId}_title", "") ?: ""
            val noteBody = prefs.getString("flutter.widget_${appWidgetId}_body", "") ?: ""
            val noteDate = prefs.getString("flutter.widget_${appWidgetId}_date", "") ?: ""

            if (noteTitle.isEmpty() && noteBody.isEmpty()) {
                views.setViewVisibility(R.id.widget_note_empty_icon, View.VISIBLE)
                views.setViewVisibility(R.id.widget_note_empty, View.VISIBLE)
                views.setImageViewBitmap(
                    R.id.widget_note_empty,
                    WidgetBitmapHelper.renderText("No Note Selected", 36f, Color.GRAY)
                )
            } else {
                views.setViewVisibility(R.id.widget_note_empty_icon, View.GONE)
                views.setViewVisibility(R.id.widget_note_empty, View.GONE)

                if (noteTitle.isNotEmpty()) {
                    views.setImageViewBitmap(
                        R.id.widget_note_title,
                        WidgetBitmapHelper.renderText(noteTitle, 48f, Color.BLACK, true)
                    )
                }
                if (noteBody.isNotEmpty()) {
                    val preview = if (noteBody.length > 120) noteBody.substring(0, 120) + "..." else noteBody
                    views.setImageViewBitmap(
                        R.id.widget_note_body,
                        WidgetBitmapHelper.renderText(preview, 36f, Color.DKGRAY)
                    )
                }
                if (noteDate.isNotEmpty()) {
                    views.setImageViewBitmap(
                        R.id.widget_note_date,
                        WidgetBitmapHelper.renderText(noteDate, 28f, Color.GRAY)
                    )
                }
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
                300 + appWidgetId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

