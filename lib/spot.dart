import 'package:geolocator/geolocator.dart';
import 'audio.dart';

class Spot {
  String name;
  double latitude;
  double longitude;
  Audio audio;

  late double distance;
  late double xDistance;
  late double yDistance;

  Spot(this.name, this.latitude, this.longitude, this.audio);

  static Spot fromJson(dynamic json, Map<String, Audio> audioMap) {
    final name = json["name"] as String;
    final latitude = json["latitude"] as double;
    final longitude = json["longitude"] as double;
    final audio = audioMap[json["audioId"] as String]!;
    return Spot(name, latitude, longitude, audio);
  }

  // 直線距離を計算
  void setDistance(Position position) {
    double currentLatitude = position.latitude;
    double currentLongitude = position.longitude;

    distance = Geolocator.distanceBetween(
        currentLatitude, currentLongitude, latitude, longitude);
  }

  // X方向・Y方向の距離を計算
  void setDistance2(Position position) {
    double currentLatitude = position.latitude;
    double currentLongitude = position.longitude;

    xDistance = Geolocator.distanceBetween(
      currentLatitude,
      currentLongitude,
      latitude,
      currentLongitude,
    ); // x軸方向の距離を計算;

    yDistance = Geolocator.distanceBetween(
      currentLatitude,
      currentLongitude,
      currentLatitude,
      longitude,
    ); // y軸方向の距離を計算;

    // 正負
    xDistance = currentLatitude < latitude ? xDistance : -xDistance;
    yDistance = currentLongitude < longitude ? yDistance : -yDistance;
  }
}
