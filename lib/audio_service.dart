import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import 'audio.dart';
import 'download_service.dart';
import 'firebase_service.dart';
import 'snackbar_service.dart';
import 'spot.dart';

class AudioService {
  late Spot currentSpot;
  late List<Spot> spotList;
  late MethodChannel platform;

  // ========================
  // firebase から音源を設定
  // ========================
  Future<void> initialize(MethodChannel platform) async {
    // 音源を全て取得
    await FirebaseService.setAudios();
    // 場所を全て設定
    spotList = await FirebaseService.getSpots();
    // MethodChannelを設定
    this.platform = platform;

    // 初期目的地を設定
    currentSpot = spotList[0];
    await _initializeAudioPlayers();
    await _initializeM1obj();
  }

  // ========================
  // 最も近い場所を選ぶ
  // ========================
  Future<Spot> setNearestSpot(Position position) async {
    Spot oldSpot = currentSpot;

    for (Spot spot in spotList) {
      // 直線上の距離を計算
      spot.setDistance(position);
      if (spot.id == currentSpot.id) {
        continue;
      }

      // より近い場所を設定
      if (currentSpot.distance > spot.distance) {
        currentSpot = spot;
      }
    }

    if (oldSpot.id != currentSpot.id) {
      SnackbarService.showShackBar("${currentSpot.name}を目的地に変更します");
    }

    if (oldSpot.audio.id != currentSpot.audio.id) {
      // 音源が変更した場合に, Swift側で再設定
      await _initializeAudioPlayers();
    }

    // 決定したSpotとの距離を取得
    currentSpot.setDistance2(position);

    return currentSpot;
  }

  // 音声ファイルを用いてAudioを初期化
  Future<void> _initializeAudioPlayers() async {
    print("startMethod: _initializeAudioPlayers");
    final String audioFilePath = await DownloadService.downloadFile(
      currentSpot.audio.name,
      currentSpot.audio.url,
    );
    try {
      await platform.invokeMethod('initializeAudioPlayers', audioFilePath);
    } on PlatformException catch (e) {
      print(e);
    }
  }

  // M1objを初期化
  Future<void> _initializeM1obj() async {
    print("startMethod: _initializeM1obj");
    try {
      await platform.invokeMethod('initializeM1obj');
    } on PlatformException catch (e) {
      print(e);
    }
  }
}
