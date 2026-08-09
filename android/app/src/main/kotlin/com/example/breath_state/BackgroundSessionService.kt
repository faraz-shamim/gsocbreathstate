package com.example.breath_state

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.os.PowerManager

class BackgroundSessionService : Service() {
    private var wakeLock: PowerManager.WakeLock? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> stopSelf()
            else -> startForegroundSession(intent)
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        wakeLock?.let {
            if (it.isHeld) it.release()
        }
        wakeLock = null
        super.onDestroy()
    }

    private fun startForegroundSession(intent: Intent?) {
        val reason = intent?.getStringExtra(EXTRA_REASON)
            ?: "BreathState session is running"
        val usesConnectedDevice =
            intent?.getBooleanExtra(EXTRA_CONNECTED_DEVICE, true) ?: true
        val usesMicrophone =
            intent?.getBooleanExtra(EXTRA_MICROPHONE, false) ?: false

        ensureNotificationChannel()
        val notification = buildNotification(reason)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            var foregroundType = 0
            if (usesConnectedDevice) {
                foregroundType =
                    foregroundType or ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE
            }
            if (usesMicrophone) {
                foregroundType =
                    foregroundType or ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
            }

            if (foregroundType == 0) {
                startForeground(NOTIFICATION_ID, notification)
            } else {
                startForeground(NOTIFICATION_ID, notification, foregroundType)
            }
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        acquireWakeLock()
    }

    private fun buildNotification(reason: String): Notification {
        val builder =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(this, CHANNEL_ID)
            } else {
                @Suppress("DEPRECATION")
                Notification.Builder(this)
            }

        return builder
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("BreathState is active")
            .setContentText(reason)
            .setOngoing(true)
            .setCategory(Notification.CATEGORY_SERVICE)
            .build()
    }

    private fun ensureNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            "Active sessions",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Keeps BreathState recordings running in the background."
            setShowBadge(false)
        }

        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)
    }

    private fun acquireWakeLock() {
        if (wakeLock?.isHeld == true) return

        val powerManager = getSystemService(PowerManager::class.java)
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "BreathState:ActiveSession",
        ).apply {
            setReferenceCounted(false)
            acquire()
        }
    }

    companion object {
        const val ACTION_START = "com.example.breath_state.action.START_BACKGROUND_SESSION"
        const val ACTION_STOP = "com.example.breath_state.action.STOP_BACKGROUND_SESSION"
        const val EXTRA_REASON = "reason"
        const val EXTRA_CONNECTED_DEVICE = "usesConnectedDevice"
        const val EXTRA_MICROPHONE = "usesMicrophone"

        private const val CHANNEL_ID = "breath_state_active_sessions"
        private const val NOTIFICATION_ID = 4307
    }
}
