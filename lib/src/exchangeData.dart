import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/src/odooClient.dart';
import 'package:ek_asu_opb_mobile/utils/config.dart' as config;
import 'package:ek_asu_opb_mobile/src/db.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

final attemptCount = config.getItem('attemptCount') ?? 5;
final limitRecord = config.getItem('limitRecord') ?? 80;
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

  DBProvider.db.insert('log', {
    'date': nowStr(),
    'message': '========================================='
  });
  DBProvider.db.insert('log',
      {'date': nowStr(), 'message': "Get dictionaries ${dicts.join(', ')}"});

  for (int i = 0; i < dicts.length; i++) {
    try {
      DBProvider.db.insert('log', {'date': nowStr(), 'message': dicts[i]});
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
          listDepIds = await DBProvider.db.selectIDs('department');
          if (listDepIds.length > 0)
            domain.add(['department_id', 'in', listDepIds]);
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
              'active'
            ]
          });

          break;
      } //switch
      if (data != null) {
        List<dynamic> dataList = data as List<dynamic>;
        for (int j = 0; j < dataList.length; j++) {
          switch (dicts[i]) {
            case 'railway':
              Railway railway =
                  Railway.fromJson(dataList[j] as Map<String, dynamic>);
              await DBProvider.db.insert(dicts[i], railway.toJson());
              break;
            case 'department':
              Department dep =
                  Department.fromJson(dataList[j] as Map<String, dynamic>);
              await DBProvider.db.insert(dicts[i], dep.toJson());
              break;
            case 'user':
              UserInfo user =
                  UserInfo.fromJson(dataList[j] as Map<String, dynamic>);
              await DBProvider.db.insert(dicts[i], user.toJson());
              break;
          } //switch
        } //for j

        var recordCount = (data as List<dynamic>).length.toString();
        print('Recived $recordCount records');
        DBProvider.db.insert('log',
            {'date': nowStr(), 'message': 'Recived $recordCount records'});
        DBProvider.db.insert('log', {
          'date': nowStr(),
          'message': "----------------------------------------"
        });

        result.add({
          dicts[i]: [1, recordCount]
        });

        await setLastUpdate(dicts[i]);
      } //if (data!=null)
    } //try
    catch (e) {
      print(e);
      DBProvider.db.insert('log', {'date': nowStr(), 'message': 'error: $e'});
      result.add({
        dicts[i]: [-1, e.toString()]
      });
    }
  } //for i
  DBProvider.db.insert('log', {
    'date': nowStr(),
    'message': '========================================='
  });
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
    DBProvider.db.insert('log', {
      'date': nowStr(),
      'message': 'Attempt ${curAttempt.toString()}..........'
    });
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
