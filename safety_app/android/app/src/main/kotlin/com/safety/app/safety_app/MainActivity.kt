package com.safety.app.safety_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.safety.app/trigger"
    private var methodChannel: MethodChannel? = null
    
    // Hardware trigger variables
    private var powerButtonPressCount = 0
    private var lastPowerButtonPressTime: Long = 0
    private val POWER_BUTTON_TIME_WINDOW: Long = 2000 // 2 seconds

    private val powerButtonReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == Intent.ACTION_SCREEN_ON || intent?.action == Intent.ACTION_SCREEN_OFF) {
                val currentTime = System.currentTimeMillis()
                
                if (currentTime - lastPowerButtonPressTime > POWER_BUTTON_TIME_WINDOW) {
                    powerButtonPressCount = 1
                } else {
                    powerButtonPressCount++
                }
                
                lastPowerButtonPressTime = currentTime
                
                if (powerButtonPressCount >= 3) {
                    // Trigger emergency
                    powerButtonPressCount = 0
                    methodChannel?.invokeMethod("triggerEmergency", null)
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
        }
        registerReceiver(powerButtonReceiver, filter)
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterReceiver(powerButtonReceiver)
    }
}
