// Firebaseからデータを取得
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mach1_spatial_api/spot.dart';

import 'audio.dart';

class FirebaseService {
  static late Map<String, Audio> audioMap = {};

  static Future<void> setAudios() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('audios').get();

    // key: id, value: audio のmapに変換
    audioMap = {};
    for (dynamic doc in snapshot.docs) {
      Audio audio = Audio.fromJson(doc.data());
      audioMap[audio.id] = audio;
    }
  }

  static Future<List<Spot>> getSpots() async {
    final snapshot = await FirebaseFirestore.instance.collection('spots').get();
    return snapshot.docs
        .map(
          (doc) => Spot.fromJson(doc.data(), audioMap),
        )
        .toList();
  }
}
