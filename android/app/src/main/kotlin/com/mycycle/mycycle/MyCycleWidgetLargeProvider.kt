package com.mycycle.mycycle

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class MyCycleWidgetLargeProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_large)
            bindLargeWidget(context, views, widgetData)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    companion object {
        fun bindLargeWidget(
            context: Context,
            views: RemoteViews,
            widgetData: SharedPreferences,
        ) {
            val moodEmoji = widgetData.getString("widget_mood_emoji", "—") ?: "—"
            val moodLabel = widgetData.getString("widget_mood_label", "не отмечено") ?: "не отмечено"

            views.setTextViewText(
                R.id.cycle_day_value,
                widgetData.getString("widget_cycle_day", "—") ?: "—",
            )
            views.setTextViewText(
                R.id.phase_value,
                widgetData.getString("widget_phase", "—") ?: "—",
            )
            views.setTextViewText(
                R.id.days_until_value,
                widgetData.getString("widget_days_until", "—") ?: "—",
            )
            views.setTextViewText(
                R.id.accuracy_value,
                widgetData.getString("widget_accuracy", "—") ?: "—",
            )
            views.setTextViewText(
                R.id.mood_value,
                "$moodEmoji $moodLabel",
            )
            views.setTextViewText(
                R.id.event_value,
                widgetData.getString("widget_next_event", "—") ?: "—",
            )

            views.setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )

            views.setOnClickPendingIntent(
                R.id.mood_good,
                HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    Uri.parse("mycycle://mood/good"),
                ),
            )
            views.setOnClickPendingIntent(
                R.id.mood_normal,
                HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    Uri.parse("mycycle://mood/normal"),
                ),
            )
            views.setOnClickPendingIntent(
                R.id.mood_bad,
                HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    Uri.parse("mycycle://mood/bad"),
                ),
            )
        }
    }
}
