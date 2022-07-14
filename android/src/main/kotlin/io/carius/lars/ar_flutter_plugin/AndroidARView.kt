package io.carius.lars.ar_flutter_plugin

import android.app.Activity
import android.app.Application
import android.content.Context
import android.graphics.Bitmap
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.HandlerThread
import android.util.Log
import android.view.MotionEvent
import android.view.PixelCopy
import android.view.View
import android.widget.Toast
import com.google.ar.core.*
import com.google.ar.core.exceptions.*
import com.google.ar.sceneform.*
import com.google.ar.sceneform.math.Vector3
import com.google.ar.sceneform.ux.*
import io.carius.lars.ar_flutter_plugin.Serialization.deserializeMatrix4
import io.carius.lars.ar_flutter_plugin.Serialization.serializeAnchor
import io.carius.lars.ar_flutter_plugin.Serialization.serializeHitResult
import io.carius.lars.ar_flutter_plugin.Serialization.serializePose
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.loader.FlutterLoader
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.nio.FloatBuffer
import java.util.concurrent.CompletableFuture

import android.R
import com.google.ar.sceneform.rendering.*

import android.view.ViewGroup

import com.google.ar.core.TrackingState














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
    private val viewContext: Context
    // Platform channels
    private val sessionManagerChannel: MethodChannel = MethodChannel(messenger, "arsession_$id")
    private val objectManagerChannel: MethodChannel = MethodChannel(messenger, "arobjects_$id")
    private val anchorManagerChannel: MethodChannel = MethodChannel(messenger, "aranchors_$id")
    // UI variables
    private lateinit var arSceneView: ArSceneView
    private lateinit var transformationSystem: TransformationSystem
    private var showFeaturePoints = false
    private var showAnimatedGuide = false
    private lateinit var animatedGuide: View
    private var pointCloudNode = Node()
    private var worldOriginNode = Node()
    // Setting defaults
    private var enableRotation = false
    private var enablePans = false
    private var keepNodeSelected = true;
    private var footprintSelectionVisualizer = FootprintSelectionVisualizer()
    // Model builder
    private var modelBuilder = ArModelBuilder()
    // Cloud anchor handler
    private lateinit var cloudAnchorHandler: CloudAnchorHandler

    private lateinit var sceneUpdateListener: com.google.ar.sceneform.Scene.OnUpdateListener
    private lateinit var onNodeTapListener: com.google.ar.sceneform.Scene.OnPeekTouchListener

    // Method channel handlers
    private val onSessionMethodCall =
            object : MethodChannel.MethodCallHandler {
                override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
                    Log.d(TAG, "AndroidARView onsessionmethodcall reveived a call!")
                    when (call.method) {
                        "init" -> {
                            initializeARView(call, result)
                        }
                        "getAnchorPose" -> {
                            val anchorNode = arSceneView.scene.findByName(call.argument("anchorId")) as AnchorNode?
                            if (anchorNode != null) {
                                result.success(serializePose(anchorNode.anchor!!.pose))
                            } else {
                                result.error("Error", "could not get anchor pose", null)
                            }
                        }
                        "getCameraPose" -> {
                            val cameraPose = arSceneView.arFrame?.camera?.displayOrientedPose
                            if (cameraPose != null) {
                                result.success(serializePose(cameraPose!!))
                            } else {
                                result.error("Error", "could not get camera pose", null)
                            }
                        }
                        "placeBasedOnCoordinates" -> {
                            val cpuCoordinates = floatArrayOf(call.arguments['x'], call.arguments['y'])
                            val viewCoordinates = FloatArray(2)
                            if (arSceneView.arFrame != null) {
                                arSceneView.arFrame!!.transformCoordinates2d(
                                    Coordinates2d.IMAGE_PIXELS,
                                    cpuCoordinates,
                                    Coordinates2d.VIEW,
                                    viewCoordinates
                                )
                                val allHitResults = arSceneView.arFrame!!.hitTest(viewCoordinates[0], viewCoordinates[1])
                                val planeAndPointHitResults = allHitResults.filter { ((it.trackable is Plane) || (it.trackable is Point)) }
                                val serializedPlaneAndPointHitResults: ArrayList<HashMap<String, Any>> =
                                    ArrayList(planeAndPointHitResults.map { serializeHitResult(it) })
                                result.success(serializedPlaneAndPointHitResults)
                            } else {
                                result.success(null)
                            }

                        }
                        "snapshot" -> {
                            var bitmap = Bitmap.createBitmap(arSceneView.width, arSceneView.height,
                                    Bitmap.Config.ARGB_8888);


                            // Create a handler thread to offload the processing of the image.
                            var handlerThread = HandlerThread("PixelCopier");
                            handlerThread.start();
                            // Make the request to copy.
                            PixelCopy.request(arSceneView, bitmap, { copyResult:Int ->
                                Log.d(TAG, "PIXELCOPY DONE")
                                if (copyResult == PixelCopy.SUCCESS) {
                                    try {
                                        val mainHandler = Handler(context.mainLooper)
                                        val runnable = Runnable {
                                            val stream = ByteArrayOutputStream()
                                            bitmap.compress(Bitmap.CompressFormat.PNG, 90, stream)
                                            val data = stream.toByteArray()
                                            result.success(data)
                                        }
                                        mainHandler.post(runnable)
                                    } catch (e: IOException) {
                                        result.error("e", e.message, e.stackTrace);
                                    }
                                } else {
                                    result.error("e", "failed to take screenshot", null);
                                }
                                handlerThread.quitSafely();
                            }, Handler(handlerThread.looper));
                        }
                        "dispose" -> {
                            dispose()
                        }
                        else -> {}
                    }
                }
            }
    private val onObjectMethodCall =
            object : MethodChannel.MethodCallHandler {
                override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
                    Log.d(TAG, "AndroidARView onobjectmethodcall reveived a call!")
                    when (call.method) {
                        "init" -> {
                            // objectManagerChannel.invokeMethod("onError", listOf("ObjectTEST from
                            // Android"))
                        }
                        "addNode" -> {
                            val dict_node: HashMap<String, Any>? = call.arguments as? HashMap<String, Any>
                            dict_node?.let{
                                addNode(it).thenAccept{status: Boolean ->
                                    result.success(status)
                                }.exceptionally { throwable ->
                                    result.error("e", throwable.message, throwable.stackTrace)
                                    null
                                }
                            }
                        }
                        "addNodeToPlaneAnchor" -> {
                            val dict_node: HashMap<String, Any>? = call.argument<HashMap<String, Any>>("node")
                            val dict_anchor: HashMap<String, Any>? = call.argument<HashMap<String, Any>>("anchor")
                            if (dict_node != null && dict_anchor != null) {
                                addNode(dict_node, dict_anchor).thenAccept{status: Boolean ->
                                    result.success(status)
                                }.exceptionally { throwable ->
                                    result.error("e", throwable.message, throwable.stackTrace)
                                    null
                                }
                            } else {
                                result.success(false)
                            }

                        }
                        "removeNode" -> {
                            val nodeName: String? = call.argument<String>("name")
                            nodeName?.let{
                                if (transformationSystem.selectedNode?.name == nodeName){
                                    transformationSystem.selectNode(null)
                                    keepNodeSelected = true
                                }
                                val node = arSceneView.scene.findByName(nodeName)
                                node?.let{
                                    arSceneView.scene.removeChild(node)
                                    result.success(null)
                                }
                            }
                        }
                        "transformationChanged" -> {
                            val nodeName: String? = call.argument<String>("name")
                            val newTransformation: ArrayList<Double>? = call.argument<ArrayList<Double>>("transformation")
                            nodeName?.let{ name ->
                                newTransformation?.let{ transform ->
                                    transformNode(name, transform)
                                    result.success(null)
                                }
                            }
                        }
                        else -> {}
                    }
                }
            }
    private val onAnchorMethodCall =
            object : MethodChannel.MethodCallHandler {
                override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
                    when (call.method) {
                        "addAnchor" -> {
                            val anchorType: Int? = call.argument<Int>("type")
                            if (anchorType != null){
                                when(anchorType) {
                                    0 -> { // Plane Anchor
                                        val transform: ArrayList<Double>? = call.argument<ArrayList<Double>>("transformation")
                                        val name: String? = call.argument<String>("name")
                                        if ( name != null && transform != null){
                                            result.success(addPlaneAnchor(transform, name))
                                        } else {
                                            result.success(false)
                                        }

                                    }
                                    else -> result.success(false)
                                }
                            } else {
                                result.success(false)
                            }
                        }
                        "removeAnchor" -> {
                            val anchorName: String? = call.argument<String>("name")
                            anchorName?.let{ name ->
                                removeAnchor(name)
                            }
                        }
                        "initGoogleCloudAnchorMode" -> {
                            if (arSceneView.session != null) {
                                val config = Config(arSceneView.session)
                                config.cloudAnchorMode = Config.CloudAnchorMode.ENABLED
                                config.updateMode = Config.UpdateMode.LATEST_CAMERA_IMAGE
                                config.focusMode = Config.FocusMode.AUTO
                                arSceneView.session?.configure(config)

                                cloudAnchorHandler = CloudAnchorHandler(arSceneView.session!!)
                            } else {
                                sessionManagerChannel.invokeMethod("onError", listOf("Error initializing cloud anchor mode: Session is null"))
                            }
                        }
                        "uploadAnchor" ->  {
                            val anchorName: String? = call.argument<String>("name")
                            val ttl: Int? = call.argument<Int>("ttl")
                            anchorName?.let {
                                val anchorNode = arSceneView.scene.findByName(anchorName) as AnchorNode?
                                if (ttl != null) {
                                    cloudAnchorHandler.hostCloudAnchorWithTtl(anchorName, anchorNode!!.anchor, cloudAnchorUploadedListener(), ttl!!)
                                } else {
                                    cloudAnchorHandler.hostCloudAnchor(anchorName, anchorNode!!.anchor, cloudAnchorUploadedListener())
                                }
                                //Log.d(TAG, "---------------- HOSTING INITIATED ------------------")
                                result.success(true)
                            }

                        }
                        "downloadAnchor" -> {
                            val anchorId: String? = call.argument<String>("cloudanchorid")
                            //Log.d(TAG, "---------------- RESOLVING INITIATED ------------------")
                            anchorId?.let {
                                cloudAnchorHandler.resolveCloudAnchor(anchorId, cloudAnchorDownloadedListener())
                            }
                        }
                        else -> {}
                    }
                }
            }

    override fun getView(): View {
        return arSceneView
    }

    override fun dispose() {
        // Destroy AR session
        Log.d(TAG, "dispose called")
        try {
            onPause()
            onDestroy()
            ArSceneView.destroyAllResources()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    init {

        Log.d(TAG, "Initializing AndroidARView")
        viewContext = context

        arSceneView = ArSceneView(context)

        setupLifeCycle(context)

        sessionManagerChannel.setMethodCallHandler(onSessionMethodCall)
        objectManagerChannel.setMethodCallHandler(onObjectMethodCall)
        anchorManagerChannel.setMethodCallHandler(onAnchorMethodCall)

        //Original visualizer: com.google.ar.sceneform.ux.R.raw.sceneform_footprint

        MaterialFactory.makeTransparentWithColor(context, Color(255f, 255f, 255f, 0.3f))
                .thenAccept { mat ->
                    footprintSelectionVisualizer.footprintRenderable = ShapeFactory.makeCylinder(0.7f,0.05f, Vector3(0f,0f,0f), mat)
                }

        transformationSystem =
                TransformationSystem(
                        activity.resources.displayMetrics,
                        footprintSelectionVisualizer)

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
                        onPause()
                    }

                    override fun onActivitySaveInstanceState(
                            activity: Activity,
                            outState: Bundle
                    ) {}

                    override fun onActivityDestroyed(activity: Activity) {
                        Log.d(TAG, "onActivityDestroyed")
//                        onPause()
//                        onDestroy()
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
        } catch (e : Exception){
            return
        }
    }

    fun onPause() {
        // hide instructions view if no longer required
        if (showAnimatedGuide){
            val view = activity.findViewById(R.id.content) as ViewGroup
            view.removeView(animatedGuide)
            showAnimatedGuide = false
        }
        arSceneView.pause()
    }

    fun onDestroy() {
        try {
            arSceneView.session?.close()
            arSceneView.destroy()
            arSceneView.scene?.removeOnUpdateListener(sceneUpdateListener)
            arSceneView.scene?.removeOnPeekTouchListener(onNodeTapListener)
        }catch (e : Exception){
            e.printStackTrace();
        }
    }

    private fun initializeARView(call: MethodCall, result: MethodChannel.Result) {
        // Unpack call arguments
        val argShowFeaturePoints: Boolean? = call.argument<Boolean>("showFeaturePoints")
        val argPlaneDetectionConfig: Int? = call.argument<Int>("planeDetectionConfig")
        val argShowPlanes: Boolean? = call.argument<Boolean>("showPlanes")
        val argCustomPlaneTexturePath: String? = call.argument<String>("customPlaneTexturePath")
        val argShowWorldOrigin: Boolean? = call.argument<Boolean>("showWorldOrigin")
        val argHandleTaps: Boolean? = call.argument<Boolean>("handleTaps")
        val argHandleRotation: Boolean? = call.argument<Boolean>("handleRotation")
        val argHandlePans: Boolean? = call.argument<Boolean>("handlePans")
        val argShowAnimatedGuide: Boolean? = call.argument<Boolean>("showAnimatedGuide")


        sceneUpdateListener = com.google.ar.sceneform.Scene.OnUpdateListener {
            frameTime: FrameTime -> onFrame(frameTime)
        }
        onNodeTapListener = com.google.ar.sceneform.Scene.OnPeekTouchListener { hitTestResult, motionEvent ->
            //if (hitTestResult.node != null){
                //transformationSystem.selectionVisualizer.applySelectionVisual(hitTestResult.node as TransformableNode)
                //transformationSystem.selectNode(hitTestResult.node as TransformableNode)
            //}
            if (hitTestResult.node != null && motionEvent?.action == MotionEvent.ACTION_DOWN) {
                objectManagerChannel.invokeMethod("onNodeTap", listOf(hitTestResult.node?.name))
            }
            transformationSystem.onTouch(
                hitTestResult,
                motionEvent
            )
        }

        arSceneView.scene?.addOnUpdateListener(sceneUpdateListener)
        arSceneView.scene?.addOnPeekTouchListener(onNodeTapListener)


        // Configure Plane scanning guide
        if (argShowAnimatedGuide == true) { // explicit comparison necessary because of nullable type
            showAnimatedGuide = true
            val view = activity.findViewById(R.id.content) as ViewGroup
            animatedGuide = activity.layoutInflater.inflate(com.google.ar.sceneform.ux.R.layout.sceneform_plane_discovery_layout, null)
            view.addView(animatedGuide)
        }

        // Configure feature points
        if (argShowFeaturePoints ==
                true) { // explicit comparison necessary because of nullable type
            arSceneView.scene.addChild(pointCloudNode)
            showFeaturePoints = true
        } else {
            showFeaturePoints = false
            while (pointCloudNode.children?.size
                    ?: 0 > 0) {
                pointCloudNode.children?.first()?.setParent(null)
            }
            pointCloudNode.setParent(null)
        }

        // Configure plane detection
        val config = arSceneView.session?.config
        if (config == null) {
            sessionManagerChannel.invokeMethod("onError", listOf("session is null"))
        }
        when (argPlaneDetectionConfig) {
            1 -> {
                config?.planeFindingMode = Config.PlaneFindingMode.HORIZONTAL
            }
            2 -> {
                config?.planeFindingMode = Config.PlaneFindingMode.VERTICAL
            }
            3 -> {
                config?.planeFindingMode = Config.PlaneFindingMode.HORIZONTAL_AND_VERTICAL
            }
            else -> {
                config?.planeFindingMode = Config.PlaneFindingMode.DISABLED
            }
        }
        arSceneView.session?.configure(config)

        // Configure whether or not detected planes should be shown
        arSceneView.planeRenderer.isVisible = if (argShowPlanes == true) true else false
        // Create custom plane renderer (use supplied texture & increase radius)
        argCustomPlaneTexturePath?.let {
            val loader: FlutterLoader = FlutterInjector.instance().flutterLoader()
            val key: String = loader.getLookupKeyForAsset(it)

            val sampler =
                    Texture.Sampler.builder()
                            .setMinFilter(Texture.Sampler.MinFilter.LINEAR)
                            .setWrapMode(Texture.Sampler.WrapMode.REPEAT)
                            .build()
            Texture.builder()
                    .setSource(viewContext, Uri.parse(key))
                    .setSampler(sampler)
                    .build()
                    .thenAccept { texture: Texture? ->
                        arSceneView.planeRenderer.material.thenAccept { material: Material ->
                            material.setTexture(PlaneRenderer.MATERIAL_TEXTURE, texture)
                            material.setFloat(PlaneRenderer.MATERIAL_SPOTLIGHT_RADIUS, 10f)
                        }
                    }
            // Set radius to render planes in
            arSceneView.scene.addOnUpdateListener { frameTime: FrameTime? ->
                val planeRenderer = arSceneView.planeRenderer
                planeRenderer.material.thenAccept { material: Material ->
                    material.setFloat(
                            PlaneRenderer.MATERIAL_SPOTLIGHT_RADIUS,
                            10f) // Sets the radius in which to visualize planes
                }
            }
        }

        // Configure world origin
        if (argShowWorldOrigin == true) {
            worldOriginNode = modelBuilder.makeWorldOriginNode(viewContext)
            arSceneView.scene.addChild(worldOriginNode)
        } else {
            worldOriginNode.setParent(null)
        }

        // Configure Tap handling
        if (argHandleTaps == true) { // explicit comparison necessary because of nullable type
            arSceneView.scene.setOnTouchListener{ hitTestResult: HitTestResult, motionEvent: MotionEvent? -> onTap(hitTestResult, motionEvent) }
        }

        // Configure gestures
        if (argHandleRotation ==
                true) { // explicit comparison necessary because of nullable type
            enableRotation = true
        } else {
            enableRotation = false
        }
        if (argHandlePans ==
                true) { // explicit comparison necessary because of nullable type
            enablePans = true
        } else {
            enablePans = false
        }

        result.success(null)
    }

    private fun onFrame(frameTime: FrameTime) {
        // hide instructions view if no longer required
        if (showAnimatedGuide && arSceneView.arFrame != null){
            for (plane in arSceneView.arFrame!!.getUpdatedTrackables(Plane::class.java)) {
                if (plane.trackingState === TrackingState.TRACKING) {
                    val view = activity.findViewById(R.id.content) as ViewGroup
                    view.removeView(animatedGuide)
                    showAnimatedGuide = false
                    break
                }
            }
        }

        if (showFeaturePoints) {
            // remove points from last frame
            while (pointCloudNode.children?.size
                    ?: 0 > 0) {
                pointCloudNode.children?.first()?.setParent(null)
            }
            var pointCloud = arSceneView.arFrame?.acquirePointCloud()
            // Access point cloud data (returns FloatBufferw with x,y,z coordinates and confidence
            // value).
            val points = pointCloud?.getPoints() ?: FloatBuffer.allocate(0)
            // Check if there are any feature points
            if (points.limit() / 4 >= 1) {
                for (index in 0 until points.limit() / 4) {
                    // Add feature point to scene
                    val featurePoint =
                            modelBuilder.makeFeaturePointNode(
                                    viewContext,
                                    points.get(4 * index),
                                    points.get(4 * index + 1),
                                    points.get(4 * index + 2))
                    featurePoint.setParent(pointCloudNode)
                }
            }
            // Release resources
            pointCloud?.release()
        }
        val updatedAnchors = arSceneView.arFrame!!.updatedAnchors
        // Notify the cloudManager of all the updates.
        if (this::cloudAnchorHandler.isInitialized) {cloudAnchorHandler.onUpdate(updatedAnchors)}

        if (keepNodeSelected && transformationSystem.selectedNode != null && transformationSystem.selectedNode!!.isTransforming){
            // If the selected node is currently transforming, we want to deselect it as soon as the transformation is done
            keepNodeSelected = false
        }
        if (!keepNodeSelected && transformationSystem.selectedNode != null && !transformationSystem.selectedNode!!.isTransforming){
            // once the transformation is done, deselect the node and allow selection of another node
            transformationSystem.selectNode(null)
            keepNodeSelected = true
        }
        if (!enablePans && !enableRotation){
            //unselect all nodes as we do not want the selection visualizer
            transformationSystem.selectNode(null)
        }

    }

    private fun addNode(dict_node: HashMap<String, Any>, dict_anchor: HashMap<String, Any>? = null): CompletableFuture<Boolean>{
        val completableFutureSuccess: CompletableFuture<Boolean> = CompletableFuture()

        try {
            when (dict_node["type"] as Int) {
                0 -> { // GLTF2 Model from Flutter asset folder
                    // Get path to given Flutter asset
                    val loader: FlutterLoader = FlutterInjector.instance().flutterLoader()
                    val key: String = loader.getLookupKeyForAsset(dict_node["uri"] as String)

                    // Add object to scene
                    modelBuilder.makeNodeFromGltf(viewContext, transformationSystem, objectManagerChannel, enablePans, enableRotation, dict_node["name"] as String, key, dict_node["transformation"] as ArrayList<Double>)
                            .thenAccept{node ->
                                val anchorName: String? = dict_anchor?.get("name") as? String
                                val anchorType: Int? = dict_anchor?.get("type") as? Int
                                if (anchorName != null && anchorType != null) {
                                    val anchorNode = arSceneView.scene.findByName(anchorName) as AnchorNode?
                                    if (anchorNode != null) {
                                        anchorNode.addChild(node)
                                        completableFutureSuccess.complete(true)
                                    } else {
                                        completableFutureSuccess.complete(false)
                                    }
                                } else {
                                    arSceneView.scene.addChild(node)
                                    completableFutureSuccess.complete(true)
                                }
                                completableFutureSuccess.complete(false)
                            }
                            .exceptionally { throwable ->
                                // Pass error to session manager (this has to be done on the main thread if this activity)
                                val mainHandler = Handler(viewContext.mainLooper)
                                val runnable = Runnable {sessionManagerChannel.invokeMethod("onError", listOf("Unable to load renderable" +  dict_node["uri"] as String)) }
                                mainHandler.post(runnable)
                                completableFutureSuccess.completeExceptionally(throwable)
                                null // return null because java expects void return (in java, void has no instance, whereas in Kotlin, this closure returns a Unit which has one instance)
                            }
                }
                1 -> { // GLB Model from the web
                    modelBuilder.makeNodeFromGlb(viewContext, transformationSystem, objectManagerChannel, enablePans, enableRotation, dict_node["name"] as String, dict_node["uri"] as String, dict_node["transformation"] as ArrayList<Double>)
                            .thenAccept{node ->
                                val anchorName: String? = dict_anchor?.get("name") as? String
                                val anchorType: Int? = dict_anchor?.get("type") as? Int
                                if (anchorName != null && anchorType != null) {
                                    val anchorNode = arSceneView.scene.findByName(anchorName) as AnchorNode?
                                    if (anchorNode != null) {
                                        anchorNode.addChild(node)
                                        completableFutureSuccess.complete(true)
                                    } else {
                                        completableFutureSuccess.complete(false)
                                    }
                                } else {
                                    arSceneView.scene.addChild(node)
                                    completableFutureSuccess.complete(true)
                                }
                                completableFutureSuccess.complete(false)
                            }
                            .exceptionally { throwable ->
                                // Pass error to session manager (this has to be done on the main thread if this activity)
                                val mainHandler = Handler(viewContext.mainLooper)
                                val runnable = Runnable {sessionManagerChannel.invokeMethod("onError", listOf("Unable to load renderable" +  dict_node["uri"] as String)) }
                                mainHandler.post(runnable)
                                completableFutureSuccess.completeExceptionally(throwable)
                                null // return null because java expects void return (in java, void has no instance, whereas in Kotlin, this closure returns a Unit which has one instance)
                            }
                }
                2 -> { // fileSystemAppFolderGLB
                    val documentsPath = viewContext.getApplicationInfo().dataDir
                    val assetPath = documentsPath + "/app_flutter/" + dict_node["uri"] as String

                    modelBuilder.makeNodeFromGlb(viewContext, transformationSystem, objectManagerChannel, enablePans, enableRotation, dict_node["name"] as String, assetPath as String, dict_node["transformation"] as ArrayList<Double>) //
                            .thenAccept{node ->
                                val anchorName: String? = dict_anchor?.get("name") as? String
                                val anchorType: Int? = dict_anchor?.get("type") as? Int
                                if (anchorName != null && anchorType != null) {
                                    val anchorNode = arSceneView.scene.findByName(anchorName) as AnchorNode?
                                    if (anchorNode != null) {
                                        anchorNode.addChild(node)
                                        completableFutureSuccess.complete(true)
                                    } else {
                                        completableFutureSuccess.complete(false)
                                    }
                                } else {
                                    arSceneView.scene.addChild(node)
                                    completableFutureSuccess.complete(true)
                                }
                                completableFutureSuccess.complete(false)
                            }
                            .exceptionally { throwable ->
                                // Pass error to session manager (this has to be done on the main thread if this activity)
                                val mainHandler = Handler(viewContext.mainLooper)
                                val runnable = Runnable {sessionManagerChannel.invokeMethod("onError", listOf("Unable to load renderable " +  dict_node["uri"] as String)) }
                                mainHandler.post(runnable)
                                completableFutureSuccess.completeExceptionally(throwable)
                                null // return null because java expects void return (in java, void has no instance, whereas in Kotlin, this closure returns a Unit which has one instance)
                            }
                }
                3 -> { //fileSystemAppFolderGLTF2
                    // Get path to given Flutter asset
                    val documentsPath = viewContext.getApplicationInfo().dataDir
                    val assetPath = documentsPath + "/app_flutter/" + dict_node["uri"] as String

                    // Add object to scene
                    modelBuilder.makeNodeFromGltf(viewContext, transformationSystem, objectManagerChannel, enablePans, enableRotation, dict_node["name"] as String, assetPath, dict_node["transformation"] as ArrayList<Double>)
                            .thenAccept{node ->
                                val anchorName: String? = dict_anchor?.get("name") as? String
                                val anchorType: Int? = dict_anchor?.get("type") as? Int
                                if (anchorName != null && anchorType != null) {
                                    val anchorNode = arSceneView.scene.findByName(anchorName) as AnchorNode?
                                    if (anchorNode != null) {
                                        anchorNode.addChild(node)
                                        completableFutureSuccess.complete(true)
                                    } else {
                                        completableFutureSuccess.complete(false)
                                    }
                                } else {
                                    arSceneView.scene.addChild(node)
                                    completableFutureSuccess.complete(true)
                                }
                                completableFutureSuccess.complete(false)
                            }
                            .exceptionally { throwable ->
                                // Pass error to session manager (this has to be done on the main thread if this activity)
                                val mainHandler = Handler(viewContext.mainLooper)
                                val runnable = Runnable {sessionManagerChannel.invokeMethod("onError", listOf("Unable to load renderable" +  dict_node["uri"] as String)) }
                                mainHandler.post(runnable)
                                completableFutureSuccess.completeExceptionally(throwable)
                                null // return null because java expects void return (in java, void has no instance, whereas in Kotlin, this closure returns a Unit which has one instance)
                            }
                }
                else -> {
                    completableFutureSuccess.complete(false)
                }
            }
        } catch (e: java.lang.Exception) {
            completableFutureSuccess.completeExceptionally(e)
        }

        return completableFutureSuccess
    }

    private fun transformNode(name: String, transform: ArrayList<Double>) {
        val node = arSceneView.scene.findByName(name)
        node?.let {
            val transformTriple = deserializeMatrix4(transform)
            it.localScale = transformTriple.first
            it.localPosition = transformTriple.second
            it.localRotation = transformTriple.third
            //it.worldScale = transformTriple.first
            //it.worldPosition = transformTriple.second
            //it.worldRotation = transformTriple.third
        }
    }

    private fun onTap(hitTestResult: HitTestResult, motionEvent: MotionEvent?): Boolean {
        val frame = arSceneView.arFrame
        if (hitTestResult.node != null && motionEvent?.action == MotionEvent.ACTION_DOWN) {
            objectManagerChannel.invokeMethod("onNodeTap", listOf(hitTestResult.node?.name))
            return true
        }
        if (motionEvent != null && motionEvent.action == MotionEvent.ACTION_DOWN) {
            if (transformationSystem.selectedNode == null || (!enablePans && !enableRotation)){
                val allHitResults = frame?.hitTest(motionEvent) ?: listOf<HitResult>()
                val planeAndPointHitResults =
                    allHitResults.filter { ((it.trackable is Plane) || (it.trackable is Point)) }
                val serializedPlaneAndPointHitResults: ArrayList<HashMap<String, Any>> =
                    ArrayList(planeAndPointHitResults.map { serializeHitResult(it) })
                sessionManagerChannel.invokeMethod(
                    "onPlaneOrPointTap",
                    serializedPlaneAndPointHitResults
                )
                return true
            } else {
                return false
            }

        }
        return false
    }

    private fun addPlaneAnchor(transform: ArrayList<Double>, name: String): Boolean {
        return try {
            val position = floatArrayOf(deserializeMatrix4(transform).second.x, deserializeMatrix4(transform).second.y, deserializeMatrix4(transform).second.z)
            val rotation = floatArrayOf(deserializeMatrix4(transform).third.x, deserializeMatrix4(transform).third.y, deserializeMatrix4(transform).third.z, deserializeMatrix4(transform).third.w)
            val anchor: Anchor = arSceneView.session!!.createAnchor(Pose(position, rotation))
            val anchorNode = AnchorNode(anchor)
            anchorNode.name = name
            anchorNode.setParent(arSceneView.scene)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun removeAnchor(name: String) {
        val anchorNode = arSceneView.scene.findByName(name) as AnchorNode?
        anchorNode?.let{
            // Remove corresponding anchor from tracking
            anchorNode.anchor?.detach()
            // Remove children
            for (node in anchorNode.children) {
                if (transformationSystem.selectedNode?.name == node.name){
                    transformationSystem.selectNode(null)
                    keepNodeSelected = true
                }
                node.setParent(null)
            }
            // Remove anchor node
            anchorNode.setParent(null)
        }
    }

    private inner class cloudAnchorUploadedListener: CloudAnchorHandler.CloudAnchorListener {
        override fun onCloudTaskComplete(anchorName: String?, anchor: Anchor?) {
            val cloudState = anchor!!.cloudAnchorState
            if (cloudState.isError) {
                Log.e(TAG, "Error uploading anchor, state $cloudState")
                sessionManagerChannel.invokeMethod("onError", listOf("Error uploading anchor, state $cloudState"))
                return
            }
            // Swap old an new anchor of the respective AnchorNode
            val anchorNode = arSceneView.scene.findByName(anchorName) as AnchorNode?
            val oldAnchor = anchorNode?.anchor
            anchorNode?.anchor = anchor
            oldAnchor?.detach()

            val args = HashMap<String, String?>()
            args["name"] = anchorName
            args["cloudanchorid"] = anchor.cloudAnchorId
            anchorManagerChannel.invokeMethod("onCloudAnchorUploaded", args)
        }
    }

    private inner class cloudAnchorDownloadedListener: CloudAnchorHandler.CloudAnchorListener {
        override fun onCloudTaskComplete(anchorName: String?, anchor: Anchor?) {
            val cloudState = anchor!!.cloudAnchorState
            if (cloudState.isError) {
                Log.e(TAG, "Error downloading anchor, state $cloudState")
                sessionManagerChannel.invokeMethod("onError", listOf("Error downloading anchor, state $cloudState"))
                return
            }
            //Log.d(TAG, "---------------- RESOLVING SUCCESSFUL ------------------")
            val newAnchorNode = AnchorNode(anchor)
            // Register new anchor on the Flutter side of the plugin
            anchorManagerChannel.invokeMethod("onAnchorDownloadSuccess", serializeAnchor(newAnchorNode, anchor), object: MethodChannel.Result {
                override fun success(result: Any?) {
                    newAnchorNode.name = result.toString()
                    newAnchorNode.setParent(arSceneView.scene)
                    //Log.d(TAG, "---------------- REGISTERING ANCHOR SUCCESSFUL ------------------")
                }

                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                    sessionManagerChannel.invokeMethod("onError", listOf("Error while registering downloaded anchor at the AR Flutter plugin: $errorMessage"))
                }

                override fun notImplemented() {
                    sessionManagerChannel.invokeMethod("onError", listOf("Error while registering downloaded anchor at the AR Flutter plugin"))
                }
            })
        }
    }

}


