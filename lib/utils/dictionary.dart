const _typeInspectionList = [
  {"id": 1, "name": "Комплексный аудит"},
  {"id": 2, "name": "Целевая"},
  {"id": 3, "name": "Внеплановая"},
];

const _periodInspectionList = [
  {"id": 1, "name": "I квартал"},
  {"id": 2, "name": "II квартал"},
  {"id": 3, "name": "III квартал"},
  {"id": 4, "name": "IV квартал"},
];

const _resultList = [
  {"id": 1, "name": "Приказ"},
  {"id": 2, "name": "Протокол"},
  {"id": 3, "name": "Корректирующие меры"},
];



List<Map<String,Object>> getTypeInspectionListt () => _typeInspectionList;
Map<String,Object> getTypeInspectionById (int _id) => _typeInspectionList.firstWhere((result) => result["id"] == _id);

List<Map<String,Object>> getPeriodInspectionList () => _periodInspectionList;
Map<String,Object> getPeriodInspectionById (int _id) => _periodInspectionList.firstWhere((result) => result["id"] == _id);

List<Map<String,Object>> getResultList () => _resultList;
Map<String,Object> getResultById (int _id) => _resultList.firstWhere((result) => result["id"] == _id);