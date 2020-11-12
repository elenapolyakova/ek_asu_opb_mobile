import 'package:ek_asu_opb_mobile/controllers/controllers.dart';

const _resultList = [
  {"id": 1, "value": "Приказ"},
  {"id": 2, "value": "Протокол"},
  {"id": 3, "value": "Корректирующие меры"},
];

const _eventList = [
  {"id": 1, "value": "Проверка"},
  {"id": 2, "value": "Встреча"},
  {"id": 3, "value": "Отъезд"},
  {"id": 4, "value": "Обед"},
  {"id": 100, "value": "Прочее"},
];

List<Map<String, Object>> getResultList() => _resultList;
Map<String, Object> getResultById(int _id) =>
    _resultList.firstWhere((result) => result["id"] == _id);

Future<List<Map<String, dynamic>>> getRailwayList() async {
  List<Map<String, dynamic>> result = [];
  List<Map<String, dynamic>> railwayList = await RailwayController.selectAll();

  railwayList.forEach((railway) {
    result
        .add({"id": railway["id"], "value": railway["name"].toString().trim()});
  });

  return result;
}

List<Map<String, Object>> getEventInspectionList() => _eventList;
Map<String, Object> getEventInspectionById(int _id) =>
    _eventList.firstWhere((result) => result["id"] == _id);
