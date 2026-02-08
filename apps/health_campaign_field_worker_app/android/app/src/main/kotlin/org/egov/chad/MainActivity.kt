package org.egov.chad

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Bitmap
import android.graphics.Canvas
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.PixelCopy
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.digit.location_tracker"
    private val CAPTURE_CHANNEL = "com.digit_scanner/screen_capture"
    private val locationReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val latitude = intent?.getDoubleExtra("latitude", 0.0)
            val longitude = intent?.getDoubleExtra("longitude", 0.0)
            val accuracy = intent?.getFloatExtra("accuracy", 0.0f) // Retrieve accuracy here

            // Handle the location data here
            Toast.makeText(
                context,
                "Latitude: $latitude, Longitude: $longitude, Accuracy: $accuracy",
                Toast.LENGTH_LONG
            ).show()
            // Optionally, you can send this data to Flutter via MethodChannel
            flutterEngine?.dartExecutor?.binaryMessenger?.let {
                MethodChannel(it, CHANNEL).invokeMethod(
                    "locationUpdate", mapOf(
                        "latitude" to latitude,
                        "longitude" to longitude,
                        "accuracy" to accuracy
                    )
                )
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        MethodChannel(
            flutterEngine!!.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startLocationUpdates" -> {
                    val interval = (call.argument<Number>("interval")?.toLong()) ?: 60000L
                    val stopAfterTimestamp = (call.argument<Number>("stopAfterTimestamp")?.toLong())
                        ?: (System.currentTimeMillis() + 60000L)
                    if (!isMyServiceRunning(LocationService::class.java)) {
                        startService(interval, stopAfterTimestamp)
                    } else {
                        Toast.makeText(
                            this,
                            "Location service is already running",
                            Toast.LENGTH_SHORT
                        ).show()
                    }
                    result.success(null)
                }

                "stopLocationUpdates" -> {
                    stopService()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }

        // Screen capture channel for ML Kit barcode scanning
        MethodChannel(
            flutterEngine!!.dartExecutor.binaryMessenger,
            CAPTURE_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "capture" -> captureScreen(result)
                else -> result.notImplemented()
            }
        }

        // Register the receiver for location updates, with proper export settings for Android 13+
        val filter = IntentFilter("LocationUpdate")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(locationReceiver, filter, Context.RECEIVER_EXPORTED)
        } else {
            registerReceiver(locationReceiver, filter)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        // Unregister the receiver
        unregisterReceiver(locationReceiver)
    }

    private fun startService(locationUpdateInterval: Long, stopAfterTimestamp: Long) {
        try {
            val serviceIntent = Intent(this, LocationService::class.java).apply {
                putExtra("interval", locationUpdateInterval) // Pass the interval to the service
                putExtra("stopAfterTimestamp", stopAfterTimestamp)
            }
            startService(serviceIntent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun stopService() {
        try {
            val serviceIntent = Intent(this, LocationService::class.java)
            Toast.makeText(this, "Stopping location service", Toast.LENGTH_SHORT).show()
            stopService(serviceIntent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun captureScreen(result: MethodChannel.Result) {
        try {
            val view = window.decorView.rootView
            val bitmap = Bitmap.createBitmap(view.width, view.height, Bitmap.Config.ARGB_8888)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                PixelCopy.request(window, bitmap, { copyResult ->
                    if (copyResult == PixelCopy.SUCCESS) {
                        val file = File(cacheDir, "mlkit_capture.jpg")
                        FileOutputStream(file).use { out ->
                            bitmap.compress(Bitmap.CompressFormat.JPEG, 95, out)
                        }
                        result.success(file.absolutePath)
                    } else {
                        result.error("CAPTURE_FAILED", "PixelCopy failed: $copyResult", null)
                    }
                }, Handler(Looper.getMainLooper()))
            } else {
                // Fallback for API < 26: use View.draw
                val canvas = Canvas(bitmap)
                view.draw(canvas)
                val file = File(cacheDir, "mlkit_capture.jpg")
                FileOutputStream(file).use { out ->
                    bitmap.compress(Bitmap.CompressFormat.JPEG, 95, out)
                }
                result.success(file.absolutePath)
            }
        } catch (e: Exception) {
            result.error("CAPTURE_ERROR", e.message, null)
        }
    }

    // Check if service is running
    private fun isMyServiceRunning(serviceClass: Class<*>): Boolean {
        val manager = getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
        for (service in manager.getRunningServices(Int.MAX_VALUE)) {
            if (serviceClass.name == service.service.className) {
                Toast.makeText(this, "Location service is already running", Toast.LENGTH_SHORT)
                    .show()
                return true
            }
        }
        Toast.makeText(this, "Location service starting", Toast.LENGTH_SHORT).show()
        return false
    }
}