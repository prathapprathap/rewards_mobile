package com.reward.server

import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // ANDROID_ID survives clear-data and reinstall (only a factory reset
        // changes it), unlike anything stored in SharedPreferences.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.reward.server/device")
            .setMethodCallHandler { call, result ->
                if (call.method == "getAndroidId") {
                    result.success(
                        Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID)
                    )
                } else {
                    result.notImplemented()
                }
            }
    }
}
