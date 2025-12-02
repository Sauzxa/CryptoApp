package com.example.cryptoimmobilierapp

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class MyFirebaseMessagingService : FirebaseMessagingService() {

    companion object {
        private const val TAG = "FCMService"
        private const val CHANNEL_ID = "reservation_notifications"
        private const val CHANNEL_NAME = "Reservation Notifications"
        private const val NOTIFICATION_GROUP = "com.example.cryptoimmobilierapp.NOTIFICATIONS"
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d(TAG, "New FCM token: $token")
        // Token will be sent to backend by Flutter code
    }

    override fun onMessageReceived(message: RemoteMessage) {
        super.onMessageReceived(message)
        
        Log.d(TAG, "Message received from: ${message.from}")
        Log.d(TAG, "Message data: ${message.data}")
        
        // Handle notification
        message.notification?.let { notification ->
            Log.d(TAG, "Notification title: ${notification.title}")
            Log.d(TAG, "Notification body: ${notification.body}")
            
            sendNotification(
                title = notification.title ?: "Notification",
                body = notification.body ?: "",
                data = message.data
            )
        }
        
        // Handle data-only messages
        if (message.data.isNotEmpty()) {
            Log.d(TAG, "Message data payload: ${message.data}")
            
            // If there's no notification, create one from data
            if (message.notification == null) {
                val title = message.data["title"] ?: "New Notification"
                val body = message.data["body"] ?: ""
                sendNotification(title, body, message.data)
            }
        }
    }

    private fun sendNotification(
        title: String,
        body: String,
        data: Map<String, String>
    ) {
        // Create notification channel (required for Android 8.0+)
        createNotificationChannel()
        
        // Generate a stable notification ID based on type and reservation ID
        // This prevents duplicate notifications for the same event
        val type = data["type"] ?: "default"
        val reservationId = data["reservationId"] ?: ""
        val notificationId = if (reservationId.isNotEmpty()) {
            // Use reservation ID hash for reservation-related notifications
            (type + reservationId).hashCode()
        } else {
            // Use type hash for other notifications
            type.hashCode()
        }
        
        // Create intent for notification tap
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            // Add notification data to intent
            data.forEach { (key, value) ->
                putExtra(key, value)
            }
            putExtra("notification_data", "true")
        }
        
        val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        
        // Use notificationId as requestCode to update the same PendingIntent
        val pendingIntent = PendingIntent.getActivity(
            this,
            notificationId,
            intent,
            pendingIntentFlags
        )
        
        // Build notification with grouping
        val notificationBuilder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(body)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pendingIntent)
            .setColor(resources.getColor(R.color.notification_color, null))
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setGroup(NOTIFICATION_GROUP)
            .setWhen(System.currentTimeMillis())
            .setShowWhen(true)
        
        // Show notification
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(notificationId, notificationBuilder.build())
        
        Log.d(TAG, "Notification sent with ID $notificationId: $title (type: $type, reservationId: $reservationId)")
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = CHANNEL_ID
            val channelName = CHANNEL_NAME
            val importance = NotificationManager.IMPORTANCE_HIGH
            
            val channel = NotificationChannel(channelId, channelName, importance).apply {
                description = "Notifications for reservations and appointments"
                enableLights(true)
                enableVibration(true)
                setShowBadge(true)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
            
            // Create additional channels
            createAdditionalChannels(notificationManager)
        }
    }
    
    private fun createAdditionalChannels(notificationManager: NotificationManager) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channels = listOf(
                NotificationChannel(
                    "agent_availability",
                    "Agent Availability",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Notifications for agent availability updates"
                    enableLights(true)
                    enableVibration(true)
                },
                NotificationChannel(
                    "messages",
                    "Messages",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Notifications for new messages"
                    enableLights(true)
                    enableVibration(true)
                },
                NotificationChannel(
                    "reminders",
                    "Reminders",
                    NotificationManager.IMPORTANCE_DEFAULT
                ).apply {
                    description = "Availability and calendar reminders"
                    enableVibration(true)
                }
            )
            
            channels.forEach { channel ->
                notificationManager.createNotificationChannel(channel)
            }
        }
    }
}
