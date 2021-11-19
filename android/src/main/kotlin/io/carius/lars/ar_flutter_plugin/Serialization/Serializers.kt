package io.carius.lars.ar_flutter_plugin.Serialization

import com.google.ar.core.*
import com.google.ar.sceneform.AnchorNode
import com.google.ar.sceneform.math.Matrix
import com.google.ar.sceneform.math.Quaternion
import com.google.ar.sceneform.math.Vector3
import com.google.ar.sceneform.ux.BaseTransformableNode
import com.google.ar.sceneform.ux.TransformableNode

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

fun serializePoseWithScale(pose: Pose, scale: Vector3): DoubleArray {
    val serializedPose = FloatArray(16)
    pose.toMatrix(serializedPose, 0)
    // copy into double Array
    val serializedPoseDouble = DoubleArray(serializedPose.size)
    for (i in serializedPose.indices) {
        serializedPoseDouble[i] = serializedPose[i].toDouble()
        if (i == 0 || i == 4 || i == 8){
            serializedPoseDouble[i] = serializedPoseDouble[i] * scale.x
        }
        if (i == 1 || i == 5 || i == 9){
            serializedPoseDouble[i] = serializedPoseDouble[i] * scale.y
        }
        if (i == 2 || i == 7 || i == 10){
            serializedPoseDouble[i] = serializedPoseDouble[i] * scale.z
        }
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

fun serializeLocalTransformation(node: BaseTransformableNode): HashMap<String, Any>{
    val serializedLocalTransformation = HashMap<String, Any>()
    serializedLocalTransformation["name"] = node.name

    val transform = Pose(floatArrayOf(node.localPosition.x, node.localPosition.y, node.localPosition.z), floatArrayOf(node.localRotation.x, node.localRotation.y, node.localRotation.z, node.localRotation.w))

    serializedLocalTransformation["transform"] = serializePoseWithScale(transform, node.localScale)

    return serializedLocalTransformation
}
