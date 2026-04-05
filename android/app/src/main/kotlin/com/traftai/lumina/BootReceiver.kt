package com.traftai.lumina

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return

        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val enabled = prefs.getBoolean("flutter.backgroundSyncEnabled", false)
        if (!enabled) return

        val intervalMinutes = prefs.getInt("flutter.backgroundSyncInterval", 720)
        SyncAlarmReceiver.schedule(context, intervalMinutes)
    }
}
