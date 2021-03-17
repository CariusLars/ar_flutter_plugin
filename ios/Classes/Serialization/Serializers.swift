import Foundation
import ARKit

func serializeHitResult(_ result: ARHitTestResult) -> Dictionary<String, Any> {
    
    var hitResult = Dictionary<String, Any>(minimumCapacity: 3)
    if (result.type == .existingPlaneUsingExtent || result.type == .existingPlaneUsingGeometry || result.type == .existingPlane) {
        hitResult["type"] = 1 // Type plane
    } else if (result.type == .featurePoint) {
        hitResult["type"] = 2 // Type point
    } else {
        hitResult["type"] = 0 // Type undefined
    }
    hitResult["distance"] = result.distance
    hitResult["worldTransform"] = serializeMatrix(result.worldTransform)
    return hitResult
}

// The following code is adapted from Oleksandr Leuschenko' ARKit Flutter Plugin (https://github.com/olexale/arkit_flutter_plugin)

func serializeMatrix(_ matrix: simd_float4x4) -> Array<Float> {
    return [matrix.columns.0, matrix.columns.1, matrix.columns.2, matrix.columns.3].flatMap { serializeArray($0) }
}

func serializeArray(_ array: simd_float4) -> Array<Float> {
    return [array[0], array[1], array[2], array[3]]
}
