import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';

// ダウンロードする機能
class DownloadService {
  static final ReceivePort _port = ReceivePort();
  String localDirectoryPath = "";
  String fileName = "demo.wav";
  String url =
      "https://firebasestorage.googleapis.com/v0/b/onp-dev-4447a.appspot.com/o/tobari_city.wav?alt=media&token=2aa3186a-3fc0-49ba-8c9d-15fba11dd402";

  static initialize() async {
    IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    await FlutterDownloader.initialize(debug: true);
    FlutterDownloader.registerCallback(downloadCallback);
  }

  // TODO: ここで正しく終了させる必要あるかも
  static void downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    final SendPort send =
        IsolateNameServer.lookupPortByName('downloader_send_port')!;
    send.send([id, status, progress]);
  }

  // ダウンロードしたローカルファイルへのパスを取得
  String getLocalFilePath() {
    return "$localDirectoryPath/$fileName";
  }

  // ダウンロード先のディレクトリを用意する
  Future<void> prepareSaveDir() async {
    // Platform.isIOS
    localDirectoryPath =
        (await getApplicationDocumentsDirectory()).absolute.path;
    final savedDir = Directory(localDirectoryPath);
    bool hasExisted = await savedDir.exists();
    if (!hasExisted) {
      savedDir.create();
    }
  }

  // ファイルをダウンロードする
  Future<void> downloadFile() async {
    await FlutterDownloader.enqueue(
      fileName: fileName,
      url: url,
      // headers: {"auth": "test_for_sql_encoding"},
      savedDir: localDirectoryPath,
      saveInPublicStorage: true,
    );
  }
}
