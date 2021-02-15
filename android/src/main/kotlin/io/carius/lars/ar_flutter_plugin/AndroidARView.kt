package io.carius.lars.ar_flutter_plugin

import android.content.Context
import android.view.View
import com.google.ar.core.*
import com.google.ar.sceneform.ArSceneView
import io.flutter.plugin.platform.PlatformView

internal class AndroidARView(context: Context, id: Int, creationParams: Map<String?, Any?>?) :
        PlatformView {
    // private val textView: TextView
    private lateinit var arSceneView: ArSceneView

    override fun getView(): View {
        return arSceneView
    }

    override fun dispose() {}

    init {
        // textView = TextView(context)
        // textView.textSize = 72f
        // textView.setBackgroundColor(Color.rgb(255, 255, 255))
        // textView.text = "Rendered on a native Android view (id: $id)"
        arSceneView = ArSceneView(context)

        // if (ArCoreUtils.hasCameraPermission(context)) {
        //    Log.d("test", "permission exists")
        // } else {
        //    Log.d("test", "no permission")
        // }
    }
}
