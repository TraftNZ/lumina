package com.traftai.lumina

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import run.Run

import android.content.Intent
import android.net.Uri
import android.os.Build
import java.io.File


class MainActivity : FlutterFragmentActivity() {
  private val CHANNEL = "com.traftai.lumina/RunGrpcServer"
  private val BG_CHANNEL = "com.traftai.lumina/BackgroundSync"

  override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
        call,
        result ->
      if (call.method == "RunGrpcServer") {
        val dataDir = call.argument<String>("dataDir") ?: ""
        val cacheDir = call.argument<String>("cacheDir") ?: ""
        val re = Run.runGrpcServer(dataDir, cacheDir)
        result.success(re)
      } else if (call.method == "scanFile") {
        scanFile(call.argument("path"), call.argument("volumeName"), call.argument("relativePath"), call.argument("mimeType"))
        result.success(null)
      } else {
        result.notImplemented()
      }
    }

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BG_CHANNEL).setMethodCallHandler {
        call,
        result ->
      when (call.method) {
        "scheduleSync" -> {
          val intervalMinutes = call.argument<Int>("intervalMinutes") ?: 720
          SyncAlarmReceiver.schedule(this, intervalMinutes)
          result.success(null)
        }
        "cancelScheduledSync" -> {
          SyncAlarmReceiver.cancel(this)
          result.success(null)
        }
        "startBackgroundSync" -> {
          if (!PhotoSyncService.isRunning) {
            val intent = Intent(this, PhotoSyncService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
              startForegroundService(intent)
            } else {
              startService(intent)
            }
          }
          result.success(null)
        }
        "isSyncRunning" -> {
          result.success(PhotoSyncService.isRunning)
        }
        else -> result.notImplemented()
      }
    }
  }

  private fun scanFile(path: String?, volumeName: String?, relativePath: String?, mimeType: String?) {
    val mediaScanIntent = Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE)
    val file = File(path)
    val contentUri = Uri.fromFile(file)
    mediaScanIntent.data = contentUri
    sendBroadcast(mediaScanIntent)
  }
}
