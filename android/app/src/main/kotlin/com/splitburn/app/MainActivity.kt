package com.splitburn.app

import android.content.ComponentName
import android.content.Intent
import android.os.Build
import android.provider.Settings
import com.splitburn.app.capture.UpiNotificationListener
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CAPTURE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isUpiCaptureEnabled" -> result.success(isCaptureEnabled())
                    "openUpiCaptureSettings" -> {
                        startActivity(captureSettingsIntent())
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private val listenerComponent: ComponentName
        get() = ComponentName(this, UpiNotificationListener::class.java)

    /** Whether the user granted notification access to the UPI listener. */
    private fun isCaptureEnabled(): Boolean {
        val enabled = Settings.Secure.getString(contentResolver, ENABLED_LISTENERS_SETTING)
            ?: return false
        return enabled.split(':')
            .mapNotNull(ComponentName::unflattenFromString)
            .any { it == listenerComponent }
    }

    /** Opens the toggle for this listener directly on Android 11+. */
    private fun captureSettingsIntent(): Intent =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Intent(Settings.ACTION_NOTIFICATION_LISTENER_DETAIL_SETTINGS).putExtra(
                Settings.EXTRA_NOTIFICATION_LISTENER_COMPONENT_NAME,
                listenerComponent.flattenToString(),
            )
        } else {
            Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        }

    private companion object {
        const val CAPTURE_CHANNEL = "com.splitburn.app/capture"
        const val ENABLED_LISTENERS_SETTING = "enabled_notification_listeners"
    }
}
