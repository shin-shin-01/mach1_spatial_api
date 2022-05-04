import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

// ダウンロードする機能
class DownloadService {
  String fileName = "demo.wav";
  String url =
      "https://firebasestorage.googleapis.com/v0/b/onp-dev-4447a.appspot.com/o/tobari_city.wav?alt=media&token=2aa3186a-3fc0-49ba-8c9d-15fba11dd402";

  // ファイルをダウンロードする
  Future<String> downloadFile() async {
    Dio dio = Dio();

    var dir = await getApplicationDocumentsDirectory();
    final directoryPath = "${dir.path}/video/";
    final filePath = "$directoryPath$fileName";

    // ディレクトリを作成
    final directory = Directory(directoryPath);
    await directory.create(recursive: true);

    // ファイルが存在しない場合のみダウンロード
    bool alreadyExists = await File(filePath).exists();
    if (!alreadyExists) {
      await dio.download(url, filePath);
    }

    return filePath;
  }
}
