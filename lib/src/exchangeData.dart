import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/src/odooClient.dart';
import 'package:ek_asu_opb_mobile/utils/config.dart' as config;
import 'package:ek_asu_opb_mobile/src/db.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final attemptCount = config.getItem('attemptCount') ?? 5;
final limitRecord = config.getItem('limitRecord') ?? 80;
final _storage = FlutterSecureStorage();
final List<String> _dict = ['railway', 'department'];

//загрузка справочников
//Возвращает List[
//  {'dictName': [1, countRecord]} //success
//  {'dictName': [-1]} //error
//]
Future<List<Map<String, dynamic>>> getDictionaries(
    {List<String> dicts, bool all: true}) async {
  List<Map<String, dynamic>> result = new List<Map<String, dynamic>>();
  dynamic data;
  //bool isLastData = false;
  dynamic lastUpdate = await getLastUpdate();
  if (all)
    dicts = _dict;
  else if (dicts == null || dicts.length == 0) dicts = _dict;

  DBProvider.db.insert('log', {
    'date': nowStr(),
    'message': '========================================='
  });
  DBProvider.db.insert('log',
      {'date': nowStr(), 'message': "Get dictionaries ${dicts.join(', ')}"});

  await DBProvider.db
      .reCreateDictionary(); //todo delete when lastUpdate is working

  for (int i = 0; i < dicts.length; i++) {
    try {
      DBProvider.db.insert('log', {'date': nowStr(), 'message': dicts[i]});
      switch (dicts[i]) {
        case 'railway':
          List<dynamic> domain = new List<dynamic>();
          //todo не работает условие, __last_update > datetime ???
          if (lastUpdate != null) domain.add(lastUpdate);
          data =
              await getDataWithAttemp('eco.ref.railway', 'search_read', null, {
            'domain': domain,
            'fields': ['id', 'name', 'short_name']
          });
          if (data != null) {
            (data as List<dynamic>).forEach((dataItem) {
              DBProvider.db.insert(dicts[i], dataItem as Map<String, dynamic>);
            });
          }

          break;
        case 'department':
          List<dynamic> domain = new List<dynamic>();
          //todo не работает условие, __last_update > datetime ???
          if (lastUpdate != null) domain.add(lastUpdate);
          data =
              await getDataWithAttemp('eco.department', 'search_read', null, {
            'domain': domain,
            'fields': ['id', 'name', 'short_name', 'rel_railway_id']
          });
          if (data != null) {
            //List<dynamic> listOfData = data as List<dynamic>;
           // for ()
            (data as List<dynamic>).forEach((dataItem) async{
              Department dep =
                  Department.fromJson(dataItem as Map<String, dynamic>);
              await DBProvider.db.insert(dicts[i], dep.toJson());
            });
          }
          break;
      }
      if (data != null) {
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
      }
    } catch (e) {
      print(e);
      DBProvider.db.insert('log', {'date': nowStr(), 'message': 'error: $e'});
      result.add({
        dicts[i]: [-1, e.toString()]
      });
    }
  }
  DBProvider.db.insert('log', {
    'date': nowStr(),
    'message': '========================================='
  });
  return result;
}

//возвращает данные по строго по параметрам
Future<dynamic> getData(String model, String method, dynamic args,
    Map<String, dynamic> kwargs) async {
  // bool checkSession = await auth.checkSession();
  // if (checkSession) return null;

  final client = await OdooProxy.odooClient;
  return client.callKw(model, method, args, kwargs);
}

//получение данных с attemptCount попытками (bool lastData - новые данные, по умолчанию да)
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
Future<dynamic> getDataChunk(String model, String method, dynamic args,
    Map<String, dynamic> kwargs) async {
  List<dynamic> result;
  var domain = [kwargs["domain"]] ?? [];
  var totalCount =
      await getDataWithAttemp('eco.ref.railway', 'search_count', domain, {});
  //int totalCount = await getCount(model, args, kwargs, lastData: lastData);
  // if (int.tryParse(totalCount) > 0) {

  // }

  //  limitRecord
  return result;
}

Future<List<dynamic>> getLastUpdate() async {
  String sLastUpdate =
      DateTime.now().toString(); //await _storage.read(key: 'lastDateUpdate');
  if (sLastUpdate == null) return null;
  //return DateTime.tryParse(sLastUpdate);
  return ['__last_update', '>', sLastUpdate];
}
