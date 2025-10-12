package com.example.rocket_notes_ai

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.rocket_notes_ai/deeplink"
    private var initialLink: String? = null

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
            when (data.host) {
                "camera" -> {
                    initialLink = "/camera"
                }
                "audio" -> {
                    initialLink = "/audio"
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialLink" -> {
                    result.success(initialLink)
                    initialLink = null // Reset after sending
                }
                else -> result.notImplemented()
            }
        }
    }
}
