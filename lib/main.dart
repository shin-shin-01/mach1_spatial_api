// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const platform = MethodChannel('audio');

  double x = 0.0;
  double y = 0.0;
  double z = 0.0;

  Future<void> _startAudio() async {
    print("startMethod: _startAudio");
    try {
      await platform.invokeMethod('playAudio', [x, y, z]);
    } on PlatformException catch (e) {
      print(e);
    }
  }

  Future<void> _stopAudio() async {
    print("startMethod: _stopAudio");
    try {
      await platform.invokeMethod('stopAudio');
    } on PlatformException catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Audio!',
            ),
            ElevatedButton(
              child: const Text('playAudio'),
              onPressed: _startAudio,
            ),
            ElevatedButton(
              child: const Text('stopAudio'),
              onPressed: _stopAudio,
            ),
            const Text('x'),
            _xSlider(),
            const Text('y'),
            _ySlider(),
            const Text('z'),
            _zSlider()
          ],
        ),
      ),
    );
  }

  Widget _xSlider() {
    return Slider(
        label: x.toStringAsFixed(2),
        min: -3,
        max: 3,
        value: x,
        activeColor: Colors.blueAccent,
        inactiveColor: Colors.grey,
        divisions: 10,
        onChanged: (double val) => setState(() {
              x = val;
              _startAudio();
            }));
  }

  Widget _ySlider() {
    return Slider(
        label: y.toStringAsFixed(2),
        min: -3,
        max: 3,
        value: y,
        activeColor: Colors.blueAccent,
        inactiveColor: Colors.grey,
        divisions: 10,
        onChanged: (double val) => setState(() {
              y = val;
              _startAudio();
            }));
  }

  Widget _zSlider() {
    return Slider(
        label: z.toStringAsFixed(2),
        min: -3,
        max: 3,
        value: z,
        activeColor: Colors.blueAccent,
        inactiveColor: Colors.grey,
        divisions: 10,
        onChanged: (double val) => setState(() {
              z = val;
              _startAudio();
            }));
  }
}
