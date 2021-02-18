package io.carius.lars.ar_flutter_plugin

import android.app.Activity
import android.app.Application
import android.content.Context
import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.Toast
import com.google.ar.core.*
import com.google.ar.core.exceptions.*
import com.google.ar.sceneform.ArSceneView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView

internal class AndroidARView(
        val activity: Activity,
        context: Context,
        messenger: BinaryMessenger,
        id: Int,
        creationParams: Map<String?, Any?>?
) : PlatformView {
    // constants
    private val TAG: String = AndroidARView::class.java.name
    // Lifecycle variables
    private var mUserRequestedInstall = true
    lateinit var activityLifecycleCallbacks: Application.ActivityLifecycleCallbacks
    // Platform channels
    private val sessionManagerChannel: MethodChannel = MethodChannel(messenger, "arsession_$id")
    private val objectManagerChannel: MethodChannel = MethodChannel(messenger, "arobjects_$id")
    // UI variables
    private lateinit var arSceneView: ArSceneView

    //Method channel handlers
    private val onSessionMethodCall = object : MethodChannel.MethodCallHandler {
        override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
            Log.d(TAG, "AndroidARView onsessionmethodcall reveived a call!")
            when (call.method) {
                "init" -> {
                    sessionManagerChannel.invokeMethod("onError", listOf("SessionTEST from Android"))
                }
                else -> {
                }
            }
        }
    }
    private val onObjectMethodCall = object : MethodChannel.MethodCallHandler {
        override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
            Log.d(TAG, "AndroidARView onobjectmethodcall reveived a call!")
            when (call.method) {
                "init" -> {
                    objectManagerChannel.invokeMethod("onError", listOf("ObjectTEST from Android"))
                }
                else -> {
                }
            }
        }
    }

    override fun getView(): View {
        return arSceneView
    }

    override fun dispose() {
        // Destroy AR session
        try {
            arSceneView.destroy()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    init {

        Log.d(TAG, "Initializing AndroidARView")
        arSceneView = ArSceneView(context)
        setupLifeCycle(context)

        sessionManagerChannel.setMethodCallHandler(onSessionMethodCall)
        objectManagerChannel.setMethodCallHandler(onObjectMethodCall)

        onResume() // call onResume once to setup initial session
        // TODO: find out why this does not happen automatically
    }

    private fun setupLifeCycle(context: Context) {
        activityLifecycleCallbacks =
                object : Application.ActivityLifecycleCallbacks {
                    override fun onActivityCreated(
                            activity: Activity,
                            savedInstanceState: Bundle?
                    ) {
                        Log.d(TAG, "onActivityCreated")
                    }

                    override fun onActivityStarted(activity: Activity) {
                        Log.d(TAG, "onActivityStarted")
                    }

                    override fun onActivityResumed(activity: Activity) {
                        Log.d(TAG, "onActivityResumed")
                        onResume()
                    }

                    override fun onActivityPaused(activity: Activity) {
                        Log.d(TAG, "onActivityPaused")
                        onPause()
                    }

                    override fun onActivityStopped(activity: Activity) {
                        Log.d(TAG, "onActivityStopped")
                        // onStopped()
                    }

                    override fun onActivitySaveInstanceState(
                            activity: Activity,
                            outState: Bundle
                    ) {}

                    override fun onActivityDestroyed(activity: Activity) {
                        Log.d(TAG, "onActivityDestroyed")
                        // onDestroy()
                    }
                }

        activity.application.registerActivityLifecycleCallbacks(this.activityLifecycleCallbacks)
    }

    fun onResume() {
        // Create session if there is none
        if (arSceneView.session == null) {
            Log.d(TAG, "ARSceneView session is null. Trying to initialize")
            try {
                var session: Session?
                if (ArCoreApk.getInstance().requestInstall(activity, mUserRequestedInstall) ==
                        ArCoreApk.InstallStatus.INSTALL_REQUESTED) {
                    Log.d(TAG, "Install of ArCore APK requested")
                    session = null
                } else {
                    session = Session(activity)
                }

                if (session == null) {
                    // Ensures next invocation of requestInstall() will either return
                    // INSTALLED or throw an exception.
                    mUserRequestedInstall = false
                    return
                } else {
                    val config = Config(session)
                    config.updateMode = Config.UpdateMode.LATEST_CAMERA_IMAGE
                    config.focusMode = Config.FocusMode.AUTO
                    session.configure(config)
                    arSceneView.setupSession(session)
                }
            } catch (ex: UnavailableUserDeclinedInstallationException) {
                // Display an appropriate message to the user zand return gracefully.
                Toast.makeText(
                                activity,
                                "TODO: handle exception " + ex.localizedMessage,
                                Toast.LENGTH_LONG)
                        .show()
                return
            } catch (ex: UnavailableArcoreNotInstalledException) {
                Toast.makeText(activity, "Please install ARCore", Toast.LENGTH_LONG).show()
                return
            } catch (ex: UnavailableApkTooOldException) {
                Toast.makeText(activity, "Please update ARCore", Toast.LENGTH_LONG).show()
                return
            } catch (ex: UnavailableSdkTooOldException) {
                Toast.makeText(activity, "Please update this app", Toast.LENGTH_LONG).show()
                return
            } catch (ex: UnavailableDeviceNotCompatibleException) {
                Toast.makeText(activity, "This device does not support AR", Toast.LENGTH_LONG)
                        .show()
                return
            } catch (e: Exception) {
                Toast.makeText(activity, "Failed to create AR session", Toast.LENGTH_LONG).show()
                return
            }
        }

        try {
            arSceneView.resume()
        } catch (ex: CameraNotAvailableException) {
            Log.d(TAG, "Unable to get camera" + ex)
            activity.finish()
            return
        }
    }

    fun onPause() {
        arSceneView.pause()
    }
}
