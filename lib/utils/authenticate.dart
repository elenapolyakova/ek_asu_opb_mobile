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
import 'package:ek_asu_opb_mobile/utils/config.dart' as config;
import 'package:ek_asu_opb_mobile/main.dart';

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
  await _storage.delete(key: 'isHomePinDialogShow');
  await _storage.delete(key: 'railwayId');
  await _storage.delete(key: 'year');
  await _storage.delete(key: 'checkPlanId');

  // удалим при повторной авторизации, если вошел новый пользователь
  // await _storage.delete(key: 'pin');
  // await _storage.delete(key: 'lastDateUpdate');
  String sessionString = await _storage.read(key: 'session');
  if (sessionString != null) _storage.write(key: "session", value: null);
  context = context ?? MyApp.navKey.currentState.overlay.context;
  // print(sessionString);

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
    String sessionString = await _storage.read(key: 'session');
    if (sessionString != null) _storage.write(key: "session", value: null);

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
        await _storage.delete(key: 'session');
        String sessionString = await _storage.read(key: 'session');
        if (sessionString != null) _storage.write(key: "session", value: null);
        // await DBProvider.db.deleteAll('userInfo');
        await DBProvider.db.reCreateDictionary();
        //await DBProvider.db.reCreateTable();

        //todo так же удалять все данные из локально БД/пересоздавать таблицы
      }
    }
    await _storage.write(key: "session", value: sessionString);
  } else {
    await _storage.delete(key: 'session');
    String sessionString = await _storage.read(key: 'session');
    if (sessionString != null) _storage.write(key: "session", value: null);
  }

  return uid != null;
}

Future<bool> resetAllStorageData() async {
  try {
    await _storage.delete(key: 'pin');
    await _storage.delete(key: 'lastDateUpdate');
    await _storage.delete(key: 'railwayId');
    await _storage.delete(key: 'year');
    await _storage.delete(key: 'checkPlanId');
    await _storage.delete(key: 'session');
    String sessionString = await _storage.read(key: 'session');
    if (sessionString != null) _storage.write(key: "session", value: null);
  } catch (e) {
    return false;
  }
  return true;
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

Future<bool> setBaseUrl(String baseUrl) async {
  try {
    String addressForPing = baseUrl
        .replaceAll(
            new RegExp('https?://', multiLine: false, caseSensitive: false), '')
        .replaceAll(
            new RegExp(':[0-9]+', multiLine: false, caseSensitive: false), '');
    await _storage.write(key: 'ServiceRootUrl', value: baseUrl);
    await _storage.write(key: 'addressForPing', value: addressForPing);

    config.setItem("ServiceRootUrl", baseUrl);
    config.setItem("addressForPing", addressForPing);

    OdooProxy.odooClient.baseURL = baseUrl;
  } catch (e) {
    return false;
  }
  return true;
}

Future<String> getBaseUrl() async {
  String baseUrl = await _storage.read(key: "ServiceRootUrl");
  if ([null, ''].contains(baseUrl)) baseUrl = config.getItem('ServiceRootUrl');
  if ([null, ''].contains(baseUrl)) baseUrl = "http://msk3tis2.vniizht.lan";
  return baseUrl;
}

Future<String> getDB() async {
  String db = await _storage.read(key: "db");
  if ([null, ''].contains(db)) db = config.getItem('db');
  if ([null, ''].contains(db)) db = "ecodb_2020-07-01";
  return db;
}

Future<bool> setDB(String db) async {
  try {
    await _storage.write(key: 'db', value: db);
    config.setItem("db", db);

    OdooProxy.odooClient.db = db;
  } catch (e) {
    return false;
  }
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

Future<bool> setRailway(int railwayId) async {
  if (railwayId != null)
    try {
      await _storage.write(key: 'railwayId', value: railwayId.toString());
    } catch (e) {
      return false;
    }
  return true;
}

Future<int> getRailway() async {
  String railwayId = await _storage.read(key: "railwayId");
  if ([null, ''].contains(railwayId)) {
    UserInfo userinfo = await getUserInfo();
    await setRailway(userinfo.railway_id);
    return userinfo.railway_id;
  } else
    return railwayId != null ? int.parse(railwayId) : null;
}

Future<bool> setYear(int year) async {
  if (year != null)
    try {
      await _storage.write(key: 'year', value: year.toString());
    } catch (e) {
      return false;
    }
  return true;
}

Future<int> getYear() async {
  String year = await _storage.read(key: "year");
  if ([null, ''].contains(year)) {
    await setYear(DateTime.now().year);
    return DateTime.now().year;
  } else
    return year != null ? int.parse(year) : null;
}

Future<bool> setCheckPlanId(int checkPlanId) async {
  if (checkPlanId != null)
    try {
      await _storage.write(key: 'checkPlanId', value: checkPlanId.toString());
    } catch (e) {
      return false;
    }
  return true;
}

Future<int> getCheckPlanId() async {
  String checkPlanId = await _storage.read(key: "checkPlanId");
  if ([null, ''].contains(checkPlanId)) return null;
  return int.parse(checkPlanId);
}
