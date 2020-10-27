import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/models/userInfo.dart';
import 'package:ek_asu_opb_mobile/src/odooClient.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import 'package:ek_asu_opb_mobile/src/db.dart';

final _storage = FlutterSecureStorage();
UserInfo _currentUser;

void LogOut(BuildContext context) async {
  OdooSession session = await getSession();
  try {
    if (session != null) {
      DBProvider.db.insert('log',
          {'date': nowStr(), 'message': 'User ${session.userLogin} logout'});
      // если нет сети - не завершим сессию для Odoo
      DBProvider.db.insert(
          'log', {'date': nowStr(), 'message': 'destroy session for odoo'});
      await OdooProxy.odooClient.destroySession();
      OdooProxy.odooClient.close();
      DBProvider.db.insert('log', {'date': nowStr(), 'message': 'success'});
      await DBProvider.db.deleteAll('userInfo');
    }
  } on OdooException catch (e) {
    DBProvider.db.insert('log', {'date': nowStr(), 'message': 'error'});
    print(e);
  }

  //await _storage.delete(key: 'userInfo');

  await _storage.delete(key: 'session');
  await _storage.delete(key: 'pin');
  await _storage.delete(key: 'lastDateUpdate');

  Navigator.pushNamedAndRemoveUntil(
      context, '/login', (Route<dynamic> route) => false);
}

Future<bool> checkLoginStatus(BuildContext context) async {
  // String uid = await _storage.read(key: 'uid');
  String session = await _storage.read(key: 'session');
  String pin = await _storage.read(key: "pin");

  if (_currentUser == null) _currentUser = await getUserInfo();

  if (session == null || pin == null || _currentUser == null) {
    LogOut(context);
    return false;
  }

  return true;
}

//Проверять только если есть сеть
Future<bool> checkSession() async {
  String session = await _storage.read(key: 'session');
  try {
    if (session != null) {
      DBProvider.db
          .insert('log', {'date': nowStr(), 'message': 'checking Session'});
      OdooProxy.odooClient.checkSession();
      DBProvider.db.insert('log', {'date': nowStr(), 'message': 'success'});
      DBProvider.db.insert('log', {
        'date': nowStr(),
        'message': '----------------------------------------'
      });
      return true;
    }
  } on OdooSessionExpiredException catch (e) {
    await _storage.delete(key: 'session');

    DBProvider.db
        .insert('log', {'date': nowStr(), 'message': 'Session expired'});
    DBProvider.db.insert('log', {
      'date': nowStr(),
      'message': '----------------------------------------'
    });
    print(e);
    return false;
  } catch (e) {
    print(e);
    return false;
  }
}

Future<bool> setUserData() async {
  OdooSession session = await getSession();
  if (session == null) return false;

  try {
    //UserInfo userInfo =  await proxyOdoo.getUserData(int.tryParse(uid.toString()), password);

    _currentUser = await OdooProxy.odooClient.getUserData(session.userId);
    if (_currentUser == null) return false;
    DBProvider.db.insert('userInfo', _currentUser.toJson());

    // userInfo.password = password;
    //await _storage.write(key: "userInfo", value: userInfoToJson(_currentUser));
    return true;
  } catch (e) {
    print(e);
    return false;
  }
}

Future<UserInfo> getUserInfo() async {
  OdooSession session = await getSession();
  if (session == null) return null;
  return UserInfo.fromJson(
      await DBProvider.db.select('userInfo', session.userId));
}

Future<bool> authorize(String login, String password) async {
  // int uid = await proxyOdoo.authorize(login, password);
  OdooSession session = await OdooProxy.odooClient.authorize(login, password);
  int uid;
  if (session != null) {
    String sessionString = json.encode(session.toJson());
    await _storage.write(key: "session", value: sessionString);
    uid = session.userId;
  } else
    await _storage.delete(key: 'session');

  return uid != null;
}

Future<OdooSession> getSession() async {
  var sessionString = await _storage.read(key: "session");
  OdooSession session;
  if (sessionString != null)
    session = OdooSession.fromJson(json.decode(sessionString));
  return session;
}

/*Future<int> getAdminUid() async {
  var adminUid = await _storage.read(key: "adminUid");
  // if (adminUid == null) adminUid = await proxyOdoo.getAdminUID();

  if (adminUid != null) {
    await _storage.write(key: "adminUid", value: adminUid.toString());
  }

  return int.tryParse(adminUid.toString());
}*/

Future<bool> setPinCode(String pin) async {
  var bytes = utf8.encode(pin);
  var hashPin = md5.convert(bytes);
  await _storage.write(key: "pin", value: hashPin.toString());

  return true;
}

Future<bool> isPinValid(String pin) async {
  var bytes = utf8.encode(pin);
  var hashPin = md5.convert(bytes);

  var _pin = await _storage.read(key: "pin");
  var _hashPin = Digest(hex.decode(_pin));

  return hashPin == _hashPin;
}
