import 'package:ek_asu_opb_mobile/controllers/controllers.dart';

const _resultList = [
  {"id": 1, "value": "Приказ"},
  {"id": 2, "value": "Протокол"},
  {"id": 3, "value": "Корректирующие меры"},
];
const _monthList = [
  {
    "name": "Январь",
    "short_name": "Янв",
    'to_name': "Январю",
    'from': "Января"
  },
  {
    "name": "Февраль",
    "short_name": "Фев",
    'to_name': "Февралю",
    'from': "Февраля"
  },
  {
    "name": "Март",
    "short_name": "Март",
    'to_name': "Марту",
    'from': "Марта"
  },
  {
    "name": "Апрель",
    "short_name": "Апр",
    'to_name': "Апрелю",
    'from': "Апреля"
  },
  {
    "name": "Май",
    "short_name": "Май",
    'to_name': "Маю",
    'from': "Мая"
  },
  {
    "name": "Июнь",
    "short_name": "Июн",
    'to_name': "Июню",
    'from': "Июня"
  },
   {
    "name": "Июль",
    "short_name": "Июл",
    'to_name': "Июлю",
    'from': "Июля"
  },
  {
    "name": "Август",
    "short_name": "Авг",
    'to_name': "Августу",
    'from': "Августа"
  },
  {
    "name": "Сентябрь",
    "short_name": "Сен",
    'to_name': "Сентябрю",
    'from': "Сентября"
  },
  {
    "name": "Октябрь",
    "short_name": "Окт",
    'to_name': "Октябрю",
    'from': "Октября"
  },
  {
    "name": "Ноябрь",
    "short_name": "Ноя",
    'to_name': "Ноябрю",
    'from': "Ноябрь"
  },
  {
    "name": "Декабрь",
    "short_name": "Дек",
    'to_name': "Декабрь",
    'from': "Декабря"
  },
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

Future<List<Map<String, dynamic>>> getRailwayForChart() async {
  List<Map<String, dynamic>> result = [];
  List<Map<String, dynamic>> railwayList = await RailwayController.selectAll();

  result.add({"id": -1, "name": 'всем полигонам'});

  railwayList.forEach((railway) {
    result.add({
      "id": railway["id"],
      "name": railway["short_name"].toString().trim().toLowerCase() + ' ж.д.'
    });
  });

  return result;
}

List<Map<String, dynamic>> getYearForChart(int year) {
  List<Map<String, dynamic>> yearList = [];
  for (int i = year; i >= year - 5; i--)
    yearList.add({"id": i, "name": i.toString()});
  return yearList;
}

List<Map<String, dynamic>> getMonthList() => _monthList;
