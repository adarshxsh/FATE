package com.example.fate_app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import android.util.Log
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.example.fate_app.telemetry.*
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.ate.telemetry/channel"
    private val EVENT_CHANNEL = "com.ate.telemetry/events"
    private val LOCATION_PERMISSION_REQUEST = 1001

    private lateinit var usageManager: UsageTelemetryManager
    private lateinit var proximityManager: ProximityTelemetryManager
    private lateinit var locationManager: LocationTelemetryManager

    private var pendingUserName: String? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d("FATE_Native", "configureFlutterEngine called")

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
                    val userName = call.argument<String>("userName")
                    pendingUserName = userName
                    ensureLocationPermissionAndStart(userName)
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
                "getDailyUsage" -> {
                    try {
                        val stats = usageManager.getDailyUsageStats()
                        result.success(stats)
                    } catch (e: Exception) {
                        e.printStackTrace()
                        result.error(
                                "USAGE_FAILED",
                                "Failed to retrieve usage stats",
                                e.localizedMessage
                        )
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun ensureLocationPermissionAndStart(userName: String? = null) {
        val fineLocation =
                ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION)
        val coarseLocation =
                ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION)

        if (fineLocation == PackageManager.PERMISSION_GRANTED ||
                        coarseLocation == PackageManager.PERMISSION_GRANTED
        ) {
            // Permission already granted — start immediately
            startNativeTelemetry(userName)
        } else {
            // Request runtime permission first
            Log.d("FATE_Native", "Requesting location permission before starting FGS")
            ActivityCompat.requestPermissions(
                    this,
                    arrayOf(
                            Manifest.permission.ACCESS_FINE_LOCATION,
                            Manifest.permission.ACCESS_COARSE_LOCATION
                    ),
                    LOCATION_PERMISSION_REQUEST
            )
        }
    }

    override fun onRequestPermissionsResult(
            requestCode: Int,
            permissions: Array<out String>,
            grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == LOCATION_PERMISSION_REQUEST) {
            if (grantResults.isNotEmpty() &&
                            grantResults.any { it == PackageManager.PERMISSION_GRANTED }
            ) {
                Log.d("FATE_Native", "Location permission granted, starting FGS")
                startNativeTelemetry(pendingUserName)
            } else {
                Log.e("FATE_Native", "Location permission denied — FGS cannot start")
            }
        }
    }

    private fun startNativeTelemetry(userName: String? = null) {
        val serviceIntent = Intent(this, TelemetryForegroundService::class.java)
        serviceIntent.putExtra("userName", userName)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent)
        } else {
            startService(serviceIntent)
        }
    }
}
