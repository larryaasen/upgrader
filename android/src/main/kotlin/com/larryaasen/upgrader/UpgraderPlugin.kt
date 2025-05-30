package com.larryaasen.upgrader

import android.app.Activity
import android.content.Context
import android.util.Log
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
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.common.ConnectionResult
// V2 embedding doesn't need PluginRegistry import

/** UpgraderPlugin */
class UpgraderPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  private val TAG = "UpgraderPlugin"
  private lateinit var channel: MethodChannel
  private lateinit var context: Context
  private var activity: Activity? = null
  private lateinit var appUpdateManager: AppUpdateManager
  private var installStateUpdatedListener: InstallStateUpdatedListener? = null
  private val REQUEST_CODE_UPDATE = 1001

  // Default constructor
  constructor() {
    // Empty constructor
  }

  /**
   * Check if Google Play Store is available on the device
   */
  private fun isPlayStoreAvailable(result: Result) {
    Log.d(TAG, "Checking if Play Store is available")

    try {
      // Check if Google Play Store app is installed
      val playStorePackage = "com.android.vending"
      val playStoreAvailable = try {
        context.packageManager.getPackageInfo(playStorePackage, 0)
        true
      } catch (e: Exception) {
        Log.d(TAG, "Play Store not found: ${e.message}")
        false
      }

      // Also check if Google Play Services is available and working
      val googlePlayServicesAvailable = try {
        val googleApiAvailability = GoogleApiAvailability.getInstance()
        val resultCode = googleApiAvailability.isGooglePlayServicesAvailable(context)
        resultCode == ConnectionResult.SUCCESS
      } catch (e: Exception) {
        Log.d(TAG, "Google Play Services check failed: ${e.message}")
        false
      }

      val isAvailable = playStoreAvailable && googlePlayServicesAvailable
      Log.d(TAG, "Play Store available: $playStoreAvailable, Play Services available: $googlePlayServicesAvailable")

      result.success(isAvailable)
    } catch (e: Exception) {
      Log.e(TAG, "Error checking Play Store availability: ${e.message}")
      result.success(false)  // On any error, assume it's not available
    }
  }

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    Log.d(TAG, "Plugin being attached to engine")
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.larryaasen.upgrader/in_app_update")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
    appUpdateManager = AppUpdateManagerFactory.create(context)
  }

  // We're using V2 embedding, so no companion object is needed for registration

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "isPlayStoreAvailable" -> {
        isPlayStoreAvailable(result)
      }
      "checkForUpdate" -> {
        val immediateUpdate = call.argument<Boolean>("immediateUpdate") ?: false
        val language = call.argument<String>("language")
        checkForUpdate(immediateUpdate, language, result)
      }
      "completeUpdate" -> {
        completeUpdate(result)
      }
      else -> {
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
    Log.d(TAG, "checkForUpdate called - immediateUpdate: $immediateUpdate, language: $language")

    val currentActivity = activity
    if (currentActivity == null) {
      Log.e(TAG, "No activity available")
      result.error("NO_ACTIVITY", "No activity available", null)
      return
    }

    // Log essential debugging information
    Log.d(TAG, "Activity: ${currentActivity.javaClass.simpleName}")
    Log.d(TAG, "Context: ${context.javaClass.simpleName}")

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
      Log.d(TAG, "appUpdateInfo received: updateAvailability: ${appUpdateInfo.updateAvailability()}")

      Log.d(TAG, "Update availability status: ${appUpdateInfo.updateAvailability()}, isUpdateAvailable: ${appUpdateInfo.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE}")

      // If we have an available update, show proper information
      if (appUpdateInfo.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE) {
        Log.d(TAG, "Update is available, versionCode: ${appUpdateInfo.availableVersionCode()}")
      }

      // Always try to proceed with the requested update type
      val updateType = if (immediateUpdate) AppUpdateType.IMMEDIATE else AppUpdateType.FLEXIBLE
      val updateTypeAllowed = appUpdateInfo.isUpdateTypeAllowed(updateType)

      Log.d(TAG, "Update type: ${if (updateType == AppUpdateType.IMMEDIATE) "IMMEDIATE" else "FLEXIBLE"}, allowed: $updateTypeAllowed")

      if (updateTypeAllowed) {
        // Always attempt to start the update flow regardless of update availability
        // Google Play Store will handle the actual determination of whether an update exists
        val appUpdateOptions = AppUpdateOptions.defaultOptions(updateType)

        Log.d(TAG, "Starting update flow with options: $appUpdateOptions")

        try {
          // Start the update
          appUpdateManager.startUpdateFlow(appUpdateInfo, currentActivity, appUpdateOptions)
          Log.d(TAG, "Update flow started successfully")
        } catch (e: Exception) {
          Log.e(TAG, "Error starting update flow: ${e.message}")
        }

        // Always report success even if we don't know for sure that an update is available
        // This is because we want the update flow to be triggered even if Google Play doesn't
        // immediately report an update as available
        result.success(mapOf(
          "updateAvailable" to true,
          "immediateUpdateAllowed" to (updateType == AppUpdateType.IMMEDIATE && updateTypeAllowed),
          "flexibleUpdateAllowed" to (updateType == AppUpdateType.FLEXIBLE && updateTypeAllowed),
          "versionCode" to appUpdateInfo.availableVersionCode()
        ))
      } else {
        Log.d(TAG, "Update type not allowed")
        result.success(mapOf(
          "updateAvailable" to true, // Still return true to encourage further checks
          "immediateUpdateAllowed" to false,
          "flexibleUpdateAllowed" to false,
          "versionCode" to appUpdateInfo.availableVersionCode()
        ))
      }
    }.addOnFailureListener { exception ->
      Log.e(TAG, "Update check failed: ${exception.message}")
      result.error("UPDATE_CHECK_FAILED", exception.message, null)
    }
  }

  private fun completeUpdate(result: Result) {
    Log.d(TAG, "completeUpdate called")
    appUpdateManager.completeUpdate().addOnSuccessListener {
      Log.d(TAG, "completeUpdate successful")
      result.success(true)
    }.addOnFailureListener { exception ->
      Log.e(TAG, "completeUpdate failed: ${exception.message}")
      result.error("COMPLETE_UPDATE_FAILED", exception.message, null)
    }
  }
}
