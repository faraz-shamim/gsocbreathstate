package com.example.breath_state

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "breath_state/background_session",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    val reason = call.argument<String>("reason")
                        ?: "BreathState session is running"
                    val usesConnectedDevice =
                        call.argument<Boolean>("usesConnectedDevice") ?: true
                    val usesMicrophone =
                        call.argument<Boolean>("usesMicrophone") ?: false

                    val intent = Intent(this, BackgroundSessionService::class.java).apply {
                        action = BackgroundSessionService.ACTION_START
                        putExtra(BackgroundSessionService.EXTRA_REASON, reason)
                        putExtra(
                            BackgroundSessionService.EXTRA_CONNECTED_DEVICE,
                            usesConnectedDevice,
                        )
                        putExtra(
                            BackgroundSessionService.EXTRA_MICROPHONE,
                            usesMicrophone,
                        )
                    }

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(null)
                }

                "stop" -> {
                    val intent = Intent(this, BackgroundSessionService::class.java)
                    stopService(intent)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "breath_state/platform",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "androidSdkInt" -> result.success(Build.VERSION.SDK_INT)
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "breath_state/webxr",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "launchBrowser" -> {
                    val url = call.argument<String>("url")
                    if (url.isNullOrBlank()) {
                        result.error("invalid_url", "A WebXR URL is required", null)
                        return@setMethodCallHandler
                    }

                    val browserIntent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                        addCategory(Intent.CATEGORY_BROWSABLE)
                        setPackage(META_QUEST_BROWSER_PACKAGE)
                    }
                    try {
                        startActivity(browserIntent)
                        result.success(null)
                    } catch (_: ActivityNotFoundException) {
                        try {
                            browserIntent.setPackage(null)
                            startActivity(browserIntent)
                            result.success(null)
                        } catch (error: ActivityNotFoundException) {
                            result.error(
                                "browser_unavailable",
                                "No browser capable of opening the WebXR scene was found",
                                error.message,
                            )
                        }
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    private companion object {
        const val META_QUEST_BROWSER_PACKAGE = "com.oculus.browser"
    }
}
