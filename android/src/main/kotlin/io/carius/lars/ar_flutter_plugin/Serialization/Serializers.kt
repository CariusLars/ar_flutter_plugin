package io.carius.lars.ar_flutter_plugin.Serialization

import com.google.ar.core.HitResult
import com.google.ar.core.Plane
import com.google.ar.core.Point
import com.google.ar.core.Pose

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