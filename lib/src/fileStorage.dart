import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class FileStorage {
  String _fileName;
  FileStorage(String fileName) {
    _fileName = fileName;
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$_fileName');
  }

  Future<File> writeData(String data) async {
    final file = await _localFile;
    return file.writeAsString('$data');
  }

  Future<File> appendData(String data) async {
    final file = await _localFile;
    return file.writeAsString('$data', mode: FileMode.append);
  }

  Future<String> readData() async {
    try {
      final file = await _localFile;
      String data = await file.readAsString();

      return data;
    } catch (e) {
      // If encountering an error, return 0.
      return 'empty';
    }
  }
}

Future<File> loadFileFromAssets(String key, String path) async {
  var bytes = await rootBundle.load(key);
  return loadFileFromBytes(bytes, path);
}

Future<File> loadFileFromBytes(ByteData bytes, String path) async {
  // String tempPath = (await getApplicationDocumentsDirectory()).path;
  File file = File(path);
  await file.writeAsBytes(
      bytes.buffer.asInt8List(bytes.offsetInBytes, bytes.lengthInBytes));
  return file;
}

Future<String> getPath() async {
  String appPath = (await getApplicationDocumentsDirectory()).path;
  return '$appPath/file_${DateTime.now().millisecondsSinceEpoch}';
}

String fileToBase64(String path) {
  File file = File(path);
  final bytes = file.readAsBytesSync().toList();
  return base64.encode(bytes);
}

Future<File> base64ToFile(String img64, {String path}) async {
  String _path = path ?? (await getPath());
  final decodedBytes = base64.decode(img64);
  File file = File(path);
  file.writeAsBytesSync(decodedBytes);
  return file;
}
