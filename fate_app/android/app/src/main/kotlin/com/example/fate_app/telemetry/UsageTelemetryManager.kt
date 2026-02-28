package com.example.fate_app.telemetry

import android.app.usage.UsageStatsManager
import android.content.Context
import android.util.Log

class UsageTelemetryManager(private val context: Context) {

    private var isTracking = false
    private val handler = android.os.Handler(android.os.Looper.getMainLooper())
    private val usageRunnable =
            object : Runnable {
                override fun run() {
                    if (isTracking) {
                        getForegroundApp()
                        handler.postDelayed(this, 30000) // 30 seconds poll interval
                    }
                }
            }

    fun startTracking() {
        if (!isTracking) {
            isTracking = true
            handler.post(usageRunnable)
        }
    }

    fun getForegroundApp(): String? {
        val usageStatsManager =
                context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val time = System.currentTimeMillis()

        // Check usage over the last 10 minutes
        val stats =
                usageStatsManager.queryUsageStats(
                        UsageStatsManager.INTERVAL_DAILY,
                        time - 1000 * 60 * 10,
                        time
                )

        var currentApp: String? = null
        var lastTimeUsed = 0L

        if (stats != null) {
            for (usageStats in stats) {
                if (usageStats.lastTimeUsed > lastTimeUsed) {
                    currentApp = usageStats.packageName
                    lastTimeUsed = usageStats.lastTimeUsed
                }
            }
        }

        Log.d("FATE_Telemetry", "Current foreground app might be: $currentApp")

        if (currentApp != null) {
            TelemetryEventBus.emitEvent("app_usage", mapOf("package" to currentApp))
        }

        return currentApp
    }

    fun getDailyUsageStats(): Map<String, Long> {
        val usageStatsManager =
                context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager

        val timeNow = System.currentTimeMillis()

        // Get start of today (midnight)
        val calendar = java.util.Calendar.getInstance()
        calendar.timeInMillis = timeNow
        calendar.set(java.util.Calendar.HOUR_OF_DAY, 0)
        calendar.set(java.util.Calendar.MINUTE, 0)
        calendar.set(java.util.Calendar.SECOND, 0)
        calendar.set(java.util.Calendar.MILLISECOND, 0)
        val timeStartOfDay = calendar.timeInMillis

        val stats = usageStatsManager.queryAndAggregateUsageStats(timeStartOfDay, timeNow)

        val usageMap = mutableMapOf<String, Long>()
        for ((packageName, usageStats) in stats) {
            // totalTimeInForeground includes both explicit foreground and occasionally some visible
            // background tasks depending on OS
            val durationMs = usageStats.totalTimeInForeground
            if (durationMs > 0) {
                // Convert to seconds
                usageMap[packageName] = durationMs / 1000
            }
        }

        Log.d("FATE_Telemetry", "Fetched daily usage for ${usageMap.size} apps.")
        return usageMap
    }
}
