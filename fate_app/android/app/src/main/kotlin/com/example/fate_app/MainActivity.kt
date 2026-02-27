package com.example.fate_app

import android.content.Intent
import android.provider.Settings
import androidx.annotation.NonNull
import com.example.fate_app.telemetry.*
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.ate.telemetry/channel"
    private val EVENT_CHANNEL = "com.ate.telemetry/events"

    private lateinit var usageManager: UsageTelemetryManager
    private lateinit var proximityManager: ProximityTelemetryManager
    private lateinit var locationManager: LocationTelemetryManager

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        android.util.Log.d("FATE_Native", "configureFlutterEngine called")

        usageManager = UsageTelemetryManager(context)
        proximityManager = ProximityTelemetryManager(context)
        locationManager = LocationTelemetryManager(context)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
                .setStreamHandler(
                        object : EventChannel.StreamHandler {
                            override fun onListen(
                                    arguments: Any?,
                                    events: EventChannel.EventSink?
                            ) {
                                if (events != null) {
                                    TelemetryEventBus.setSink(events)
                                }
                            }

                            override fun onCancel(arguments: Any?) {
                                TelemetryEventBus.setSink(null)
                            }
                        }
                )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call,
                result ->
            when (call.method) {
                "startTelemetry" -> {
                    startNativeTelemetry()
                    result.success("Telemetry started.")
                }
                "requestUsagePermission" -> {
                    startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                    result.success(null)
                }
                "requestNotificationPermission" -> {
                    startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startNativeTelemetry() {
        try {
            usageManager.startTracking()
        } catch (e: Exception) {
            e.printStackTrace()
        }

        try {
            locationManager.startLocationUpdates()
        } catch (e: Exception) {
            e.printStackTrace()
        }

        try {
            proximityManager.startDiscovery()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
