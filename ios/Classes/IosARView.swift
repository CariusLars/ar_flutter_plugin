import Flutter
import UIKit
import Foundation
import ARKit

class IosARView: NSObject, FlutterPlatformView, ARSCNViewDelegate {
    let sceneView: ARSCNView
    let channel: FlutterMethodChannel

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        self.sceneView = ARSCNView(frame: frame)
        self.channel = FlutterMethodChannel(name: "arsession_\(viewId)", binaryMessenger: messenger)
        super.init()

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints,ARSCNDebugOptions.showWorldOrigin]    
        self.sceneView.delegate = self
        self.sceneView.session.run(configuration)

        self.channel.setMethodCallHandler(self.onMethodCalled)
    }

    func view() -> UIView {
        return self.sceneView
    }

    func onMethodCalled(_ call :FlutterMethodCall, _ result:FlutterResult) {
        let arguments = call.arguments as? Dictionary<String, Any>
          
        switch call.method {
            case "init":
                self.channel.invokeMethod("onError", arguments: ["TEST"])
                result(nil)
                break
            default:
                result(FlutterMethodNotImplemented)
                break
        }
    }
}
