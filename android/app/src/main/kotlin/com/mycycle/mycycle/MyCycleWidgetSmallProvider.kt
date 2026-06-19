package com.mycycle.mycycle

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class MyCycleWidgetSmallProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_small)
            bindSmallWidget(context, views, widgetData)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    companion object {
        fun bindSmallWidget(
            context: Context,
            views: RemoteViews,
            widgetData: SharedPreferences,
        ) {
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
            views.setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )
        }
    }
}
