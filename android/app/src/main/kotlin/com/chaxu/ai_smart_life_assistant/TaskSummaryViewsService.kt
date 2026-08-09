package com.chaxu.ai_smart_life_assistant

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray
import org.json.JSONObject

class TaskSummaryViewsService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return TaskSummaryViewsFactory(this.applicationContext)
    }
}

class TaskSummaryViewsFactory(private val context: Context) : RemoteViewsService.RemoteViewsFactory {
    private val taskList = mutableListOf<JSONObject>()

    override fun onCreate() {
        loadTasksData()
    }

    override fun onDataSetChanged() {
        loadTasksData()
    }

    private fun loadTasksData() {
        taskList.clear()
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

        val jsonStr = getValue("widget_tasks_json")
        if (!jsonStr.isNullOrEmpty()) {
            try {
                val array = JSONArray(jsonStr)
                for (i in 0 until array.length()) {
                    taskList.add(array.getJSONObject(i))
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    override fun onDestroy() {
        taskList.clear()
    }

    override fun getCount(): Int = taskList.size

    override fun getViewAt(position: Int): RemoteViews {
        if (position >= taskList.size) return RemoteViews(context.packageName, R.layout.widget_task_item)

        val task = taskList[position]
        val title = task.optString("title", "Untitled Task")
        val category = task.optString("category", "General")
        val timeStr = task.optString("timeStr", "")
        val taskId = task.optString("id", "")

        val views = RemoteViews(context.packageName, R.layout.widget_task_item).apply {
            setTextViewText(R.id.item_title, title)
            setTextViewText(R.id.item_category_tag, category)
            setTextViewText(R.id.item_time, timeStr)

            // Fill-in Intent for item click
            val fillInIntent = Intent().apply {
                data = Uri.parse("remindly://reminders/$taskId")
            }
            setOnClickFillInIntent(R.id.widget_item_container, fillInIntent)
        }

        return views
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = true
}
