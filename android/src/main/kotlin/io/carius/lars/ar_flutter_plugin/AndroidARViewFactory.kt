package io.carius.lars.ar_flutter_plugin

import android.app.Activity
import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class AndroidARViewFactory(val activity: Activity, val messenger: BinaryMessenger) :
        PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context?, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as Map<String?, Any?>?
        return AndroidARView(activity, context!!, messenger, viewId, creationParams)
    }
}
