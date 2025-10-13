package com.example.pensieve

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.widget.RemoteViews

/**
 * Widget provider per la cattura rapida con camera
 */
class CameraWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // Aggiorna tutti i widget
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        // Widget abilitato per la prima volta
    }

    override fun onDisabled(context: Context) {
        // Ultimo widget rimosso
    }

    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            // Crea il RemoteViews per il layout del widget
            val layoutId = context.resources.getIdentifier("camera_widget_layout", "layout", context.packageName)
            val views = RemoteViews(context.packageName, layoutId)

            // Crea l'intent per aprire l'app con deep link
            val intent = Intent(Intent.ACTION_VIEW).apply {
                data = Uri.parse("rocketnotes://camera")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                setPackage(context.packageName)
                putExtra("from_widget", true)
            }

            // Crea il PendingIntent con flag appropriati per Android 12+
            val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }

            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                pendingIntentFlags
            )

            // Imposta il click listener sul container del widget
            val containerId = context.resources.getIdentifier("widget_container", "id", context.packageName)
            views.setOnClickPendingIntent(containerId, pendingIntent)

            // Aggiorna il widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
