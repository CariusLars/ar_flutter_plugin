package io.carius.lars.ar_flutter_plugin.Serialization

import com.google.ar.core.*
import com.google.ar.sceneform.AnchorNode

fun serializeHitResult(hitResult: HitResult): HashMap<String, Any> {
    val serializedHitResult = HashMap<String,Any>()

    if (hitResult.trackable is Plane && (hitResult.trackable as Plane).isPoseInPolygon(hitResult.hitPose)) {
        serializedHitResult["type"] = 1 // Type plane
    }
    else if (hitResult.trackable is Point){
        serializedHitResult["type"] = 2 // Type point
    } else {
        serializedHitResult["type"] = 0 // Type undefined
    }

    serializedHitResult["distance"] = hitResult.distance.toDouble()
    serializedHitResult["worldTransform"] = serializePose(hitResult.hitPose)

    return serializedHitResult
}

fun serializePose(pose: Pose): DoubleArray {
    val serializedPose = FloatArray(16)
    pose.toMatrix(serializedPose, 0)
    // copy into double Array
    val serializedPoseDouble = DoubleArray(serializedPose.size)
    for (i in serializedPose.indices) {
        serializedPoseDouble[i] = serializedPose[i].toDouble()
    }
    return serializedPoseDouble
}

fun serializeAnchor(anchorNode: AnchorNode, anchor: Anchor?): HashMap<String, Any?> {
    val serializedAnchor = HashMap<String, Any?>()
    serializedAnchor["type"] = 0 // index for plane anchors
    serializedAnchor["name"] = anchorNode.name
    serializedAnchor["cloudanchorid"] = anchor?.cloudAnchorId
    serializedAnchor["transformation"] = if (anchor != null) serializePose(anchor.pose) else null
    serializedAnchor["childNodes"] = anchorNode.children.map { child -> child.name }

    return serializedAnchor
}