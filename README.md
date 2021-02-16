# ar_flutter_plugin

Flutter Plugin for AR (Augmented Reality) - Supports ARKit for iOS and ARCore for Android devices.

Many thanks to Oleksandr Leuschenko for the [arkit_flutter_plugin](https://github.com/olexale/arkit_flutter_plugin) and to Gian Marco Di Francesco for the [arcore_flutter_plugin](https://github.com/giandifra/arcore_flutter_plugin) which both served as a great basis and starting point for this project.

## Getting Started

This plugin is still a work in progress and not usable right now. Keep posted for updates or contribute by creating a [pull request](https://github.com/CariusLars/ar_flutter_plugin/compare)!

## Roadmap

The first goal of this plugin is to provide collaborative AR functionality through cloud anchors on Android and iOS. The plugin will provide an easy interface for placing custom models (ideally from the web) onto planes and sharing the annotations across devices through app-specific channels (to allow "subscription" of certain annotations). GPS-tagging anchors will be supported to allow efficient querying of anchors by a device's location. A first architecture could look like this: 

![ar_plugin_architecture](./AR_Plugin_Architecture_lowlevel.svg)

The cloud backends shown above are only exemplary, the plugin will allow the user to attach their own backend, an example utilizing Firebase will be added to the /example folder.

Later, additional functionality like image anchors, light estimation, etc. will be added to create a full-fledged cross-platform AR plugin for flutter.

## Contributing

Contributions to this plugin are very welcome. To contribute code and discuss ideas, [create a pull request](https://github.com/CariusLars/ar_flutter_plugin/compare) or [open an issue](https://github.com/CariusLars/ar_flutter_plugin/issues/new).
