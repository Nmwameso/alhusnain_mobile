package com.alhusnain.ah_customer

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

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        Log.d("FCM", "🔔 Message received: ${remoteMessage.notification?.title}")

        remoteMessage.notification?.let {
            showNotification(it.title ?: "New Notification", it.body ?: "You have a new message.", remoteMessage.data)
        }
    }

    override fun onNewToken(token: String) {
        Log.d("FCM", "🔄 New token: $token")
        sendTokenToServer(token)
    }

    /**
     * ✅ Send the new FCM token to your backend server
     */
    private fun sendTokenToServer(token: String) {
        // TODO: Implement API call to send `token` to your backend
        Log.d("FCM", "📡 Token sent to server: $token")
    }

    /**
     * ✅ Show a local notification when an FCM message is received
     */
    private fun showNotification(title: String, message: String, data: Map<String, String>) {
        val channelId = "vehicle_updates_channel"
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // ✅ Create notification channel for Android 8+ (Oreo)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Vehicle Updates",
                NotificationManager.IMPORTANCE_HIGH
            )
            notificationManager.createNotificationChannel(channel)
        }

        // ✅ Create an Intent to open `VehicleDetailsScreen` when tapped
        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra("vehicle_id", data["vehicle_id"]) // Pass vehicle_id for navigation
        }

        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // ✅ Build the notification
        val notificationBuilder = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.drawable.ic_notification) // Replace with your notification icon
            .setContentTitle(title)
            .setContentText(message)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pendingIntent)

        // ✅ Show the notification
        notificationManager.notify(0, notificationBuilder.build())
    }
}
