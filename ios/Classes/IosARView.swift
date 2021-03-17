import Flutter
import UIKit
import Foundation
import ARKit
import Combine

class IosARView: NSObject, FlutterPlatformView, ARSCNViewDelegate, UIGestureRecognizerDelegate {
    let sceneView: ARSCNView
    let sessionManagerChannel: FlutterMethodChannel
    let objectManagerChannel: FlutterMethodChannel
    let anchorManagerChannel: FlutterMethodChannel
    var showPlanes = false
    var customPlaneTexturePath: String? = nil
    private var trackedPlanes = [UUID: (SCNNode, SCNNode)]()
    let modelBuilder = ArModelBuilder()
    
    var cancellableCollection = Set<AnyCancellable>() //Used to store all cancellables in (needed for working with Futures)
    var anchorCollection = [String: ARAnchor]() //Used to bookkeep all anchors created by Flutter calls

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        self.sceneView = ARSCNView(frame: frame)
        self.sessionManagerChannel = FlutterMethodChannel(name: "arsession_\(viewId)", binaryMessenger: messenger)
        self.objectManagerChannel = FlutterMethodChannel(name: "arobjects_\(viewId)", binaryMessenger: messenger)
        self.anchorManagerChannel = FlutterMethodChannel(name: "aranchors_\(viewId)", binaryMessenger: messenger)
        super.init()

        let configuration = ARWorldTrackingConfiguration() // Create default configuration before initializeARView is called
        self.sceneView.delegate = self
        self.sceneView.session.run(configuration)

