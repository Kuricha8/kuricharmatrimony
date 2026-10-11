package com.kurichiyar.matrimony

import android.content.pm.PackageManager
import android.content.pm.Signature
import android.os.Build
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

class MainActivity : FlutterFragmentActivity() {
    private val SECURITY_CHANNEL = "com.kurichiyar.matrimony/security"
    private val WINDOW_SECURITY_CHANNEL = "com.kurichiyar.matrimony/window_security"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Security channel for signature checks
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SECURITY_CHANNEL).setMethodCallHandler { call, result ->
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

        // Window security channel for anti-screenshot and screen recording protection (FLAG_SECURE)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WINDOW_SECURITY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableSecureScreen" -> {
                    try {
                        runOnUiThread {
                            window.setFlags(
                                WindowManager.LayoutParams.FLAG_SECURE,
                                WindowManager.LayoutParams.FLAG_SECURE
                            )
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("WINDOW_ERROR", "Failed to enable FLAG_SECURE: ${e.message}", null)
                    }
                }
                "disableSecureScreen" -> {
                    try {
                        runOnUiThread {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("WINDOW_ERROR", "Failed to disable FLAG_SECURE: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
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
