package com.geocrime.geocrime_app

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.geocrime.geocrime_app/widget"
    private var triggerSosPending = false
    private var methodChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent != null && "com.geocrime.geocrime_app.ACTION_TRIGGER_SOS" == intent.action) {
            triggerSosPending = true
            // If the Flutter engine is already running, send the event immediately
            methodChannel?.invokeMethod("triggerSos", null)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "getLaunchIntentAction" -> {
                        if (triggerSosPending) {
                            triggerSosPending = false
                            result.success("trigger_sos")
                        } else {
                            result.success(null)
                        }
                    }
                    "resetLaunchIntentAction" -> {
                        triggerSosPending = false
                        result.success(null)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
        }
    }
}
