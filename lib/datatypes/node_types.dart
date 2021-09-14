/// Determines which types of nodes the plugin supports
enum NodeType {
  localGLTF2, // Node with renderable with fileending .gltf in the Flutter asset folder
  webGLB, // Node with renderable with fileending .glb loaded from the internet during runtime
  fileSystemGLB, // Node with renderable with fileending .glb in the documents folder of the current app
}
