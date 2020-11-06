import 'package:ek_asu_opb_mobile/controllers/controllers.dart' as controllers;

const _typeInspectionList = [
  {"id": 1, "value": "Комплексный аудит"},
  {"id": 2, "value": "Целевая"},
  {"id": 3, "value": "Внеплановая"},
];

const _periodInspectionList = [
  {"id": 1, "value": "I квартал"},
  {"id": 2, "value": "II квартал"},
  {"id": 3, "value": "III квартал"},
  {"id": 4, "value": "IV квартал"},
];

const _resultList = [
  {"id": 1, "value": "Приказ"},
  {"id": 2, "value": "Протокол"},
  {"id": 3, "value": "Корректирующие меры"},
];

const _eventList = [
  {"id": 1, "value": "Проверка"},
  {"id": 2, "value": "Встреча"},
  {"id": 3, "value": "Завтрак"},
  {"id": 4, "value": "Обед"},
  {"id": 5, "value": "Отъезд"},
  {"id": 100, "value": "Прочее"},
];


List<Map<String, Object>> getTypeInspectionList() => _typeInspectionList;
Map<String, Object> getTypeInspectionById(int _id) =>
    _typeInspectionList.firstWhere((result) => result["id"] == _id);

List<Map<String, Object>> getPeriodInspectionList() => _periodInspectionList;
Map<String, Object> getPeriodInspectionById(int _id) =>
    _periodInspectionList.firstWhere((result) => result["id"] == _id);

List<Map<String, Object>> getResultList() => _resultList;
Map<String, Object> getResultById(int _id) =>
    _resultList.firstWhere((result) => result["id"] == _id);

Future<List<Map<String, dynamic>>> getRailwayList() async {
  List<Map<String, dynamic>> result = [];
  List<Map<String, dynamic>> railwayList =
      await controllers.Railway.selectAll();

  railwayList.forEach((railway) {
    result
        .add({"id": railway["id"], "value": railway["name"].toString().trim()});
  });

  return result;
}

List<Map<String, Object>> getEventInspectionList() => _eventList;
Map<String, Object> getEventInspectionById(int _id) =>
    _eventList.firstWhere((result) => result["id"] == _id);
