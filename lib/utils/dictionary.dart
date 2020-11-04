
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

List<Map<String, Object>> getTypeInspectionList() => _typeInspectionList;
Map<String, Object> getTypeInspectionById(int _id) =>
    _typeInspectionList.firstWhere((result) => result["id"] == _id);

List<Map<String, Object>> getPeriodInspectionList() => _periodInspectionList;
Map<String, Object> getPeriodInspectionById(int _id) =>
    _periodInspectionList.firstWhere((result) => result["id"] == _id);

List<Map<String, Object>> getResultList() => _resultList;
Map<String, Object> getResultById(int _id) =>
    _resultList.firstWhere((result) => result["id"] == _id);

// Future<bool> getDictionary() async {
//   var lastUpdate = await _storage.read(key: 'lastDateUpdate');

// }
