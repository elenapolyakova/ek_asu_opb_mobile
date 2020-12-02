import 'package:ek_asu_opb_mobile/controllers/checkList.dart';
import 'package:ek_asu_opb_mobile/controllers/checkListItem.dart';
import 'package:ek_asu_opb_mobile/controllers/controllers.dart';
import 'package:ek_asu_opb_mobile/controllers/ispDocument.dart';
import 'package:ek_asu_opb_mobile/controllers/isp.dart';
import 'package:ek_asu_opb_mobile/src/odooClient.dart';
import 'package:ek_asu_opb_mobile/utils/config.dart' as config;
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;

final attemptCount = config.getItem('attemptCount') ?? 5;
final limitRecord = config.getItem('limitRecord') ?? 80;
final cbtRole = config.getItem('cbtRole') ?? 'cbt';
final ncopRole = config.getItem('ncopRole') ?? 'ncop';
final _storage = FlutterSecureStorage();
final List<String> _dict = [
  'railway',
  'department',
  'user',
  'check_list',
  'koap',
  'isp'
];

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

  LogController.insert('=========================================');
  LogController.insert("Get dictionaries ${dicts.join(', ')}");

  for (int i = 0; i < dicts.length; i++) {
    try {
      LogController.insert(dicts[i]);
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
        case 'koap':
          List<dynamic> domain = new List<dynamic>();
          if (lastUpdate != null) domain.add(lastUpdate);
          data = await getDataWithAttemp('mob.ref.koap', 'search_read', null, {
            'domain': domain,
            'fields': [
              'id',
              'article',
              'paragraph',
              'text',
              'man_fine_from',
              'man_fine_to',
              'firm_fine_from',
              'firm_fine_to',
              'firm_stop',
              'desc',
            ]
          });

          break;
        case 'department':
          List<dynamic> domain = new List<dynamic>();
          if (lastUpdate != null) domain.add(lastUpdate);
          domain.add([
            'id',
            'in',
            [32229, 32230, 22886, 21818]
          ]);
          data =
              await getDataWithAttemp('eco.department', 'search_read', null, {
            'domain': domain,
            'fields': [
              'id',
              'name',
              'short_name',
              'rel_railway_id',
              'active',
              'f_inn',
              'f_ogrn',
              'f_okpo',
              'f_addr',
              'director_fio',
              'director_email',
              'director_phone',
              'deputy_fio',
              'deputy_email',
              'deputy_phone',
              'rel_sector_id',
              'f_coord_n',
              'f_coord_e'
            ],
            // 'limit': 100,
          });

          break;
        case 'user':
          List<dynamic> domain = new List<dynamic>();

          if (lastUpdate != null) domain.add(lastUpdate);
          listDepIds = await DepartmentController.selectIDs();
          if (listDepIds == null) continue;
          if (listDepIds.length > 0) if (userRoleTxt == ncopRole)
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
        case 'check_list':
          List<dynamic> domain = new List<dynamic>();
          if (lastUpdate != null) domain.add(lastUpdate);

          domain.add(['parent_id', '=', null]);
          domain.add(['is_base', '=', true]);
          data =
              await getDataWithAttemp('mob.check.list', 'search_read', null, {
            'domain': domain,
            'fields': [
              'id',
              'parent_id',
              'is_active',
              'base_id',
              'name',
              'type',
              'active',
              'type',
              'is_base',
              'child_ids'
            ]
          });
          if (data.length > 0) {
            for (var element in data) {
              var assignedQuestions = await getDataWithAttemp(
                  'mob.check.list.item', 'search_read', null, {
                'domain': [
                  ['id', 'in', element["child_ids"]]
                ],
                'fields': [
                  'id',
                  'parent_id',
                  'name',
                  'question',
                  'result',
                  'description',
                  'active',
                  'base_id',
                ]
              });

              for (var q in assignedQuestions) {
                //  As we perform first download from odoo, we set odooId as id of input
                q["odoo_id"] = q["id"];
                // If parent id exists like [3, someName]
                if (q["parent_id"] is List) {
                  var parent_id = q["parent_id"][0];
                  q["parent_id"] = parent_id;
                } else {
                  q["parent_id"] = null;
                }
              }

              element["q_data"] = assignedQuestions;
              // Set odooId as main ID for check list, as it's first download
              element["odoo_id"] = element["id"];
            }
          }
          break;
        case 'isp':
          List<dynamic> domain = new List<dynamic>();
          if (lastUpdate != null) domain.add(lastUpdate);

          data = await getDataWithAttemp(
              'mob.document_list', 'search_read', null, {
            'domain': domain,
            'fields': ['id', 'parent_id', 'name']
          });

          if (data.length > 0) {
            for (var docList in data) {
              // Это вложение
              if (docList["parent_id"] is List) {
                docList['parent_id'] = docList['parent_id'][0];
              }

              domain.add(['parent2_id', '=', docList["id"]]);

              var assignedDocs =
                  await getDataWithAttemp('mob.document', 'search_read', null, {
                'domain': domain,
                'fields': [
                  'id',
                  'parent2_id',
                  'name',
                  'file_name',
                  'type',
                  'number',
                  'description'
                ]
              });
              docList["docs"] = assignedDocs;

              // Update domain for new docListInputs
              domain = [];
              // IF not null get only last added docs!
              if (lastUpdate != null) domain.add(lastUpdate);
            }
          }
          break;
      } //switch
      if (data != null) {
        List<dynamic> dataList = data as List<dynamic>;
        for (int j = 0; j < dataList.length; j++) {
          switch (dicts[i]) {
            case 'railway':
              await RailwayController.insert(
                  dataList[j] as Map<String, dynamic>);
              break;
            case 'koap':
              await KoapController.insert(dataList[j] as Map<String, dynamic>);
              break;
            case 'department':
              await DepartmentController.insert(
                  dataList[j] as Map<String, dynamic>);
              break;
            case 'user':
              await UserController.insert(dataList[j] as Map<String, dynamic>);
              break;
            case 'check_list':
              await CheckListController.insert(
                  dataList[j] as Map<String, dynamic>);
              if (dataList[j]["q_data"].length > 0) {
                for (var payload in dataList[j]["q_data"]) {
                  await CheckListItemController.insert(
                      payload as Map<String, dynamic>);
                }
              }
              break;
            case 'isp':
              await DocumentListController.insert(
                  dataList[j] as Map<String, dynamic>);

              if (dataList[j]["docs"].length > 0) {
                for (var doc in dataList[j]["docs"]) {
                  if (doc['parent2_id'] is List) {
                    doc['parent2_id'] = doc['parent2_id'][0];
                  }
                  // Important!
                  doc['is_new'] = true;
                  await ISPDocumentController.insert(
                      doc as Map<String, dynamic>);
                }
              }
          } //switch
        } //for j

        var recordCount = (data as List<dynamic>).length.toString();
        print('Recived $recordCount records');
        LogController.insert('Recived $recordCount records');
        LogController.insert("----------------------------------------");

        result.add({
          dicts[i]: [1, recordCount]
        });

        await setLastUpdate(dicts[i]);
      } //if (data!=null)
    } //try
    catch (e) {
      print(e);
      LogController.insert('error: $e');
      result.add({
        dicts[i]: [-1, e.toString()]
      });
    }
  } //for i
  LogController.insert('=========================================');
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
    LogController.insert('Attempt ${curAttempt.toString()}..........');
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

  DateTime dateTime = DateTime.now();
  dateTime = toServerTime(dateTime);
  print("Datetime SetLastUpdate $dateTime");
  if (sLastUpdate == null)
    lastUpdate = {modelName: dateTime.toString()};
  else {
    lastUpdate = json.decode(sLastUpdate);
    lastUpdate[modelName] = dateTime.toString();
  }

  await _storage.write(key: 'lastDateUpdate', value: json.encode(lastUpdate));
}

