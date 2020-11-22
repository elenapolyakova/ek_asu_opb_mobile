import 'dart:async';
import 'dart:io';
import 'package:connectivity/connectivity.dart';
import 'config.dart' as config;
import 'package:ek_asu_opb_mobile/src/db.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';

Future<bool> checkExist() async {
  var conectivityResult = await Connectivity().checkConnectivity();
  if (conectivityResult == ConnectivityResult.mobile ||
      conectivityResult == ConnectivityResult.wifi) {
    return true;
  }
  return false;
}

Future<bool> ping() async {
  try {
    String address = config.getItem('addressForPing');
    final result = await InternetAddress.lookup(address);
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } on SocketException catch (_) {
    return false;
  }
}

Future<bool> checkConnection() async {
  DBProvider.db
      .insert('log', {'date': nowStr(), 'message': 'checking Connection'});

  try {
    var result = await checkExist() && await ping();

    DBProvider.db.insert(
        'log', {'date': nowStr(), 'message': "${result ? 'sucess' : 'error'}"});
    DBProvider.db.insert('log', {
      'date': nowStr(),
      'message': '----------------------------------------'
    });
    return result;
  } catch (ex) {
    DBProvider.db.insert('log', {'date': nowStr(), 'message': 'error'});
    DBProvider.db.insert('log', {
      'date': nowStr(),
      'message': '----------------------------------------'
    });
    return false;
  }
}
