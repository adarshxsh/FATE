package com.example.fate_app.telemetry

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat

class TelemetryForegroundService : Service() {
    private val CHANNEL_ID = "TelemetryServiceChannel"
    private val NOTIFICATION_ID = 101

    private lateinit var usageManager: UsageTelemetryManager
    private lateinit var proximityManager: ProximityTelemetryManager
    private lateinit var locationManager: LocationTelemetryManager

    override fun onCreate() {
        super.onCreate()
        Log.d("FATE_Service", "Service created")
        usageManager = UsageTelemetryManager(this)
        proximityManager = ProximityTelemetryManager(this)
        locationManager = LocationTelemetryManager(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("FATE_Service", "Service starting")
        val userName = intent?.getStringExtra("userName")

        createNotificationChannel()
        val notification = createNotification()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION or
                            ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        // Start trackers
        try {
            usageManager.startTracking()
        } catch (e: Exception) {
            Log.e("FATE_Service", "Usage track fail", e)
        }
        try {
            locationManager.startLocationUpdates()
        } catch (e: Exception) {
            Log.e("FATE_Service", "Loc track fail", e)
        }
        try {
            proximityManager.startDiscovery(userName)
        } catch (e: Exception) {
            Log.e("FATE_Service", "Prox track fail", e)
        }

        return START_STICKY
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("FATE Intelligence Active")
                .setContentText("Proximity and location analysis running in background.")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel =
                    NotificationChannel(
                            CHANNEL_ID,
                            "FATE Telemetry Service",
                            NotificationManager.IMPORTANCE_LOW
                    )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        Log.d("FATE_Service", "Service destroyed")
    }
}
