package com.traftai.lumina

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import run.Run

class PhotoSyncService : Service() {
    companion object {
        const val CHANNEL_ID = "photo_sync_channel"
        const val NOTIFICATION_ID = 1001
        const val ACTION_STOP = "com.traftai.lumina.STOP_SYNC"

        @Volatile
        var isRunning = false
            private set
    }

    private var flutterEngine: FlutterEngine? = null
    private var wakeLock: PowerManager.WakeLock? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopSelf()
            return START_NOT_STICKY
        }

        isRunning = true
        startForeground(NOTIFICATION_ID, buildNotification("Starting photo sync..."))
        acquireWakeLock()
        startFlutterEngine()
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        isRunning = false
        releaseWakeLock()
        flutterEngine?.destroy()
        flutterEngine = null
        super.onDestroy()
    }

    private fun startFlutterEngine() {
        val engine = FlutterEngine(this)
        flutterEngine = engine

        val channel = MethodChannel(
            engine.dartExecutor.binaryMessenger,
            "com.traftai.lumina/BackgroundSync"
        )

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "RunGrpcServer" -> {
                    val dataDir = call.argument<String>("dataDir") ?: ""
                    val cacheDir = call.argument<String>("cacheDir") ?: ""
                    val re = Run.runGrpcServer(dataDir, cacheDir)
                    result.success(re)
                }
                "updateNotification" -> {
                    val total = call.argument<Int>("total") ?: 0
                    val completed = call.argument<Int>("completed") ?: 0
                    val currentFile = call.argument<String>("currentFile")
                    val text = if (currentFile != null) {
                        "Syncing $completed/$total — $currentFile"
                    } else {
                        "Syncing $completed/$total photos"
                    }
                    updateNotification(text)
                    result.success(null)
                }
                "syncComplete" -> {
                    val message = call.argument<String>("message") ?: "Sync complete"
                    updateNotification(message)
                    result.success(null)
                    stopSelf()
                }
                else -> result.notImplemented()
            }
        }

        val appBundlePath = FlutterInjector.instance().flutterLoader().findAppBundlePath()
        engine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint(appBundlePath, "backgroundSyncEntrypoint")
        )

        io.flutter.plugins.GeneratedPluginRegistrant.registerWith(engine)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Photo Sync",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Background photo sync progress"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(text: String): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Lumina Photo Sync")
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_popup_sync)
            .setOngoing(true)
            .setSilent(true)
            .build()
    }

    private fun updateNotification(text: String) {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, buildNotification(text))
    }

    private fun acquireWakeLock() {
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = pm.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "lumina:photo_sync"
        ).apply {
            acquire(60 * 60 * 1000L) // 1 hour max
        }
    }

    private fun releaseWakeLock() {
        wakeLock?.let {
            if (it.isHeld) it.release()
        }
        wakeLock = null
    }
}
