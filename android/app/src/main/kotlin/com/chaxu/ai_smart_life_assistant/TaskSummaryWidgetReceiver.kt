package com.chaxu.ai_smart_life_assistant

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews

class TaskSummaryWidgetReceiver : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        updateWidgetContent(context, appWidgetManager, appWidgetIds)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val componentName = ComponentName(context, TaskSummaryWidgetReceiver::class.java)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
        updateWidgetContent(context, appWidgetManager, appWidgetIds)
        appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetIds, R.id.widget_list_view)
    }

    private fun updateWidgetContent(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs1 = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val prefs2 = context.getSharedPreferences("${context.packageName}_preferences", Context.MODE_PRIVATE)
        val prefs3 = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

        fun getValue(key: String): String? {
            return prefs1.getString("flutter.$key", null)
                ?: prefs1.getString(key, null)
                ?: prefs2.getString("flutter.$key", null)
                ?: prefs2.getString(key, null)
                ?: prefs3.getString("flutter.$key", null)
                ?: prefs3.getString(key, null)
        }

        val stats = getValue("widget_task_stats") ?: "0/0 Completed"

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_task_summary).apply {
                setTextViewText(R.id.widget_task_stats, stats)

                // Set RemoteAdapter for scrollable ListView
                val intent = Intent(context, TaskSummaryViewsService::class.java)
                setRemoteAdapter(R.id.widget_list_view, intent)
                setEmptyView(R.id.widget_list_view, R.id.widget_empty_view)

                // PendingIntent template for ListView item clicks
                val clickIntent = Intent(context, MainActivity::class.java).apply {
                    action = Intent.ACTION_VIEW
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val clickPendingIntent = PendingIntent.getActivity(
                    context, 0, clickIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
                )
                setPendingIntentTemplate(R.id.widget_list_view, clickPendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
        appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetIds, R.id.widget_list_view)
    }
}
