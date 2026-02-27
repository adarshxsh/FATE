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
        val discoveryOptions = DiscoveryOptions.Builder().setStrategy(Strategy.P2P_STAR).build()

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
                                        "Found peer: \$endpointId (\${info.endpointName})"
                                )
                                TelemetryEventBus.emitEvent(
                                        "peer_found",
                                        mapOf("endpointId" to endpointId)
                                )
                            }

                            override fun onEndpointLost(endpointId: String) {
                                Log.d("FATE_Telemetry", "Lost peer: \$endpointId")
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
}
