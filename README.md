# ar_flutter_plugin

Flutter Plugin for AR (Augmented Reality) - Supports ARKit for iOS and ARCore for Android devices.

Many thanks to Oleksandr Leuschenko for the [arkit_flutter_plugin](https://github.com/olexale/arkit_flutter_plugin) and to Gian Marco Di Francesco for the [arcore_flutter_plugin](https://github.com/giandifra/arcore_flutter_plugin) which both served as a great basis and starting point for this project.

## Getting Started

This plugin is still a work in progress. Keep posted for updates or contribute by creating a [pull request](https://github.com/CariusLars/ar_flutter_plugin/compare)!

If you still want to use the plugin before it's officially released, add the following to your `pubspec.yaml` file:
```yaml
dependencies:
  ar_flutter_plugin:
    git: git://github.com/CariusLars/ar_flutter_plugin.git
```

To try out the plugin, it is best to have a look at one of the following examples implemented in the `Example` app:


| Example Name                | Description                                                                                                                                                                                                                                                                            | Link to Code                                                                                                                                   |
| --------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| Debug Options               | Simple AR scene with toggles to visualize the world origin, feature points and tracked planes                                                                                                                                                                                          | [Debug Options Code](https://github.com/CariusLars/ar_flutter_plugin/blob/main/example/lib/examples/debugoptionsexample.dart)                  |
| Local & Online Objets       | AR scene with buttons to place GLTF objects from the flutter asset folders or GLB objects from the internet at a given position, rotation and scale. Additional buttons allow to modify scale, position and orientation with regard to the world origin after objects have been placed | [Local & Online Objects Code](https://github.com/CariusLars/ar_flutter_plugin/blob/main/example/lib/examples/localandwebobjectsexample.dart)   |
| Objects & Anchors on Planes | AR Scene in which tapping on a plane creates an anchor with a 3D model attached to it                                                                                                                                                                                                  | [Objects & Anchors on Planes Code](https://github.com/CariusLars/ar_flutter_plugin/blob/main/example/lib/examples/objectsonplanesexample.dart) |
| GPS Objects                 | Place 3D objects into the scene using their GPS coordinates objects.                                                                                                                                                                                                                   | [GPS Objects Code](https://github.com/CariusLars/ar_flutter_plugin/blob/main/example/lib/examples/gpsobjectsexample.dart)                      |
| Cloud Anchors               | NOT IMPLEMENTED YET. Will allow to place, upload and download objects.                                                                                                                                                                                                                 | [Cloud Anchors Code](https://github.com/CariusLars/ar_flutter_plugin/blob/main/example/lib/examples/cloudanchorexample.dart)                   |


## Roadmap

The first goal of this plugin is to provide collaborative AR functionality through cloud anchors on Android and iOS. The plugin will provide an easy interface for placing custom models (ideally from the web) onto planes and sharing the annotations across devices through app-specific channels (to allow "subscription" of certain annotations). GPS-tagging anchors will be supported to allow efficient querying of anchors by a device's location. A first architecture could look like this: 

![ar_plugin_architecture](./AR_Plugin_Architecture_lowlevel.svg)

The cloud backends shown above are only exemplary, the plugin will allow the user to attach their own backend, an example utilizing Firebase will be added to the /example folder.

Later, additional functionality like image anchors, light estimation, etc. will be added to create a full-fledged cross-platform AR plugin for flutter.

## Contributing

Contributions to this plugin are very welcome. To contribute code and discuss ideas, [create a pull request](https://github.com/CariusLars/ar_flutter_plugin/compare) or [open an issue](https://github.com/CariusLars/ar_flutter_plugin/issues/new).
