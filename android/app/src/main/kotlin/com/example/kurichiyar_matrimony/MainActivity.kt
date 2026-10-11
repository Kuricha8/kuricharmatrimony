package com.example.kurichiyar_matrimony

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.content.pm.Signature
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.kurichiyar.matrimony/security"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            val channels = listOf(
                NotificationChannel(
                    "high_importance_channel",
                    "പ്രധാന അറിയിപ്പുകൾ (High Importance)",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "പുതിയ ഉപയോക്താക്കൾ, അപ്രൂവലുകൾ എന്നിവയ്ക്കുള്ള ചാനൽ"
                    enableVibration(true)
                },
                NotificationChannel(
                    "app_updates",
                    "App Updates (ആപ്പ് അപ്ഡേറ്റുകൾ)",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Notifications for new app updates and releases"
                    enableVibration(true)
                },
                NotificationChannel(
                    "general_announcements",
                    "General Announcements (പൊതു അറിയിപ്പുകൾ)",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Community news, general announcements, and system alerts"
                    enableVibration(true)
                },
                NotificationChannel(
                    "kurichiyar_chat_channel",
                    "Chat Messages (ചാറ്റ് സന്ദേശങ്ങൾ)",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Direct chat messages and replies"
                    enableVibration(true)
                },
                NotificationChannel(
                    "clan_high_importance_channel",
                    "Tharavadu Clan Notifications",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Notifications for clan status updates and chat messages"
                    enableVibration(true)
                }
            )

            channels.forEach { channel ->
                notificationManager.createNotificationChannel(channel)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getApkSignatureHash") {
                try {
                    val hash = getSignatureHash()
                    result.success(hash)
                } catch (e: Exception) {
                    result.error("UNAVAILABLE", "Failed to get signature hash.", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getSignatureHash(): String {
        val packageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES)
        } else {
            @Suppress("DEPRECATION")
            packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES)
        }

        val signatures: Array<Signature>? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            packageInfo.signingInfo?.apkContentsSigners
        } else {
            @Suppress("DEPRECATION")
            packageInfo.signatures
        }

        if (signatures != null && signatures.isNotEmpty()) {
            val md = MessageDigest.getInstance("SHA-256")
            md.update(signatures[0].toByteArray())
            val digest = md.digest()
            val hexString = StringBuilder()
            for (byte in digest) {
                val hex = Integer.toHexString(0xFF and byte.toInt())
                if (hex.length == 1) {
                    hexString.append('0')
                }
                hexString.append(hex)
            }
            return hexString.toString()
        }
        return ""
    }
}
