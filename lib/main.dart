// ignore_for_file: avoid_print

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import 'audio_service.dart';
import 'spot.dart';

// ========================
// main
// ========================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 向き指定
  // it is expected that the app will be used in Portrait mode held in hand and will assume 0 values for...
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await Firebase.initializeApp();
  runApp(const MyApp());
}

final scaffoldKey = GlobalKey<ScaffoldMessengerState>();

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey.shade800,
        ),
        scaffoldBackgroundColor: const Color(0xFFEFEFEF),
      ),
      scaffoldMessengerKey: scaffoldKey,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  static const platform = MethodChannel('audio');
  StreamSubscription? _getPositionSubscription;
  Timer? _getCurrentValueTimer;
  bool _isFinished = false;

  // 目的地
  String spotName = "";
  String audioName = "";

  // 目的地までの距離
  double distance = 0.0;
  double x = 0.0;
  double y = 0.0; // 縦方向
  double z = 0.0;

  // 回転角
  bool bUseHeadphoneOrientationData = false;
  double yaw = 0.0;
  double pitch = 0.0;
  double roll = 0.0;

  // 位置情報
  double latitude = 0.0;
  double longitude = 0.0;

  // 音量
  double leftVolume = 0.0;
  double rightVolume = 0.0;

  // ========================
  // 初期化
  // ========================
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
    _startJobs();
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        print("app in resumed");
        if (_isFinished) _startJobs();
        break;
      case AppLifecycleState.inactive:
        print("app in inactive");
        break;
      case AppLifecycleState.paused:
        print("app in paused");
        _finishJobs();
        break;
      case AppLifecycleState.detached:
        print("app in detached");
        _finishJobs();
        break;
    }
  }

  // ========================
  // ジョブを定期実行
  // ========================
  void _startJobs() async {
    _isFinished = false;

    // 位置情報の許可を得る
    await checkPermission();
    // AudioServiceを初期化
    final AudioService audioService = AudioService();
    await audioService.initialize(platform);

    // 位置情報を定期的に取得・反映
    _getPositionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position? position) async {
      if (position != null) {
        // 最も近い場所を選ぶ
        Spot spot = await audioService.setNearestSpot(position);

        setState(() {
          latitude = position.latitude;
          longitude = position.longitude;

          spotName = spot.name;
          audioName = spot.audio.name;
          distance = double.parse((spot.distance).toStringAsFixed(2));
          x = spot.xDistance;
          y = spot.yDistance;
        });

        // 音楽を再生
        await _startAudio();
      }
    });

    // 2秒ごとに現在の情報を取得（回転情報や音量情報）
    _getCurrentValueTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) async => await _getCurrentValue(),
    );
  }

  // ========================
  // 定期実行してた処理たちを止める
  // ========================
  void _finishJobs() {
    // 音声を停止
    _stopAudio();
    // 位置情報の更新を停止
    _getPositionSubscription?.cancel();
    // 情報取得の停止
    _getCurrentValueTimer?.cancel();

    _isFinished = true;
  }

  // ========================
  // 音声を再生・停止
  // ========================
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
      await platform.invokeMethod('stopAudio', [x, y, z]);
    } on PlatformException catch (e) {
      print(e);
    }
  }

  // ========================
  // 音量や回転情報を取得
  // ========================
  Future<void> _getCurrentValue() async {
    print("startMethod: _getCurrentValue");
    try {
      final value = await platform.invokeMethod('getCurrentValue');

      setState(() {
        yaw = value["yaw"] as double;
        pitch = value["pitch"] as double;
        roll = value["roll"] as double;
        leftVolume = value["leftVolume"] as double;
        rightVolume = value["rightVolume"] as double;
      });
    } on PlatformException catch (e) {
      print(e);
    }
  }

  // ========================
  // UI
  // ========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mach1 Test App"),
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // 左の音量をグラフ化
            volBarGraph("L", leftVolume),
            // 統計情報を掲載
            informationWidget(),
            // 右の音量をグラフ化
            volBarGraph("R", rightVolume),
          ],
        ),
      ),
    );
  }

  /// 音量を示す棒グラフ
  Widget volBarGraph(String lr, double volume) {
    Size size = MediaQuery.of(context).size;
    double volumeFixed = double.parse((volume).toStringAsFixed(2));

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(lr),
        const SizedBox(height: 10),
        Container(
          color: Colors.white,
          width: 30,
          height: size.height * 0.6 * (1 - volume),
        ),
        Container(
          color: Colors.blue,
          width: 30,
          height: size.height * 0.6 * volume,
        ),
        const SizedBox(height: 10),
        Text("$volumeFixed", style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 20),
      ],
    );
  }

  /// 統計情報を掲載
  Widget informationWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(spotName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(audioName),
        const SizedBox(height: 30),
        const Text("目的地までの距離"),
        Text('$distanceメートル'),
        const SizedBox(height: 20),
        const Text("XYZ軸方向の距離"),
        Text('x: $x'),
        Text('y: $y'),
        Text('z: $z'),
        const SizedBox(height: 30),
        const Text("現在の位置情報"),
        Text('Latitude: $latitude'),
        Text('Longitude: $longitude'),
        const SizedBox(height: 30),
        const Text("回転情報"),
        Text('Yaw: $yaw'),
        Text('Pitch: $pitch'),
        Text('Roll: $roll'),
      ],
    );
  }
}

// ========================
// Geolocator
// ========================
// 位置情報の設定
const LocationSettings locationSettings =
    LocationSettings(accuracy: LocationAccuracy.best);

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
