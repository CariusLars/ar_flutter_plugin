import Flutter
import UIKit
import Foundation
import ARKit

class IosARView: NSObject, FlutterPlatformView {
    private var _sceneView: ARSCNView

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        _sceneView = ARSCNView(frame: frame)
        super.init()
        _sceneView.delegate = self
        _sceneView.seesion.run()
    }

    func view() -> UIView {
        return _sceneView
    }

    //func createNativeView(view _view: UIView){
    //    _view.backgroundColor = UIColor.blue
    //    let nativeLabel = UILabel()
    //    nativeLabel.text = "Native text from iOS"
    //    nativeLabel.textColor = UIColor.white
    //    nativeLabel.textAlignment = .center
    //    nativeLabel.frame = CGRect(x: 0, y: 0, width: 180, height: 48.0)
    //    _view.addSubview(nativeLabel)
    //}
}
