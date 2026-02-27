package com.example.fate_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import android.os.Handler
import android.os.Looper
import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.os.Process
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.util.UUID

class MainActivity : FlutterActivity() {
    private val TELEMETRY_CHANNEL = "com.ate.telemetry/channel"
    private val COMMAND_CHANNEL = "com.ate.telemetry/commands"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Method Channel for Commands
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, COMMAND_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestUsagePermissions" -> {
                    val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                    startActivity(intent)
                    result.success(null)
                }
                "requestNotificationPermissions" -> {
                    val intent = Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS")
                    startActivity(intent)
                    result.success(null)
                }
                "checkAllPermissions" -> {
                    result.success(hasUsageStatsPermission())
                }
                else -> result.notImplemented()
            }
        }
        
        // Event Channel for Telemetry
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, TELEMETRY_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                private var handler: Handler? = null
                private var runnable: Runnable? = null

                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    handler = Handler(Looper.getMainLooper())
                    runnable = object : Runnable {
                        override fun run() {
                            val activeApp = getActiveAppPackageName()
                            val data = mapOf(
                                "id" to UUID.randomUUID().toString(),
                                "timestamp" to System.currentTimeMillis(),
                                "eventType" to "active_session",
                                "packageName" to (activeApp ?: "com.fate.app"),
                                "category" to (if (activeApp == "com.fate.app") "CORE" else "OTHER"),
                                "durationSec" to 2
                            )
                            
                            events?.success(data)
                            handler?.postDelayed(this, 2000)
                        }
                    }
                    handler?.post(runnable!!)
                }

                override fun onCancel(arguments: Any?) {
                    handler?.removeCallbacks(runnable!!)
                    handler = null
                    runnable = null
                }
            }
        )
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun getActiveAppPackageName(): String? {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val endTime = System.currentTimeMillis()
        val startTime = endTime - 1000 * 60 // Last 1 minute
        
        val usageEvents = usageStatsManager.queryEvents(startTime, endTime)
        var activePackage: String? = null
        val event = UsageEvents.Event()
        
        while (usageEvents.hasNextEvent()) {
            usageEvents.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND) {
                activePackage = event.packageName
            }
        }
        
        return activePackage
    }
}

