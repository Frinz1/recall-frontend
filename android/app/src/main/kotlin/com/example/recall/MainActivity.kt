package com.example.recall

import android.accounts.AccountManager
import android.app.Activity
import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.example.recall/google_account_picker"
    private val pickAccountRequestCode = 9001
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "pickGoogleAccount") {
                    if (pendingResult != null) {
                        result.error("ALREADY_ACTIVE", "Google account picker is already open.", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            AccountManager.newChooseAccountIntent(
                                null,
                                null,
                                arrayOf("com.google"),
                                null,
                                null,
                                null,
                                null
                            )
                        } else {
                            @Suppress("DEPRECATION")
                            AccountManager.newChooseAccountIntent(
                                null,
                                null,
                                arrayOf("com.google"),
                                false,
                                null,
                                null,
                                null,
                                null
                            )
                        }
                        pendingResult = result
                        startActivityForResult(intent, pickAccountRequestCode)
                    } catch (e: Exception) {
                        pendingResult = null
                        result.error("PICKER_FAILED", e.localizedMessage ?: "Failed to open Google account picker", null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == pickAccountRequestCode) {
            val callback = pendingResult
            pendingResult = null
            if (callback != null) {
                if (resultCode == Activity.RESULT_OK && data != null) {
                    val accountEmail = data.getStringExtra(AccountManager.KEY_ACCOUNT_NAME)
                    if (!accountEmail.isNullOrBlank()) {
                        callback.success(mapOf("email" to accountEmail))
                    } else {
                        callback.error("EMPTY_ACCOUNT", "No Google account email was returned.", null)
                    }
                } else {
                    callback.error("CANCELLED", "Google Sign-In was cancelled.", null)
                }
            }
        }
    }
}
