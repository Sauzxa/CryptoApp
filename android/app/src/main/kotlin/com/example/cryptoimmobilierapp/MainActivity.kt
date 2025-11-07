package com.example.cryptoimmobilierapp

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.os.Bundle

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.cryptoimmobilierapp/notification"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialNotification" -> {
                    val notificationData = getNotificationData(intent)
                    result.success(notificationData)
                }
                else -> result.notImplemented()
            }
        }
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleNotificationIntent(intent)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleNotificationIntent(intent)
    }
    
    private fun handleNotificationIntent(intent: Intent?) {
        intent?.let {
            if (it.hasExtra("notification_data")) {
                // Notification tap detected, Flutter will handle via MethodChannel
            }
        }
    }
    
    private fun getNotificationData(intent: Intent?): Map<String, String>? {
        intent?.extras?.let { bundle ->
            val map = mutableMapOf<String, String>()
            for (key in bundle.keySet()) {
                val value = bundle.get(key)
                if (value is String) {
                    map[key] = value
                }
            }
            return if (map.isNotEmpty()) map else null
        }
        return null
    }
}