Future<List> getLastSyncDateDomain(modelName) async {
  String sLastUpdate = await _storage.read(key: 'lastDateUpdate');
  if (sLastUpdate == null)
    return [
      [
        'active',
        'in',
        [true, false]
      ]
    ];
  Map<String, dynamic> lastUpdate = json.decode(sLastUpdate);
  if (lastUpdate[modelName] == null)
    return [
      [
        'active',
        'in',
        [true, false]
      ]
    ];
  DateTime datetime = stringToDateTime(lastUpdate[modelName]);
  datetime = toServerTime(datetime);
  return [
    [
      'write_date',
      '>',
      dateTimeToString(datetime, true),
    ],
    [
      'active',
      'in',
      [true, false]
    ]
  ];
}

Future<void> setLastSyncDateForDomain(modelName, DateTime dateTime) async {
  String sLastUpdate = await _storage.read(key: 'lastDateUpdate');
  Map<String, dynamic> lastUpdate;
  if (sLastUpdate == null)
    lastUpdate = {modelName: dateTimeToString(dateTime, true)};
  else {
    lastUpdate = json.decode(sLastUpdate);
    lastUpdate[modelName] = dateTimeToString(dateTime, true);
  }

  await _storage.write(key: 'lastDateUpdate', value: json.encode(lastUpdate));
}

Future<void> removeLastSyncDate(modelName) async {
  String sLastUpdate = await _storage.read(key: 'lastDateUpdate');
  Map<String, dynamic> lastUpdate;
  if (sLastUpdate == null)
    return;
  else {
    lastUpdate = json.decode(sLastUpdate);
    lastUpdate.remove(modelName);
  }

  await _storage.write(key: 'lastDateUpdate', value: json.encode(lastUpdate));
}
