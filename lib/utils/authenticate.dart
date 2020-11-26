import 'package:ek_asu_opb_mobile/controllers/controllers.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/models/userInfo.dart';
import 'package:ek_asu_opb_mobile/src/odooClient.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:ek_asu_opb_mobile/src/db.dart';

final _storage = FlutterSecureStorage();
UserInfo _currentUser;
bool _isSameUser = false;

void LogOut(BuildContext context) async {
  OdooSession session = await getSession();
  try {
    if (session != null) {
      LogController.insert('User ${session.userLogin} logout');
      // если нет сети - не завершим сессию для Odoo
      LogController.insert('destroy session for odoo');
      await OdooProxy.odooClient.destroySession();
      OdooProxy.odooClient.close();
      LogController.insert('success');
    }
  } on OdooException catch (e) {
    LogController.insert('error');
    print(e);
  }

  await _storage.delete(key: 'session');
  // удалим при повторной авторизации, если вошел новый пользователь
  // await _storage.delete(key: 'pin');
  // await _storage.delete(key: 'lastDateUpdate');

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
   OdooProxy.odooClient.sessionListen(sessionChanged);
  return true;
}

//Проверять только если есть сеть
Future<bool> checkSession(BuildContext context) async {
  String session = await _storage.read(key: 'session');
  try {
    if (session != null) {
      LogController.insert('checking Session');
      OdooProxy.odooClient.checkSession();
      LogController.insert('success');
      LogController.insert('----------------------------------------');
      return true;
    }
  } on OdooSessionExpiredException catch (e) {
    await _storage.delete(key: 'session');

    Navigator.pushNamed(context, '/login');

    LogController.insert('Session expired');
    LogController.insert('----------------------------------------');
    print(e);
    return false;
  } catch (e) {
    print(e);
    return false;
  }
}

bool isSameUser() {
  return _isSameUser;
}

Future<bool> setUserData() async {
  OdooSession session = await getSession();
  if (session == null) return false;
  UserInfo oldUserInfo = await getUserInfo();

  try {
    _currentUser = await OdooProxy.odooClient.getUserData(session.userId);
    if (_currentUser == null) return false;
    //todo сравнивать, если изменилось предприятие у пользователя, то загружать новые данные? а если они еще не все ушли в одоо?
    if (oldUserInfo != null) {
      if (oldUserInfo.department_id != _currentUser.department_id) {
        await DBProvider.db.reCreateDictionary();
        //  await DBProvider.db.reCreateTable();
        await _storage.delete(key: 'lastDateUpdate');
        await _storage.delete(key: 'messengerDates');
        
      } else
        _isSameUser = true;
    }

    await UserInfoController.deleteAll();
    await UserInfoController.insert(_currentUser.toJson());

    return true;
  } catch (e) {
    print(e);
    return false;
  }
}

Future<UserInfo> getUserInfo() async {
  OdooSession session = await getSession();
  if (session == null) return null;

  return await UserInfoController.selectUserInfo();
}

Future<String> getUserRoleTxt() async {
  UserInfo userInfo = await getUserInfo();
  if (userInfo != null) return userInfo.f_user_role_txt;
  return '';
}

sessionChanged(OdooSession session) async {
  if (session != null) {
    String sessionString = json.encode(session.toJson());
    await _storage.write(key: "session", value: sessionString);
  }
}

Future<bool> authorize(String login, String password) async {
  UserInfo oldUserInfo = await getUserInfo();
  _isSameUser = false;

  OdooProxy.odooClient.sessionListen(sessionChanged);
  OdooSession session = await OdooProxy.odooClient.authorize(login, password);
  int uid;
  if (session != null) {
    String sessionString = json.encode(session.toJson());
    uid = session.userId;

    if (oldUserInfo != null) {
      if (oldUserInfo.id != uid) {
        await _storage.delete(key: 'pin');
        await _storage.delete(key: 'lastDateUpdate');
        await _storage.delete(key: 'messengerDates');
        await _storage.delete(key: 'session');
        // await DBProvider.db.deleteAll('userInfo');
        await DBProvider.db.reCreateDictionary();
        //await DBProvider.db.reCreateTable();

        //todo так же удалять все данные из локально БД/пересоздавать таблицы
      }
    }
    await _storage.write(key: "session", value: sessionString);
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

Future<String> getPin() async {
  return await _storage.read(key: "pin");
}

Future<bool> isPinValid(String pin) async {
  var bytes = utf8.encode(pin);
  var hashPin = md5.convert(bytes);

  var _pin = await _storage.read(key: "pin");
  var _hashPin = Digest(hex.decode(_pin));

  return hashPin == _hashPin;
}
