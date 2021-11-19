import Foundation
import ARKit
import ARCoreCloudAnchors

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

func serializeAnchor(anchor: ARAnchor, anchorNode: SCNNode?, ganchor: GARAnchor, name: String?) -> Dictionary<String, Any?> {
    var serializedAnchor = Dictionary<String, Any?>()
    
    serializedAnchor["type"] = 0 // index for plane anchors
    serializedAnchor["name"] = name
    serializedAnchor["cloudanchorid"] = ganchor.cloudIdentifier
    serializedAnchor["transformation"] = serializeMatrix(anchor.transform)
    serializedAnchor["childNodes"] = anchorNode?.childNodes.map{$0.name}

    return serializedAnchor
}

func serializeLocalTransformation(node: SCNNode?) -> Dictionary<String, Any?> {
    var serializedLocalTransformation = Dictionary<String, Any?>()

    let transform: [Float?] = [node?.transform.m11, node?.transform.m12, node?.transform.m13, node?.transform.m14, node?.transform.m21, node?.transform.m22, node?.transform.m23, node?.transform.m24, node?.transform.m31, node?.transform.m32, node?.transform.m33, node?.transform.m34, node?.transform.m41, node?.transform.m42, node?.transform.m43, node?.transform.m44]
    
    serializedLocalTransformation["name"] = node?.name
    serializedLocalTransformation["transform"] = transform

    return serializedLocalTransformation
}
