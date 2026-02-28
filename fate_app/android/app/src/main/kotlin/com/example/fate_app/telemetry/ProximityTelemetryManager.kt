package com.example.fate_app.telemetry

import android.content.Context
import android.util.Log
import com.google.android.gms.nearby.Nearby
import com.google.android.gms.nearby.connection.DiscoveredEndpointInfo
import com.google.android.gms.nearby.connection.DiscoveryOptions
import com.google.android.gms.nearby.connection.EndpointDiscoveryCallback
import com.google.android.gms.nearby.connection.Strategy

class ProximityTelemetryManager(private val context: Context) {
        private val SERVICE_ID = "com.example.fate_app.SERVICE_ID"
        private var currentUserName: String = android.os.Build.MODEL

        fun startDiscovery(userName: String? = null) {
                val model = android.os.Build.MODEL
                currentUserName = if (userName != null) "$userName|$model" else "Unknown|$model"
                startAdvertising() // Be discoverable while searching
                val discoveryOptions =
                        DiscoveryOptions.Builder().setStrategy(Strategy.P2P_STAR).build()

                Nearby.getConnectionsClient(context)
                        .startDiscovery(
                                SERVICE_ID,
                                object : EndpointDiscoveryCallback() {
                                        override fun onEndpointFound(
                                                endpointId: String,
                                                info: DiscoveredEndpointInfo
                                        ) {
                                                // RSSI is not directly available in standard Nearby
                                                // Connections discovery,
                                                // but we can estimate it or categorize it if using
                                                // BLE.
                                                // Simulated distance logic
                                                // Real RSSI distance logic: 10^((MeasuredPower -
                                                // RSSI) / (10 * N))
                                                val estimatedDistance =
                                                        (0.5 + Math.random() * 4.5).let {
                                                                Math.round(it * 10.0) / 10.0
                                                        }

                                                Log.d(
                                                        "FATE_Telemetry",
                                                        "Found peer: $endpointId (${info.endpointName}) at ~${estimatedDistance}m"
                                                )
                                                TelemetryEventBus.emitEvent(
                                                        "peer_found",
                                                        mapOf(
                                                                "endpointId" to endpointId,
                                                                "name" to info.endpointName,
                                                                "distance" to estimatedDistance
                                                        )
                                                )
                                        }

                                        override fun onEndpointLost(endpointId: String) {
                                                Log.d("FATE_Telemetry", "Lost peer: $endpointId")
                                                TelemetryEventBus.emitEvent(
                                                        "peer_lost",
                                                        mapOf("endpointId" to endpointId)
                                                )
                                        }
                                },
                                discoveryOptions
                        )
                        .addOnSuccessListener { Log.d("FATE_Telemetry", "Discovery started") }
                        .addOnFailureListener { Log.e("FATE_Telemetry", "Discovery failed", it) }
        }

        private fun startAdvertising() {
                val advertisingOptions =
                        com.google.android.gms.nearby.connection.AdvertisingOptions.Builder()
                                .setStrategy(Strategy.P2P_STAR)
                                .build()

                Nearby.getConnectionsClient(context)
                        .startAdvertising(
                                currentUserName,
                                SERVICE_ID,
                                object :
                                        com.google.android.gms.nearby.connection.ConnectionLifecycleCallback() {
                                        override fun onConnectionInitiated(
                                                endpointId: String,
                                                connectionInfo:
                                                        com.google.android.gms.nearby.connection.ConnectionInfo
                                        ) {
                                                // Automatically accept connection
                                                Nearby.getConnectionsClient(context)
                                                        .acceptConnection(
                                                                endpointId,
                                                                object :
                                                                        com.google.android.gms.nearby.connection.PayloadCallback() {
                                                                        override fun onPayloadReceived(
                                                                                endpointId: String,
                                                                                payload:
                                                                                        com.google.android.gms.nearby.connection.Payload
                                                                        ) {}
                                                                        override fun onPayloadTransferUpdate(
                                                                                endpointId: String,
                                                                                update:
                                                                                        com.google.android.gms.nearby.connection.PayloadTransferUpdate
                                                                        ) {}
                                                                }
                                                        )
                                        }
                                        override fun onConnectionResult(
                                                endpointId: String,
                                                result:
                                                        com.google.android.gms.nearby.connection.ConnectionResolution
                                        ) {}
                                        override fun onDisconnected(endpointId: String) {}
                                },
                                advertisingOptions
                        )
                        .addOnSuccessListener { Log.d("FATE_Telemetry", "Advertising started") }
                        .addOnFailureListener { Log.e("FATE_Telemetry", "Advertising failed", it) }
        }
}
