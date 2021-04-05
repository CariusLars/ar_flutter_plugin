package io.carius.lars.ar_flutter_plugin

import com.google.ar.core.Anchor
import com.google.ar.core.Anchor.CloudAnchorState
import com.google.ar.core.Session
import java.util.*

// Class for handling logic regarding the Google Cloud Anchor API
internal class CloudAnchorHandler( arSession: Session ) {

    // Listener that can be attached to hosing or resolving processes
    interface CloudAnchorListener {
        // Callback to invoke when cloud anchor task finishes
        fun onCloudTaskComplete(anchorName: String?, anchor: Anchor?)
    }

    private val TAG: String = CloudAnchorHandler::class.java.simpleName
    private val pendingAnchors = HashMap<Anchor, Pair<String?, CloudAnchorListener?>>()
    private val session: Session = arSession

    @Synchronized
    fun hostCloudAnchor(anchorName: String, anchor: Anchor?, listener: CloudAnchorListener?) {
        val newAnchor = session.hostCloudAnchor(anchor)
        // Register listener so it is invoked when the operation finishes
        pendingAnchors[newAnchor] = Pair(anchorName, listener)
    }

    @Synchronized
    fun hostCloudAnchorWithTtl(anchorName: String, anchor: Anchor?, listener: CloudAnchorListener?, ttl: Int) {
        val newAnchor = session.hostCloudAnchorWithTtl(anchor, ttl)
        // Register listener so it is invoked when the operation finishes
        pendingAnchors[newAnchor] = Pair(anchorName, listener)
    }

    @Synchronized
    fun resolveCloudAnchor(anchorId: String?, listener: CloudAnchorListener?) {
        val newAnchor = session.resolveCloudAnchor(anchorId)
        // Register listener so it is invoked when the operation finishes
        pendingAnchors[newAnchor] = Pair(null, listener)
    }

    // Updating function that should be called after each session.update call
    @Synchronized
    fun onUpdate(updatedAnchors: Collection<Anchor>) {
        for (anchor in updatedAnchors) {
            if (pendingAnchors.containsKey(anchor)) {
                if (anchor.cloudAnchorState != CloudAnchorState.NONE && anchor.cloudAnchorState != CloudAnchorState.TASK_IN_PROGRESS){
                    val element: Pair<String?, CloudAnchorListener?>? = pendingAnchors.remove(anchor)
                    element!!.second!!.onCloudTaskComplete(element.first, anchor)
                }
            }
        }
    }

    // Remove all listeners
    @Synchronized
    fun clearListeners() {
        pendingAnchors.clear()
    }

}
