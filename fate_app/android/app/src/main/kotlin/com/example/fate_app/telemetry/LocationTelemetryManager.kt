package com.example.fate_app.telemetry

import android.annotation.SuppressLint
import android.content.Context
import android.os.Looper
import android.util.Log
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority

class LocationTelemetryManager(private val context: Context) {
    private val fusedLocationClient = LocationServices.getFusedLocationProviderClient(context)

    @SuppressLint("MissingPermission")
    fun startLocationUpdates() {
        // ── Immediate fetch on app open ──
        // Emit the last cached location right away so the UI shows a zone
        // without waiting for the first 2-minute poll.
        fusedLocationClient.lastLocation.addOnSuccessListener { location ->
            if (location != null) {
                Log.d(
                        "FATE_Telemetry",
                        "Startup location: ${location.latitude}, ${location.longitude}"
                )
                TelemetryEventBus.emitEvent(
                        "location_update",
                        mapOf("lat" to location.latitude, "lng" to location.longitude)
                )
            }
        }

        // ── Periodic poll every 2 minutes ──
        val locationRequest =
                LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, 120000)
                        .setMinUpdateIntervalMillis(120000)
                        .build()

        fusedLocationClient.requestLocationUpdates(
                locationRequest,
                object : LocationCallback() {
                    override fun onLocationResult(p0: LocationResult) {
                        val location = p0.lastLocation
                        if (location != null) {
                            Log.d(
                                    "FATE_Telemetry",
                                    "Location update: ${location.latitude}, ${location.longitude}"
                            )
                            TelemetryEventBus.emitEvent(
                                    "location_update",
                                    mapOf("lat" to location.latitude, "lng" to location.longitude)
                            )
                        }
                    }
                },
                Looper.getMainLooper()
        )
    }
}
