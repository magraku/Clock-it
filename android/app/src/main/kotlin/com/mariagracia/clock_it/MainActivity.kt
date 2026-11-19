package com.mariagracia.clock_it

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "clockit/focus").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "status" -> result.success(FocusMode.status(this))
                    "enable" -> { FocusMode.enable(this, call.arguments == true); result.success(null) }
                    "sync" -> {
                        FocusMode.sync(this, (call.arguments as? List<*>)?.mapNotNull { (it as? Number)?.toLong() } ?: emptyList())
                        result.success(null)
                    }
                    "requestAccess" -> { FocusMode.requestAccess(this); result.success(null) }
                    else -> result.notImplemented()
                }
            } catch (e: RuntimeException) {
                result.error("focus_unavailable", "Focus settings are unavailable on this device", null)
            }
        }
    }

    override fun onResume() {
        super.onResume()
        FocusMode.reconcile(this)
    }
}
