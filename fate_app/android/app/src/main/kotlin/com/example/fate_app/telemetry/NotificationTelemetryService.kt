package com.example.fate_app.telemetry

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

class NotificationTelemetryService : NotificationListenerService() {

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        sbn?.let {
            val packageName = it.packageName
            val extras = it.notification.extras
            val title = extras.getString("android.title") ?: ""
            val text = extras.getCharSequence("android.text")?.toString() ?: ""
            val postTime = it.postTime  // Epoch ms when notification arrived

            Log.d("FATE_Telemetry", "Posted: $packageName | $title | $text")
            
            TelemetryEventBus.emitEvent("notification_posted", mapOf(
                "package" to packageName,
                "title" to title,
                "text" to text,
                "post_time" to postTime
            ))
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        super.onNotificationRemoved(sbn)
        sbn?.let {
            val packageName = it.packageName
            TelemetryEventBus.emitEvent("notification_removed", mapOf(
                "package" to packageName
            ))
        }
    }
}
