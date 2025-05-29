package com.larryaasen.upgrader

import android.app.Activity
import android.content.Context
import androidx.annotation.NonNull
import com.google.android.play.core.appupdate.AppUpdateManager
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.appupdate.AppUpdateOptions
import com.google.android.play.core.install.InstallStateUpdatedListener
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.InstallStatus
import com.google.android.play.core.install.model.UpdateAvailability
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** UpgraderPlugin */
class UpgraderPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  private lateinit var channel : MethodChannel
  private lateinit var context: Context
  private var activity: Activity? = null
  private lateinit var appUpdateManager: AppUpdateManager
  private var installStateUpdatedListener: InstallStateUpdatedListener? = null
  private val REQUEST_CODE_UPDATE = 1001

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.larryaasen.upgrader/in_app_update")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
    appUpdateManager = AppUpdateManagerFactory.create(context)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "checkForUpdate" -> {
        val immediateUpdate = call.argument<Boolean>("immediateUpdate") ?: false
        val language = call.argument<String>("language")
        checkForUpdate(immediateUpdate, language, result)
      }
      "completeUpdate" -> {
        completeUpdate(result)
      }
      "else" -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    installStateUpdatedListener?.let {
      appUpdateManager.unregisterListener(it)
    }
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addActivityResultListener { requestCode, resultCode, _ ->
      if (requestCode == REQUEST_CODE_UPDATE) {
        if (resultCode != Activity.RESULT_OK) {
          channel.invokeMethod("onUpdateFailure", mapOf("errorCode" to resultCode))
        }
        return@addActivityResultListener true
      }
      return@addActivityResultListener false
    }
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  private fun checkForUpdate(immediateUpdate: Boolean, language: String?, result: Result) {
    val currentActivity = activity
    if (currentActivity == null) {
      result.error("NO_ACTIVITY", "No activity available", null)
      return
    }

    // Create a listener to track the update state
    installStateUpdatedListener = InstallStateUpdatedListener { state ->
      when (state.installStatus()) {
        InstallStatus.DOWNLOADED -> {
          channel.invokeMethod("onUpdateDownloaded", null)
        }
        InstallStatus.INSTALLED -> {
          channel.invokeMethod("onUpdateInstalled", null)
        }
        InstallStatus.FAILED -> {
          channel.invokeMethod("onUpdateFailure", mapOf("errorCode" to state.installErrorCode()))
        }
      }
    }

    installStateUpdatedListener?.let {
      appUpdateManager.registerListener(it)
    }

    // Returns an intent object that you use to check for an update.
    val appUpdateInfoTask = appUpdateManager.appUpdateInfo

    // Checks that the platform will allow the specified type of update.
    appUpdateInfoTask.addOnSuccessListener { appUpdateInfo ->
      if (appUpdateInfo.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE) {
        // Check if update is allowed
        val updateType = if (immediateUpdate) AppUpdateType.IMMEDIATE else AppUpdateType.FLEXIBLE
        val updateTypeAllowed = appUpdateInfo.isUpdateTypeAllowed(updateType)
        
        if (updateTypeAllowed) {
          val appUpdateOptions = AppUpdateOptions.defaultOptions(updateType)
          
          // Start the update
          appUpdateManager.startUpdateFlow(appUpdateInfo, currentActivity, appUpdateOptions, REQUEST_CODE_UPDATE)
          result.success(mapOf(
            "updateAvailable" to true,
            "immediateUpdateAllowed" to (updateType == AppUpdateType.IMMEDIATE && updateTypeAllowed),
            "flexibleUpdateAllowed" to (updateType == AppUpdateType.FLEXIBLE && updateTypeAllowed),
            "versionCode" to appUpdateInfo.availableVersionCode()
          ))
        } else {
          result.success(mapOf(
            "updateAvailable" to true,
            "immediateUpdateAllowed" to false,
            "flexibleUpdateAllowed" to false,
            "versionCode" to appUpdateInfo.availableVersionCode()
          ))
        }
      } else {
        result.success(mapOf(
          "updateAvailable" to false
        ))
      }
    }.addOnFailureListener { exception ->
      result.error("UPDATE_CHECK_FAILED", exception.message, null)
    }
  }

  private fun completeUpdate(result: Result) {
    appUpdateManager.completeUpdate().addOnSuccessListener {
      result.success(true)
    }.addOnFailureListener { exception ->
      result.error("COMPLETE_UPDATE_FAILED", exception.message, null)
    }
  }
}
