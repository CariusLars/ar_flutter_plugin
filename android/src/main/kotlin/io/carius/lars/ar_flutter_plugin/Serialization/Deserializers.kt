package io.carius.lars.ar_flutter_plugin.Serialization

import com.google.ar.sceneform.math.Quaternion
import com.google.ar.sceneform.math.Vector3


fun deserializeMatrix4(transform: ArrayList<Double>): Triple<Vector3, Vector3, Quaternion> {
    val scale = Vector3()
    val position = Vector3()
    val rotation: Quaternion

    scale.x = Vector3(transform[0].toFloat(), transform[1].toFloat(), transform[2].toFloat()).length()
    scale.y = Vector3(transform[4].toFloat(), transform[5].toFloat(), transform[6].toFloat()).length()
    scale.z = Vector3(transform[8].toFloat(), transform[9].toFloat(), transform[10].toFloat()).length()

    position.x = transform[12].toFloat()
    position.y = transform[13].toFloat()
    position.z = transform[14].toFloat()

    val correction_z = Quaternion(0.0f, 0.0f, 1.0f, 180f)
    val correction_y = Quaternion(0.0f, 1.0f, 0.0f, 180f)
    val rowWiseMatrix = floatArrayOf(transform[0].toFloat() / scale.x, transform[4].toFloat() / scale.y, transform[8].toFloat() / scale.z, transform[1].toFloat() / scale.x, transform[5].toFloat() / scale.y, transform[9].toFloat() / scale.z, transform[2].toFloat() / scale.x, transform[6].toFloat() / scale.y, transform[10].toFloat() / scale.z)

    val w = Math.sqrt(1.0 + rowWiseMatrix[0] + rowWiseMatrix[4] + rowWiseMatrix[8]) / 2.0
    val w4: Double = 4.0 * w
    val x = (rowWiseMatrix[7] - rowWiseMatrix[5]) / w4
    val y = (rowWiseMatrix[2] - rowWiseMatrix[6]) / w4
    val z = (rowWiseMatrix[3] - rowWiseMatrix[1]) / w4

    val inputRotation = Quaternion(x.toFloat(),y.toFloat(),z.toFloat(),w.toFloat())
    rotation = Quaternion.multiply(Quaternion.multiply(inputRotation, correction_y), correction_z)

    return Triple(scale, position, rotation)
}
