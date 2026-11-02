package com.dusrel.note.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.dusrel.note.MainActivity
import com.dusrel.note.R

class CaptureBarWidgetProvider : AppWidgetProvider() {

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
            val views = RemoteViews(context.packageName, R.layout.widget_capture_bar)

            fun createPendingIntent(mode: String, reqCode: Int): PendingIntent {
                val intent = Intent(context, MainActivity::class.java).apply {
                    action = Intent.ACTION_VIEW
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra("capture_mode", mode)
                }
                val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                return PendingIntent.getActivity(context, reqCode, intent, flags)
            }

            views.setOnClickPendingIntent(
                R.id.widget_capture_new,
                createPendingIntent("new_note", 101)
            )
            views.setOnClickPendingIntent(
                R.id.widget_capture_checklist,
                createPendingIntent("checklist", 102)
            )
            views.setOnClickPendingIntent(
                R.id.widget_capture_record,
                createPendingIntent("audio", 103)
            )
            views.setOnClickPendingIntent(
                R.id.widget_capture_camera,
                createPendingIntent("camera", 104)
            )
            views.setOnClickPendingIntent(
                R.id.widget_capture_scan,
                createPendingIntent("scan", 105)
            )

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

