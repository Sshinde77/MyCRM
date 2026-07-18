package com.technofra.mycrm

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import com.google.android.play.core.appupdate.AppUpdateInfo
import com.google.android.play.core.appupdate.AppUpdateManager
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.UpdateAvailability
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
  companion object {
    private const val UPDATE_REQUEST_CODE = 1001
  }

  private lateinit var appUpdateManager: AppUpdateManager

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    appUpdateManager = AppUpdateManagerFactory.create(this)
    checkForImmediateUpdate()
  }

  private fun checkForImmediateUpdate() {
    appUpdateManager.appUpdateInfo
      .addOnSuccessListener { updateInfo ->
        val updateAvailable =
          updateInfo.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE
        val immediateUpdateAllowed =
          updateInfo.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE)

        if (updateAvailable && immediateUpdateAllowed) {
          startImmediateUpdate(updateInfo)
        }
      }
      .addOnFailureListener {
        // Ignore update check failures and continue loading the app.
      }
  }

  private fun startImmediateUpdate(updateInfo: AppUpdateInfo) {
    appUpdateManager.startUpdateFlowForResult(
      updateInfo,
      AppUpdateType.IMMEDIATE,
      this,
      UPDATE_REQUEST_CODE,
    )
  }

  override fun onResume() {
    super.onResume()

    if (!::appUpdateManager.isInitialized) {
      return
    }

    appUpdateManager.appUpdateInfo
      .addOnSuccessListener { updateInfo ->
        if (
          updateInfo.updateAvailability() ==
          UpdateAvailability.DEVELOPER_TRIGGERED_UPDATE_IN_PROGRESS
        ) {
          startImmediateUpdate(updateInfo)
        }
      }
  }

  @Deprecated("Deprecated in Java")
  override fun onActivityResult(
    requestCode: Int,
    resultCode: Int,
    data: Intent?,
  ) {
    super.onActivityResult(requestCode, resultCode, data)

    if (requestCode != UPDATE_REQUEST_CODE) {
      return
    }

    if (resultCode != Activity.RESULT_OK) {
      finishAffinity()
    }
  }
}
