//not for bool field!
String getStr(dynamic source) {
  if (source is bool) if (!source) return "";
  return source.toString();
}

//not for bool field!
dynamic getObj(dynamic source) {
  if (source is bool) if (!source) return null;
  return source;
}

//not for bool field!
int getIdFromList(dynamic source) {
  if (getObj(source) != null) {
    if (source is List<dynamic>)
      return int.tryParse((source as List<dynamic>)[0].toString());
    return source;
  }

  return null;
}

String dateStr(DateTime dt) =>
    '${addZero(dt.day)}.${addZero(dt.month)}.${dt.year} ${addZero(dt.hour)}:${addZero(dt.minute)}:${addZero(dt.second)}';

String dateDMY(DateTime dt) =>
    '${addZero(dt.day)}.${addZero(dt.month)}.${dt.year}';

String dateHm(DateTime dt) => '${addZero(dt.hour)}:${addZero(dt.minute)}';

String nowStr() => dateStr(DateTime.now());

String addZero(val) => slice(('0' + val.toString()), -2);

String slice(String subject, [int start = 0, int end]) {
  if (subject is! String) {
    return '';
  }

  int _realEnd;
  int _realStart = start < 0 ? subject.length + start : start;
  if (end is! int) {
    _realEnd = subject.length;
  } else {
    _realEnd = end < 0 ? subject.length + end : end;
  }

  return subject.substring(_realStart, _realEnd);
}

Map<String, dynamic> unpackListId(listId) {
  Map<String, dynamic> res = {
    'id': null,
    'name': null,
  };
  if (!(listId is bool) && listId != null && listId.length > 0) {
    res['id'] = listId[0];
    res['name'] = listId[1];
  }
  return res;
}

List<Map<String, dynamic>> makeListFromJson(Map<dynamic, dynamic> json) {
  return List<Map<String, dynamic>>.generate(json.keys.length, (i) {
    dynamic key = (json.keys.toList())[i];
    return {'id': key.toString(), 'value': json[key]};
  });
}

bool isDateEqual(DateTime dt1, DateTime dt2) {
  return dt1.year == dt2.year && dt1.month == dt2.month && dt1.day == dt2.day;
}

DateTime stringToDateTime(dynamic date) {
  if (date is bool && !date) return null;
  return DateTime.tryParse(date);
}

String dateTimeToString(DateTime date, [bool includeTime = false]) {
  List<String> dateSplit = date.toIso8601String().split(':');
  if (!includeTime) return dateSplit[0];
  return "${dateSplit[0]} ${dateSplit.sublist(1).join('')}";
}
