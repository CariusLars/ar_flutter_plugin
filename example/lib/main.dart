import 'package:ar_flutter_plugin_example/examples/externalmodelmanagementexample.dart';
import 'package:ar_flutter_plugin_example/examples/objectsonplanesexample.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';

import 'package:ar_flutter_plugin_example/examples/cloudanchorexample.dart';
import 'package:ar_flutter_plugin_example/examples/localandwebobjectsexample.dart';
import 'package:ar_flutter_plugin_example/examples/debugoptionsexample.dart';

import 'examples/objectgesturesexample.dart';
import 'examples/screenshotexample.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  static const String _title = 'AR Plugin Demo';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await ArFlutterPlugin.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text(_title),
        ),
        body: Column(children: [
          Text('Running on: $_platformVersion\n'),
          Expanded(
            child: ExampleList(),
          ),
        ]),
      ),
    );
  }
}

class ExampleList extends StatelessWidget {
  ExampleList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final examples = [
      Example(
          'Debug Options',
          'Visualize feature points, planes and world coordinate system',
          () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => DebugOptionsWidget()))),
      Example(
          'Local & Online Objects',
          'Place 3D objects from Flutter assets and the web into the scene',
          () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => LocalAndWebObjectsWidget()))),
      Example(
          'Anchors & Objects on Planes',
          'Place 3D objects on detected planes using anchors',
          () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ObjectsOnPlanesWidget()))),
      Example(
          'Object Transformation Gestures',
          'Rotate and Pan Objects',
          () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => ObjectGesturesWidget()))),
      Example(
          'Screenshots',
          'Place 3D objects on planes and take screenshots',
          () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => ScreenshotWidget()))),
      Example(
          'Cloud Anchors',
          'Place and retrieve 3D objects using the Google Cloud Anchor API',
          () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => CloudAnchorWidget()))),
      Example(
          'External Model Management',
          'Similar to Cloud Anchors example, but uses external database to choose from available 3D models',
          () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ExternalModelManagementWidget())))
    ];
    return ListView(
      children:
          examples.map((example) => ExampleCard(example: example)).toList(),
    );
  }
}

class ExampleCard extends StatelessWidget {
  ExampleCard({Key? key, required this.example}) : super(key: key);
  final Example example;

  @override
  build(BuildContext context) {
    return Card(
      child: InkWell(
        splashColor: Colors.blue.withAlpha(30),
        onTap: () {
          example.onTap();
        },
        child: ListTile(
          title: Text(example.name),
          subtitle: Text(example.description),
        ),
      ),
    );
  }
}

class Example {
  const Example(this.name, this.description, this.onTap);
  final String name;
  final String description;
  final Function onTap;
}
