# Changelog

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
