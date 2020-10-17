import 'dart:async';
import 'dart:io';
import 'package:connectivity/connectivity.dart';

Future<bool> checkConnection() async {
  var conectivityResult = await Connectivity().checkConnectivity();
  if (conectivityResult == ConnectivityResult.mobile ||
      conectivityResult == ConnectivityResult.wifi) {
    return true;
  }
  return false;
}

Future<bool> checkConnection2() async {
  try {
    final result = await InternetAddress.lookup('google.com');
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) 
    return true;
  } on SocketException catch (_) {
    return false;
  }
}
