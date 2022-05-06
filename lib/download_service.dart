import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import 'snackbar_service.dart';

// ダウンロードする機能
class DownloadService {
  // ファイルをダウンロードする
  static Future<String> downloadFile(String fileName, String url) async {
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
      SnackbarService.showShackBar("$fileNameをダウンロードします");
      await dio.download(url, filePath);
    }

    return filePath;
  }
}
