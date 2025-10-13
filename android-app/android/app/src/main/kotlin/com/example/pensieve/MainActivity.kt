package com.example.pensieve

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.pensieve/deeplink"
    private var initialLink: String? = null
    private val TAG = "pensieve"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        val action = intent?.action
        val data: Uri? = intent?.data

        if (action == Intent.ACTION_VIEW && data != null) {
            // Gestisce i deep links dai widget
            try {
                val host = data.host
                Log.d(TAG, "handleIntent: received deep link host=$host")

                // Only accept deep links coming from widget PendingIntent
                var fromWidget = false
                try {
                    val extras = intent?.extras
                    if (extras != null) {
                        val obj = extras.get("from_widget")
                        when (obj) {
                            is Boolean -> fromWidget = obj
                            is String -> fromWidget = obj.equals("true", ignoreCase = true)
                            else -> fromWidget = extras.getBoolean("from_widget", false)
                        }
                    }
                } catch (e: Exception) {
                    Log.w(TAG, "handleIntent: error reading from_widget extra", e)
                }
                Log.d(TAG, "handleIntent: fromWidget=$fromWidget")

                if (!fromWidget) {
                    Log.d(TAG, "handleIntent: ignoring deep link since not from widget")
                    return
                }

                if (initialLink == null) {
                    when (host) {
                        "camera" -> initialLink = "/camera"
                        "audio" -> initialLink = "/audio"
                        else -> initialLink = data.toString()
                    }
                    Log.d(TAG, "handleIntent: initialLink set=$initialLink")
                } else {
                    Log.d(TAG, "handleIntent: initialLink already set=$initialLink, ignoring new link")
                }
            } catch (e: Exception) {
                Log.w(TAG, "handleIntent: error parsing deep link", e)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialLink" -> {
                    Log.d(TAG, "MethodChannel getInitialLink called, returning=$initialLink")
                    result.success(initialLink)
                    initialLink = null // Reset after sending
                }
                else -> result.notImplemented()
            }
        }
    }
}
 
