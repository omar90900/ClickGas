package com.clickgas.app

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Wallet payments: opens the customer's wallet app by package name.
        // Answers false when it isn't installed, so Dart can open the store.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "clickgas/apps")
            .setMethodCallHandler { call, result ->
                if (call.method != "open") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val intent = call.argument<String>("package")
                    ?.let { packageManager.getLaunchIntentForPackage(it) }
                if (intent == null) {
                    result.success(false)
                } else {
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(true)
                }
            }
    }
}
