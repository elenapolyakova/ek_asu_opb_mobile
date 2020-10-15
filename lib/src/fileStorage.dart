import 'dart:io';
import 'dart:async';
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
