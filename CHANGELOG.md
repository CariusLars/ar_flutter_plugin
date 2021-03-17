# Changelog

## 0.2.0

* Adds AR Anchor as a common representation of anchors on all platforms
* Implements AR Plane Anchor as subclass of AR Anchor: Plane Anchors can be created in Flutter, registered on the target platform and then be used to attach nodes to
* Adds AR Hittest Result as a common representation of hittest results on all platforms. If the setting is activated in the session manager, taps on the platforms are registered and hit test results can be used to trigger callbacks in Flutter (example: hit result world coordinate transforms can be used to place anchors or nodes into the scene)
* Adds option to trigger callbacks when nodes are tapped
* Adds example to showcase hittests, creating and placing anchors and attaching nodes to anchors

## 0.1.0

* Adds AR Node as a common representation of nodes on all platforms
* Custom objects (GLTF2 models from Flutter's asset folders or GLB models from the Internet) can be attached to nodes and are loaded / downloaded asynchronously during runtime to ensure maximum flexibility
* AR Nodes (with attached objects) can be placed in the scene with respect to the world coordinate system, position, rotation and scale can be set and updated during runtime
* Updates debug option functionality: options can be changed at runtime (see Debug Option example)
* Updates examples to showcase current state of the plugin

## 0.0.1

* Coarse Plugin Architecture layed out
* ARView supports iOS (ARKit) and Android (ARCore) devices
* Camera Permission checks added
* Debug options added on both platforms: Feature Points visualization, detected planes visualization and world origin visualization
* Adds possibility to use own texture for plane visualization on both platforms
