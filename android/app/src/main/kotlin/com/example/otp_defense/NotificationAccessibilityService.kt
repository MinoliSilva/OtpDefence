package com.example.otp_defense

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.app.Notification
import android.content.Context
import android.os.Bundle
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class NotificationAccessibilityService : AccessibilityService() {

    private val CHANNEL = "com.example.otp_defense/accessibility"
    private var methodChannel: MethodChannel? = null

    override fun onServiceConnected() {
        super.onServiceConnected()
        val info = AccessibilityServiceInfo()
        info.eventTypes = AccessibilityEvent.TYPE_NOTIFICATION_STATE_CHANGED
        info.feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
        info.flags = AccessibilityServiceInfo.DEFAULT
        
        // Let's filter to only messaging/SMS apps if needed, but for now we listen to all notifications
        // and filter inside Flutter to check for OTP patterns.
        this.serviceInfo = info

        Log.d("AccessibilityService", "Notification Accessibility Service Connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null || event.eventType != AccessibilityEvent.TYPE_NOTIFICATION_STATE_CHANGED) {
            return
        }

        val eventPackageName = event.packageName?.toString() ?: ""
        // Filter out our own notifications to avoid loops
        if (eventPackageName == this.packageName) return

        val textList = event.text
        if (textList.isNullOrEmpty()) return

        val notificationText = textList.joinToString(" ")
        
        var title = ""
        val messages = mutableListOf<String>()

        val notification = event.parcelableData
        if (notification is Notification) {
            val extras = notification.extras
            // Try to get title from extras (usually the sender identity)
            title = extras.getString(Notification.EXTRA_TITLE) 
                ?: extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()
                ?: eventPackageName

            // Advanced message extraction from various notification styles
            val textLines = extras.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)
            if (textLines != null && textLines.isNotEmpty()) {
                for (line in textLines) {
                    if (line != null) messages.add(line.toString())
                }
            } else {
                val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)
                if (bigText != null) {
                    messages.add(bigText.toString())
                } else {
                    val text = extras.getCharSequence(Notification.EXTRA_TEXT) ?: extras.getCharSequence(Notification.EXTRA_INFO_TEXT)
                    if (text != null) {
                        messages.add(text.toString())
                    } else {
                        messages.add(notificationText)
                    }
                }
            }
        } else {
            title = eventPackageName
            messages.add(notificationText)
        }

        // Clean up title if it contains numeric sender
        var cleanTitle = title.replace(Regex("[^a-zA-Z0-9 ]"), "").take(20).trim()

        // If the parsed title seems to just be the package name, try to extract sender from message body prefix
        if (title.contains(eventPackageName) || cleanTitle.lowercase() == eventPackageName.replace(Regex("[^a-zA-Z0-9]"), "").take(20).trim().lowercase()) {
            val firstMessage = messages.firstOrNull()
            if (firstMessage != null && firstMessage.contains(":")) {
                val possibleSender = firstMessage.substringBefore(":")
                // If it's a reasonably short string without too many special characters, use it as sender
                if (possibleSender.length in 2..25) {
                    cleanTitle = possibleSender.trim()
                }
            }
        }

        Log.d("AccessibilityService", "Notification from: $cleanTitle | Content available: ${messages.joinToString(", ")}")

        // Send to Flutter for analysis
        sendToFlutter(cleanTitle, messages)
    }

    override fun onInterrupt() {
        Log.e("AccessibilityService", "Service Interrupted")
    }

    private fun sendToFlutter(sender: String, messages: List<String>) {
        val engine = FlutterEngineCache.getInstance().get("otp_defense_engine")
        if (engine != null) {
            if (methodChannel == null) {
                methodChannel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            }
            val data = mapOf(
                "sender" to sender,
                "messages" to messages
            )
            methodChannel?.invokeMethod("onNotificationReceived", data)
            Log.d("AccessibilityService", "Successfully dispatched to Flutter engine")
        } else {
            // This is the common failure point when app is killed
            Log.w("AccessibilityService", "Flutter Engine Cache is empty! Event dropped. Background scanning may be compromised.")
            // TODO (Optional): We could potentially restart the engine here if needed
        }
    }
}
