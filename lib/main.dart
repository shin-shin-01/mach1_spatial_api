// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 向き指定
  // it is expected that the app will be used in Portrait mode held in hand and will assume 0 values for...
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
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

  // 目的地までの距離
  double x = 0.0;
  double y = 0.0;
  double z = 0.0;

  // 回転角
  bool bUseHeadphoneOrientationData = false;
  double yaw = 0.0;
  double pitch = 0.0;
  double roll = 0.0;

  // 位置情報
  double latitude = 0.0;
  double longitude = 0.0;

  final LocationSettings locationSettings =
      const LocationSettings(accuracy: LocationAccuracy.best);

  @override
  void initState() {
    super.initState();

    Future(() async {
      await checkPermission();

      Geolocator.getPositionStream(locationSettings: locationSettings)
          .listen((Position? position) async {
        if (position != null) {
          await setDistanceFromPosition(position);
          await _startAudio();
        }
      });

      Timer.periodic(
        const Duration(seconds: 2),
        (_) async => await _getCameraRotation(),
      );
    });
  }

  Future<void> _startAudio() async {
    print("startMethod: _startAudio");
    try {
      await platform.invokeMethod('playAudio', [x, y, z]);
    } on PlatformException catch (e) {
      print(e);
    }
  }

  // Future<void> _stopAudio() async {
  //   print("startMethod: _stopAudio");
  //   try {
  //     await platform.invokeMethod('stopAudio');
  //   } on PlatformException catch (e) {
  //     print(e);
  //   }
  // }

  Future<void> _getCameraRotation() async {
    print("startMethod: _getCameraRotation");
    try {
      final rotation = await platform.invokeMethod('getCameraRotation');

      setState(() {
        yaw = rotation["yaw"] as double;
        pitch = rotation["pitch"] as double;
        roll = rotation["roll"] as double;
      });
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
            // ElevatedButton(
            //   child: const Text('playAudio'),
            //   onPressed: _startAudio,
            // ),
            // ElevatedButton(
            //   child: const Text('stopAudio'),
            //   onPressed: _stopAudio,
            // ),
            const SizedBox(height: 50),
            const Text("XYZ軸方向の距離"),
            Text('x: $x'),
            Text('y: $y'),
            Text('z: $z'),
            const SizedBox(height: 50),
            const Text("現在の位置情報"),
            Text('Latitude: $latitude'),
            Text('Longitude: $longitude'),
            const SizedBox(height: 50),
            const Text("回転情報"),
            Text('yaw: $yaw'),
            Text('pitch: $pitch'),
            Text('roll: $roll'),
          ],
        ),
      ),
    );
  }

  // 位置情報の許可を得る
  Future<void> checkPermission() async {
    LocationPermission permission;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        return Future.error('Location Not Available');
      }
    }
  }

  // 位置情報から対象オブジェクトへの距離を x, y で出力
  Future<void> setDistanceFromPosition(Position position) async {
    // 大濠公園入口
    double objectLatitude = 33.59012176;
    double objectLongitude = 130.37748086;

    setState(() {
      latitude = position.latitude;
      longitude = position.longitude;
    });

    double xDistanceInMeters = Geolocator.distanceBetween(
        latitude, longitude, objectLatitude, longitude); // x軸方向の距離を計算
    double yDistanceInMeters = Geolocator.distanceBetween(
        latitude, longitude, latitude, objectLongitude); // y軸方向の距離を計算

    setState(() {
      x = position.latitude < objectLatitude
          ? xDistanceInMeters
          : -xDistanceInMeters;
      y = position.longitude < objectLongitude
          ? yDistanceInMeters
          : -yDistanceInMeters;
    });
  }
}