        self.sessionManagerChannel.setMethodCallHandler(self.onSessionMethodCalled)
        self.objectManagerChannel.setMethodCallHandler(self.onObjectMethodCalled)
        self.anchorManagerChannel.setMethodCallHandler(self.onAnchorMethodCalled)
    }

    func view() -> UIView {
        return self.sceneView
    }

    func onSessionMethodCalled(_ call :FlutterMethodCall, _ result:FlutterResult) {
        let arguments = call.arguments as? Dictionary<String, Any>
          
        switch call.method {
            case "init":
                //self.sessionManagerChannel.invokeMethod("onError", arguments: ["SessionTEST from iOS"])
                //result(nil)
                initializeARView(arguments: arguments!, result: result)
                break
            default:
                result(FlutterMethodNotImplemented)
                break
        }
    }

    func onObjectMethodCalled(_ call :FlutterMethodCall, _ result: @escaping FlutterResult) {
        let arguments = call.arguments as? Dictionary<String, Any>
          
        switch call.method {
            case "init":
                self.objectManagerChannel.invokeMethod("onError", arguments: ["ObjectTEST from iOS"])
                result(nil)
                break
            case "addNode":
                addNode(dict_node: arguments!).sink(receiveCompletion: {completion in }, receiveValue: { val in
                       result(val)
                    }).store(in: &self.cancellableCollection)
                break
            case "addNodeToPlaneAnchor":
                if let dict_node = arguments!["node"] as? Dictionary<String, Any>, let dict_anchor = arguments!["anchor"] as? Dictionary<String, Any> {
                    addNode(dict_node: dict_node, dict_anchor: dict_anchor).sink(receiveCompletion: {completion in }, receiveValue: { val in
                           result(val)
                        }).store(in: &self.cancellableCollection)
                }
                break
            case "removeNode":
                if let name = arguments!["name"] as? String {
                    sceneView.scene.rootNode.childNode(withName: name, recursively: true)?.removeFromParentNode()
                }
                break
            case "transformationChanged":
                if let name = arguments!["name"] as? String, let transform = arguments!["transformation"] as? Array<NSNumber> {
                    transformNode(name: name, transform: transform)
                    result(nil)
                }
                break
            default:
                result(FlutterMethodNotImplemented)
                break
        }
    }

    func onAnchorMethodCalled(_ call :FlutterMethodCall, _ result: @escaping FlutterResult) {
        let arguments = call.arguments as? Dictionary<String, Any>
          
        switch call.method {
            case "init":
                self.objectManagerChannel.invokeMethod("onError", arguments: ["ObjectTEST from iOS"])
                result(nil)
                break
            case "addAnchor":
                if let type = arguments!["type"] as? Int {
                    switch type {
                    case 0: //Plane Anchor
                        if let transform = arguments!["transformation"] as? Array<NSNumber>, let name = arguments!["name"] as? String {
                            addPlaneAnchor(transform: transform, name: name)
                            result(true)
                        }
                        result(false)
                        break
                    default:
                        result(false)
                    
                    }
                }
                result(nil)
                break
            case "removeAnchor":
                if let name = arguments!["name"] as? String {
                    deleteAnchor(anchorName: name)
                }
                break
            default:
                result(FlutterMethodNotImplemented)
                break
        }
    }

    func initializeARView(arguments: Dictionary<String,Any>, result: FlutterResult){
        // Set plane detection configuration
        let configuration = ARWorldTrackingConfiguration()
        if let planeDetectionConfig = arguments["planeDetectionConfig"] as? Int {
            switch planeDetectionConfig {
                case 1: 
                    configuration.planeDetection = .horizontal
                
                case 2: 
                    if #available(iOS 11.3, *) {
                        configuration.planeDetection = .vertical
                    }
                case 3: 
                    if #available(iOS 11.3, *) {
                        configuration.planeDetection = [.horizontal, .vertical]
                    }
                default: 
                    configuration.planeDetection = []
            }
        }

        // Set plane rendering options
        if let configShowPlanes = arguments["showPlanes"] as? Bool {
            showPlanes = configShowPlanes
            if (showPlanes){
                // Visualize currently tracked planes
                for plane in trackedPlanes.values {
                    plane.0.addChildNode(plane.1)
                }
            } else {
                // Remove currently visualized planes
                for plane in trackedPlanes.values {
                    plane.1.removeFromParentNode()
                }
            }
        }
        if let configCustomPlaneTexturePath = arguments["customPlaneTexturePath"] as? String {
            customPlaneTexturePath = configCustomPlaneTexturePath
        }

        // Set debug options
        var debugOptions = ARSCNDebugOptions().rawValue
        if let showFeaturePoints = arguments["showFeaturePoints"] as? Bool {
            if (showFeaturePoints) {
                debugOptions |= ARSCNDebugOptions.showFeaturePoints.rawValue
            }
        }
        if let showWorldOrigin = arguments["showWorldOrigin"] as? Bool {
            if (showWorldOrigin) {
                debugOptions |= ARSCNDebugOptions.showWorldOrigin.rawValue
            }
        }
        self.sceneView.debugOptions = ARSCNDebugOptions(rawValue: debugOptions)
        
        if let configHandleTaps = arguments["handleTaps"] as? Bool {
            if (configHandleTaps){
                let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
                tapGestureRecognizer.delegate = self
                self.sceneView.gestureRecognizers?.append(tapGestureRecognizer)
            }
        }
    
        // Update session configuration
        self.sceneView.session.run(configuration)
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        if let planeAnchor = anchor as? ARPlaneAnchor{
            let plane = modelBuilder.makePlane(anchor: planeAnchor, flutterAssetFile: customPlaneTexturePath)
            trackedPlanes[anchor.identifier] = (node, plane)
            if (showPlanes) {
                node.addChildNode(plane)
            }
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        if let planeAnchor = anchor as? ARPlaneAnchor, let plane = trackedPlanes[anchor.identifier] {
            modelBuilder.updatePlaneNode(planeNode: plane.1, anchor: planeAnchor)
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        trackedPlanes.removeValue(forKey: anchor.identifier)
    }

    func addNode(dict_node: Dictionary<String, Any>, dict_anchor: Dictionary<String, Any>? = nil) -> Future<Bool, Never> {

        return Future {promise in
            
            switch (dict_node["type"] as! Int) {
                case 0: // GLTF2 Model from Flutter asset folder
                    // Get path to given Flutter asset
                    let key = FlutterDartProject.lookupKey(forAsset: dict_node["uri"] as! String)
                    // Add object to scene
                    if let node: SCNNode = self.modelBuilder.makeNodeFromGltf(name: dict_node["name"] as! String, modelPath: key, transformation: dict_node["transform"] as? Array<NSNumber>) {
                        if let anchorName = dict_anchor?["name"] as? String, let anchorType = dict_anchor?["type"] as? Int {
                            switch anchorType{
                                case 0: //PlaneAnchor
                                    if let anchor = self.anchorCollection[anchorName]{
                                        // Attach node to the top-level node of the specified anchor
                                        self.sceneView.node(for: anchor)?.addChildNode(node)
                                    } else {
                                        promise(.success(false))
                                    }
                                default:
                                    promise(.success(false))
                                }
                            
                        } else {
                            // Attach to top-level node of the scene
                            self.sceneView.scene.rootNode.addChildNode(node)
                        }
                        promise(.success(true))
                    } else {
                        self.sessionManagerChannel.invokeMethod("onError", arguments: ["Unable to load renderable \(dict_node["uri"] as! String)"])
                        promise(.success(false))
                    }
                    break
                case 1: // GLB Model from the web
                    // Add object to scene
                    self.modelBuilder.makeNodeFromWebGlb(name: dict_node["name"] as! String, modelURL: dict_node["uri"] as! String, transformation: dict_node["transform"] as? Array<NSNumber>)
                    .sink(receiveCompletion: {
                                    completion in print("Async Model Downloading Task completed: ", completion)
                    }, receiveValue: { val in
                        if let node: SCNNode = val {
                            if let anchorName = dict_anchor?["name"] as? String, let anchorType = dict_anchor?["type"] as? Int {
                                switch anchorType{
                                    case 0: //PlaneAnchor
                                        if let anchor = self.anchorCollection[anchorName]{
                                            // Attach node to the top-level node of the specified anchor
                                            self.sceneView.node(for: anchor)?.addChildNode(node)
                                        } else {
                                            promise(.success(false))
                                        }
                                    default:
                                        promise(.success(false))
                                    }
                                
                            } else {
                                // Attach to top-level node of the scene
                                self.sceneView.scene.rootNode.addChildNode(node)
                            }
                            promise(.success(true))
                        } else {
                            self.sessionManagerChannel.invokeMethod("onError", arguments: ["Unable to load renderable \(dict_node["name"] as! String)"])
                            promise(.success(false))
                        }
                    }).store(in: &self.cancellableCollection)
                    break
                default:
                    promise(.success(false))
            }
            
        }
    }
    
    func transformNode(name: String, transform: Array<NSNumber>) {
        let node = sceneView.scene.rootNode.childNode(withName: name, recursively: true)
        node?.transform = deserializeMatrix4(transform)
    }
    
    @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
        guard let sceneView = recognizer.view as? ARSCNView else {
            return
        }
        let touchLocation = recognizer.location(in: sceneView)
    
        let allHitResults = sceneView.hitTest(touchLocation, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.closest.rawValue])
        // Because 3D model loading can lead to composed nodes, we have to traverse through a node's parent until the parent node with the name assigned by the Flutter API is found
        let nodeHitResults: Array<String> = allHitResults.compactMap { nearestParentWithNameStart(node: $0.node, characters: "[#")?.name }
        if (nodeHitResults.count != 0) {
            self.objectManagerChannel.invokeMethod("onNodeTap", arguments: nodeHitResults)
            return
        }
            
        let planeTypes: ARHitTestResult.ResultType
        if #available(iOS 11.3, *){
            planeTypes = ARHitTestResult.ResultType([.existingPlaneUsingGeometry, .featurePoint])
        }else {
            planeTypes = ARHitTestResult.ResultType([.existingPlaneUsingExtent, .featurePoint])
        }
        
        let planeAndPointHitResults = sceneView.hitTest(touchLocation, types: planeTypes)
            
        let serializedPlaneAndPointHitResults = planeAndPointHitResults.map{serializeHitResult($0)}
            if (serializedPlaneAndPointHitResults.count != 0) {
                self.sessionManagerChannel.invokeMethod("onPlaneOrPointTap", arguments: serializedPlaneAndPointHitResults)
            }
        }
    // Recursive helper function to traverse a node's parents until a node with a name starting with the specified characters is found
    func nearestParentWithNameStart(node: SCNNode?, characters: String) -> SCNNode? {
        if let nodeNamePrefix = node?.name?.prefix(characters.count) {
            if (nodeNamePrefix == characters) { return node }
        }
        if let parent = node?.parent { return nearestParentWithNameStart(node: parent, characters: characters) }
        return nil
    }
    
    func addPlaneAnchor(transform: Array<NSNumber>, name: String){
        let arAnchor = ARAnchor(transform: simd_float4x4(deserializeMatrix4(transform)))
        anchorCollection[name] = arAnchor
        sceneView.session.add(anchor: arAnchor)
        // Ensure root node is added to anchor before any other function can run (if this isn't done, addNode could fail because anchor does not have a root node yet).
        // The root node is added to the anchor as soon as the async rendering loop runs once, more specifically the function "renderer(_:nodeFor:)"
        while (sceneView.node(for: arAnchor) == nil) {
            usleep(1) // wait 1 millionth of a second
        }
    }
    
    func deleteAnchor(anchorName: String) {
        if let anchor = anchorCollection[anchorName]{
            // Delete all child nodes
            if var attachedNodes = sceneView.node(for: anchor)?.childNodes {
                attachedNodes.removeAll()
            }
            // Remove anchor
            sceneView.session.remove(anchor: anchor)
            // Update bookkeeping
            anchorCollection.removeValue(forKey: anchorName)
        }
        
        
    }
        
}
