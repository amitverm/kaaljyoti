package com.kaaljyoti

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Daily Panchang widget: renders the strings precomputed by the
 * Flutter app (OsWidgetService). No ephemeris runs here — the data is
 * valid for the Vedic day and refreshed whenever the app opens plus
 * on the OS's 30-minute cycle (which simply re-reads the same store).
 */
class PanchangWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val data = HomeWidgetPlugin.getData(context)
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_panchang)
            views.setTextViewText(R.id.pw_title, data.getString("pw_title", "Panchang"))
            views.setTextViewText(R.id.pw_place, data.getString("pw_place", ""))
            views.setTextViewText(R.id.pw_tithi, data.getString("pw_tithi", "Open the app once"))
            views.setTextViewText(R.id.pw_nakshatra, data.getString("pw_nakshatra", ""))
            views.setTextViewText(R.id.pw_sun, data.getString("pw_sun", ""))
            views.setTextViewText(R.id.pw_abhijit, data.getString("pw_abhijit", ""))
            views.setTextViewText(R.id.pw_disha, data.getString("pw_disha", ""))
            views.setTextViewText(R.id.pw_rahu, data.getString("pw_rahu", ""))

            // Tap anywhere -> open the app (lands on Today).
            val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (launch != null) {
                val pending = PendingIntent.getActivity(
                    context, 0, launch,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.pw_root, pending)
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
