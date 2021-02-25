import UIKit
import Foundation
import ARKit

// Responsible for creating Renderables and Nodes
class ArModelBuilder: NSObject {

    func makePlane(anchor: ARPlaneAnchor, flutterAssetFile: String?) -> SCNNode {
        let plane = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        //Create material
        let material = SCNMaterial()
        let opacity: CGFloat
        
        if let textureSourcePath = flutterAssetFile {
            // Use given asset as plane texture
            let key = FlutterDartProject.lookupKey(forAsset: textureSourcePath)
            if let image = UIImage(named: key, in: Bundle.main,compatibleWith: nil){
                // Asset was found so we can use it
                material.diffuse.contents = image
                material.diffuse.wrapS = .repeat
                material.diffuse.wrapT = .repeat
                plane.materials = [material]
                opacity = 1.0
            } else {
                // Use standard planes
                opacity = 0.3
            }
        } else {
            // Use standard planes
            opacity = 0.3
        }
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
        // rotate plane by 90 degrees to match the anchor (planes are vertical by default)
        planeNode.eulerAngles.x = -.pi / 2

        planeNode.opacity = opacity

        return planeNode
    }

    func updatePlaneNode(planeNode: SCNNode, anchor: ARPlaneAnchor){
        if let plane = planeNode.geometry as? SCNPlane {
            // Update plane dimensions
            plane.width = CGFloat(anchor.extent.x)
            plane.height = CGFloat(anchor.extent.z)
            // Update texture of planes
            let imageSize: Float = 65 // in mm
            let repeatAmount: Float = 1000 / imageSize //how often per meter we need to repeat the image
            if let gridMaterial = plane.materials.first {
                gridMaterial.diffuse.contentsTransform = SCNMatrix4MakeScale(anchor.extent.x * repeatAmount, anchor.extent.z * repeatAmount, 1)
            }
        }
       planeNode.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
    }
}
