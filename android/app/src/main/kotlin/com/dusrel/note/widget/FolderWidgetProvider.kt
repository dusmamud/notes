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

class FolderWidgetProvider : AppWidgetProvider() {

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
            val views = RemoteViews(context.packageName, R.layout.widget_folder)
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

            val folderId = prefs.getLong("flutter.widget_${appWidgetId}_folder_id", -1L)
            val folderTitle = prefs.getString("flutter.widget_${appWidgetId}_folder_title", "Notes") ?: "Notes"

            views.setViewVisibility(R.id.widget_header_icon, View.VISIBLE)
            views.setViewVisibility(R.id.widget_header_title, View.VISIBLE)
            views.setImageViewBitmap(
                R.id.widget_header_title,
                WidgetBitmapHelper.renderText(folderTitle, 38f, Color.WHITE, true)
            )

            val intent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                if (folderId != -1L) {
                    putExtra("folder_id", folderId)
                }
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                500 + appWidgetId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

