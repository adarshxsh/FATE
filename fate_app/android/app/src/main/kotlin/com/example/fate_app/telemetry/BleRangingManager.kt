package com.example.fate_app.telemetry

import android.annotation.SuppressLint
import android.bluetooth.BluetoothManager
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
import android.os.SystemClock
import android.util.Log
import java.util.UUID

/**
 * Signal-strength ranging between FATE phones.
 *
 * Nearby Connections finds peers but exposes no RSSI. Wi-Fi RSSI is measured
 * against access points, not other phones, so it can't range peer-to-peer
 * either. This manager runs a small BLE beacon alongside Nearby:
 *
 *   advert service data (9 bytes) = bleId (8 bytes) | measuredPowerAt1m (int8 dBm)
 *
 * and scans for the same service UUID. Each sighting is sent to Dart as raw
 * RSSI. Smoothing and the path-loss distance model live in Dart
 * (lib/logic/rssi_ranging.dart) so they're unit-tested in CI.
 */
class BleRangingManager(private val context: Context) {
    companion object {
        private const val TAG = "FATE_BLE"
        val SERVICE_UUID: ParcelUuid =
            ParcelUuid(UUID.fromString("6c0f3a1e-3f6b-4a8e-9a57-fa7e00000001"))

        /**
         * RSSI at 1 m, in dBm. -59 is the common iBeacon reference for phones at
         * TX_POWER_MEDIUM. Real handsets vary by about ±6 dB because of antenna and
         * case, which is why the reference is broadcast in the packet: a device that
         * gets calibrated later can advertise its own value without receivers changing.
         */
        const val DEFAULT_MEASURED_POWER_1M: Int = -59

        /** Per-peer emit throttle: the Kalman filter on the Dart side needs a steady stream, not a flood. */
        private const val MIN_EMIT_INTERVAL_MS = 1000L
    }

    private val adapter get() =
        (context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager)?.adapter
    private val lastEmit = HashMap<String, Long>()
    private val main = Handler(Looper.getMainLooper())
    private var running = false

    private val advertiseCallback = object : AdvertiseCallback() {
        override fun onStartSuccess(settingsInEffect: AdvertiseSettings) {
            Log.d(TAG, "Advertising (txPowerLevel=${settingsInEffect.txPowerLevel})")
        }
        override fun onStartFailure(errorCode: Int) {
            Log.e(TAG, "Advertise failed: $errorCode")
        }
    }

    private val scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult) = handle(result)
        override fun onBatchScanResults(results: MutableList<ScanResult>) = results.forEach(::handle)
        override fun onScanFailed(errorCode: Int) {
            Log.e(TAG, "Scan failed: $errorCode")
        }
    }

    /** @param bleIdHex the 16-hex-char id the app generated (also in the Nearby name). */
    @SuppressLint("MissingPermission") // granted from Settings; SecurityException is caught
    fun start(bleIdHex: String?) {
        if (running) return
        val id = bleIdHex?.let(::hexToBytes)
        val bt = adapter
        if (bt == null || !bt.isEnabled) {
            Log.w(TAG, "Bluetooth unavailable/off; ranging disabled")
            return
        }
        try {
            if (id != null && id.size == 8) {
                val payload = id + byteArrayOf(DEFAULT_MEASURED_POWER_1M.toByte())
                bt.bluetoothLeAdvertiser?.startAdvertising(
                    AdvertiseSettings.Builder()
                        .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_BALANCED)
                        .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_MEDIUM)
                        .setConnectable(false)
                        .build(),
                    AdvertiseData.Builder()
                        .setIncludeDeviceName(false) // 31-byte budget: 16B UUID + 9B data
                        .setIncludeTxPowerLevel(false)
                        .addServiceData(SERVICE_UUID, payload)
                        .build(),
                    advertiseCallback,
                )
            } else {
                Log.w(TAG, "No valid bleId; scanning only")
            }
            bt.bluetoothLeScanner?.startScan(
                listOf(ScanFilter.Builder().setServiceData(SERVICE_UUID, ByteArray(0), ByteArray(0)).build()),
                ScanSettings.Builder()
                    .setScanMode(ScanSettings.SCAN_MODE_BALANCED)
                    .setCallbackType(ScanSettings.CALLBACK_TYPE_ALL_MATCHES)
                    .build(),
                scanCallback,
            )
            running = true
        } catch (e: SecurityException) {
            Log.e(TAG, "Missing BLUETOOTH_SCAN/ADVERTISE permission", e)
        }
    }

    @SuppressLint("MissingPermission")
    fun stop() {
        if (!running) return
        try {
            adapter?.bluetoothLeScanner?.stopScan(scanCallback)
            adapter?.bluetoothLeAdvertiser?.stopAdvertising(advertiseCallback)
        } catch (e: SecurityException) {
            Log.e(TAG, "stop failed", e)
        }
        running = false
    }

    private fun handle(result: ScanResult) {
        val data = result.scanRecord?.getServiceData(SERVICE_UUID) ?: return
        if (data.size < 9) return
        val bleId = data.copyOfRange(0, 8).joinToString("") { "%02x".format(it) }
        val measuredPower = data[8].toInt() // signed int8
        val now = SystemClock.elapsedRealtime()
        if (now - (lastEmit[bleId] ?: 0L) < MIN_EMIT_INTERVAL_MS) return
        lastEmit[bleId] = now
        main.post {
            TelemetryEventBus.emitEvent(
                "ble_rssi",
                mapOf("bleId" to bleId, "rssi" to result.rssi, "measuredPower" to measuredPower),
            )
        }
    }

    private fun hexToBytes(hex: String): ByteArray? {
        if (hex.length % 2 != 0 || !hex.all { it.isDigit() || it.lowercaseChar() in 'a'..'f' }) return null
        return ByteArray(hex.length / 2) { i -> hex.substring(2 * i, 2 * i + 2).toInt(16).toByte() }
    }
}
