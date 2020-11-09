import 'package:ek_asu_opb_mobile/src/odooClient.dart';
import 'package:ek_asu_opb_mobile/utils/config.dart' as config;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import "package:ek_asu_opb_mobile/controllers/controllers.dart" as controllers;
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;

final attemptCount = config.getItem('attemptCount') ?? 5;
final limitRecord = config.getItem('limitRecord') ?? 80;
final cbtRole = config.getItem('cbtRole') ?? 'cbt';
final ncopRole = config.getItem('ncopRole') ?? 'ncop';
final _storage = FlutterSecureStorage();
final List<String> _dict = ['railway', 'department', 'user'];

//загрузка справочников
//Возвращает List[
//  {'dictName': [1, countRecord]} //success
//  {'dictName': [-1, err.message]} //error
//]
Future<List<Map<String, dynamic>>> getDictionaries(
    {List<String> dicts, bool all: true, bool isLastUpdate: true}) async {
  List<Map<String, dynamic>> result = new List<Map<String, dynamic>>();
  dynamic data;
  List<dynamic> listDepIds;

  if (all)
    dicts = _dict;
  else if (dicts == null || dicts.length == 0) dicts = _dict;

  String userRoleTxt = await auth.getUserRoleTxt();

  controllers.Log.insert('=========================================');
  controllers.Log.insert("Get dictionaries ${dicts.join(', ')}");

  for (int i = 0; i < dicts.length; i++) {
    try {
      controllers.Log.insert(dicts[i]);
      dynamic lastUpdate = isLastUpdate ? await getLastUpdate(dicts[i]) : null;
      switch (dicts[i]) {
        case 'railway':
          List<dynamic> domain = new List<dynamic>();
          if (lastUpdate != null) domain.add(lastUpdate);
          data =
              await getDataWithAttemp('eco.ref.railway', 'search_read', null, {
            'domain': domain,
            'fields': ['id', 'name', 'short_name']
          });

          break;
        case 'department':
          List<dynamic> domain = new List<dynamic>();
          if (lastUpdate != null) domain.add(lastUpdate);
          data =
              await getDataWithAttemp('eco.department', 'search_read', null, {
            'domain': domain,
            'fields': ['id', 'name', 'short_name', 'rel_railway_id', 'active']
          });

          break;
        case 'user':
          List<dynamic> domain = new List<dynamic>();

          if (lastUpdate != null) domain.add(lastUpdate);
          listDepIds = await controllers.Department.selectIDs();
          if (listDepIds == null) continue;
          if (listDepIds.length > 0)
            if (userRoleTxt == ncopRole)
              domain.add(['department_id', 'in', listDepIds]);
          // domain.add(['department_id.role', 'in', ['cbt', 'ncop']]);
          /* domain.add([
            'f_user_role_txt',
            'in',
            [cbtRole, ncopRole]
          ]);*/
          domain.add([
            'user_role',
            'in',
            ['cbt', 'ncop']
          ]);
          data = await getDataWithAttemp('res.users', 'search_read', null, {
            'domain': domain,
            'fields': [
              'id',
              'login',
              'f_user_role_txt',
              'display_name',
              'department_id',
              'rel_railway_id',
              'email',
              'phone',
              'active',
              'function',
              'user_role'
            ]
          });

          break;
      } //switch
      if (data != null) {
        List<dynamic> dataList = data as List<dynamic>;
        for (int j = 0; j < dataList.length; j++) {
          switch (dicts[i]) {
            case 'railway':
              await controllers.Railway.insert(
                  dataList[j] as Map<String, dynamic>);
              break;
            case 'department':
              await controllers.Department.insert(
                  dataList[j] as Map<String, dynamic>);
              break;
            case 'user':
              await controllers.User.insert(
                  dataList[j] as Map<String, dynamic>);
              break;
          } //switch
        } //for j

        var recordCount = (data as List<dynamic>).length.toString();
        print('Recived $recordCount records');
        controllers.Log.insert('Recived $recordCount records');
        controllers.Log.insert("----------------------------------------");

        result.add({
          dicts[i]: [1, recordCount]
        });

        await setLastUpdate(dicts[i]);
      } //if (data!=null)
    } //try
    catch (e) {
      print(e);
      controllers.Log.insert('error: $e');
      result.add({
        dicts[i]: [-1, e.toString()]
      });
    }
  } //for i
  controllers.Log.insert('=========================================');
  return result;
}

Future<dynamic> getData(String model, String method, dynamic args,
    Map<String, dynamic> kwargs) async {
  return OdooProxy.odooClient.callKw(model, method, args, kwargs);
}

//получение данных с attemptCount попытками
Future<dynamic> getDataWithAttemp(String model, String method, dynamic args,
    Map<String, dynamic> kwargs) async {
  int curAttempt = 0;

  while (curAttempt++ < attemptCount) {
    print('Attempt ${curAttempt.toString()}..........');
    controllers.Log.insert('Attempt ${curAttempt.toString()}..........');
    var data = await getData(model, method, args, kwargs);
    if (data == null) continue;
    return data;
  }
  return null;
}

//получаем данные частями по limitRecord с attemptCount попытками
//todo дописать, если нужно
Future<dynamic> getDataChunk(String model, String method, dynamic args,
    Map<String, dynamic> kwargs) async {
  List<dynamic> result;
  var domain = [kwargs["domain"]] ?? [];
  var totalCount =
      await getDataWithAttemp('eco.ref.railway', 'search_count', domain, {});
  //int totalCount = await getCount(model, args, kwargs, lastData: lastData);
  // if (int.tryParse(totalCount) > 0) {

  // }

  return result;
}

Future<List<dynamic>> getLastUpdate(modelName) async {
  String sLastUpdate = await _storage.read(key: 'lastDateUpdate');
  if (sLastUpdate == null) return null;
  dynamic lastUpdate = json.decode(sLastUpdate);
  if (lastUpdate[modelName] != null)
    return ['write_date', '>', lastUpdate[modelName]];
  return null;
}

Future<void> setLastUpdate(modelName) async {
  String sLastUpdate = await _storage.read(key: 'lastDateUpdate');
  Map<String, dynamic> lastUpdate;
  if (sLastUpdate == null)
    lastUpdate = {modelName: DateTime.now().toString()};
  else {
    lastUpdate = json.decode(sLastUpdate);
    lastUpdate[modelName] = DateTime.now().toString();
  }

  await _storage.write(key: 'lastDateUpdate', value: json.encode(lastUpdate));
}
