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

        fun startDiscovery() {
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
                                                Log.d(
                                                        "FATE_Telemetry",
                                                        "Found peer: $endpointId (${info.endpointName})"
                                                )
                                                TelemetryEventBus.emitEvent(
                                                        "peer_found",
                                                        mapOf(
                                                                "endpointId" to endpointId,
                                                                "name" to info.endpointName
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
                                android.os.Build.MODEL,
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
