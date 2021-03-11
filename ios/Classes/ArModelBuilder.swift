import UIKit
import Foundation
import ARKit
import GLTFSceneKit
import Combine

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

    // Creates a node form a given gltf2 model path
    func makeNodeFromGltf(name: String, modelPath: String, transformation: Array<NSNumber>?) -> SCNNode? {
        
        var scene: SCNScene
        let node: SCNNode = SCNNode()

        do {
            let sceneSource = try GLTFSceneSource(named: modelPath)
            scene = try sceneSource.scene()

            for child in scene.rootNode.childNodes {
                child.scale = SCNVector3(0.01,0.01,0.01) // Compensate for the different model dimension definitions in iOS and Android (meters vs. millimeters)
                //child.eulerAngles.z = -.pi // Compensate for the different model coordinate definitions in iOS and Android
                //child.eulerAngles.y = -.pi // Compensate for the different model coordinate definitions in iOS and Android
                node.addChildNode(child)
            }

            node.name = name
            if let transform = transformation {
                node.transform = deserializeMatrix4(transform)
            }
            /*node.scale = worldScale
            node.position = worldPosition
            node.worldOrientation = worldRotation*/

            return node
        } catch {
            print("\(error.localizedDescription)")
            return nil
        }
    }
    
    // Creates a node form a given glb model path
    func makeNodeFromWebGlb(name: String, modelURL: String, transformation: Array<NSNumber>?) -> Future<SCNNode?, Never> {
        
        return Future {promise in
            var node: SCNNode? = SCNNode()
            
            let handler: (URL?, URLResponse?, Error?) -> Void = {(url: URL?, urlResponse: URLResponse?, error: Error?) -> Void in
                // If response code is not 200, link was invalid, so return
                if ((urlResponse as? HTTPURLResponse)?.statusCode != 200) {
                    print("makeNodeFromWebGltf received non-200 response code")
                    node = nil
                    promise(.success(node))
                } else {
                    guard let fileURL = url else { return }
                    do {
                        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                        let documentsDirectory = paths[0]
                        let targetURL = documentsDirectory.appendingPathComponent(urlResponse!.url!.lastPathComponent)
                        
                        try? FileManager.default.removeItem(at: targetURL) //remove item if it's already there
                        try FileManager.default.copyItem(at: fileURL, to: targetURL)

                        do {
                            let sceneSource = GLTFSceneSource(url: targetURL)
                            let scene = try sceneSource.scene()

                            for child in scene.rootNode.childNodes {
                                child.scale = SCNVector3(0.01,0.01,0.01) // Compensate for the different model dimension definitions in iOS and Android (meters vs. millimeters)
                                //child.eulerAngles.z = -.pi // Compensate for the different model coordinate definitions in iOS and Android
                                //child.eulerAngles.y = -.pi // Compensate for the different model coordinate definitions in iOS and Android
                                node?.addChildNode(child)
                            }

                            node?.name = name
                            if let transform = transformation {
                                node?.transform = deserializeMatrix4(transform)
                            }
                            /*node?.scale = worldScale
                            node?.position = worldPosition
                            node?.worldOrientation = worldRotation*/

                        } catch {
                            print("\(error.localizedDescription)")
                            node = nil
                        }
                        
                        // Delete file to avoid cluttering device storage (at some point, caching can be included)
                        try FileManager.default.removeItem(at: targetURL)
                        
                        promise(.success(node))
                    } catch {
                        node = nil
                        promise(.success(node))
                    }
                }
                
            }
            
    
            let downloadTask = URLSession.shared.downloadTask(with: URL(string: modelURL)!, completionHandler: handler)
            
            downloadTask.resume()
            
        }
        
    }
    
}
