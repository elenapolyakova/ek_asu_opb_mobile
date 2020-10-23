import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/models/userInfo.dart';
import 'package:ek_asu_opb_mobile/utils/proxyOdoo.dart' as proxyOdoo;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:convert/convert.dart';

final _storage = FlutterSecureStorage();

void LogOut(BuildContext context) async {
  await _storage.delete(key: 'userInfo');
  await _storage.delete(key: 'uid');
  await _storage.delete(key: 'pin');
  await _storage.delete(key: 'lastDateUpdate');

  Navigator.pushNamedAndRemoveUntil(
      context, '/login', (Route<dynamic> route) => false);
}

Future<bool> checkLoginStatus(BuildContext context) async {
  String value = await _storage.read(key: 'uid');
  if (value == null) {
    LogOut(context);
    return false;
  } 
  return true;
}

Future<bool> setUserData(String login, String password) async {
  var uid = await _storage.read(key: "uid");
  if (uid == null) return false;

  UserInfo userInfo = await proxyOdoo.getUserData(int.tryParse(uid.toString()));
  userInfo.password = password;
  await _storage.write(key: "userInfo", value: userInfoToJson(userInfo));
  return true;
}

Future<UserInfo> getUserInfo() async {
  UserInfo userInfo;
  String userInfoJson = await _storage.read(key: "userInfo");
  if (userInfoJson != null) userInfo = userInfoFromJson(userInfoJson);
  return userInfo;
}

Future<bool> authorize(String login, String password) async {
  int uid = await proxyOdoo.authorize(login, password);
  if (uid != null) await _storage.write(key: "uid", value: uid.toString());
  return uid != null;
}

Future<int> getAdminUid() async {
  var adminUid = await _storage.read(key: "adminUid");
  if (adminUid == null) adminUid = await proxyOdoo.getAdminUID();

  if (adminUid != null) {
    await _storage.write(key: "adminUid", value: adminUid.toString());
  }

  return int.tryParse(adminUid.toString());
}

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
