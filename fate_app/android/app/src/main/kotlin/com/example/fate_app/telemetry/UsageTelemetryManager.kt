package com.example.fate_app.telemetry

import android.app.usage.UsageStatsManager
import android.content.Context
import android.util.Log

class UsageTelemetryManager(private val context: Context) {

    fun getForegroundApp(): String? {
        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val time = System.currentTimeMillis()
        
        // Check usage over the last 10 minutes
        val stats = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, time - 1000 * 60 * 10, time)
        
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
        return currentApp
    }
}
