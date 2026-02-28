package com.example.fate_app.telemetry

import io.flutter.plugin.common.EventChannel

object TelemetryEventBus {
    private var eventSink: EventChannel.EventSink? = null

    fun setSink(sink: EventChannel.EventSink?) {
        eventSink = sink
    }

    fun emitEvent(type: String, data: Map<String, Any>) {
        val payload = mapOf(
            "type" to type,
            "data" to data,
            "timestamp" to System.currentTimeMillis()
        )
        // Ensure UI thread if needed, but Flutter EventSink handles it usually.
        eventSink?.success(payload)
    }

    fun emitError(code: String, message: String, details: Any?) {
        eventSink?.error(code, message, details)
    }
}
