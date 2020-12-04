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

String dateStr(DateTime dt) => dt == null
    ? ''
    : '${addZero(dt.day)}.${addZero(dt.month)}.${dt.year} ${addZero(dt.hour)}:${addZero(dt.minute)}:${addZero(dt.second)}';

String dateDMY(DateTime dt) =>
    dt == null ? '' : '${addZero(dt.day)}.${addZero(dt.month)}.${dt.year}';

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

/// Unpack from either:
/// listId = [id, name],
/// listId = false,
/// listId = id,
/// listId = "id",
/// ------------
/// Returns ```{'id': id, 'name': name}```
Map<String, dynamic> unpackListId(listId) {
  Map<String, dynamic> res = {
    'id': null,
    'name': null,
  };
  if (listId is int) {
    res['id'] = listId;
  } else if (listId is String) {
    res['id'] = int.tryParse(listId);
    if (res['id'] == null) res['name'] = listId;
  } else if (listId is List && listId.length > 0) {
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

DateTime stringToDateTime(dynamic date, {bool forceUtc: true}) {
  if (date == null || date is bool && !date) return null;
  return DateTime.tryParse(date).toUtc();
}

String dateTimeToString(DateTime date, [bool includeTime = false]) {
  if (date == null) return null;
  List<String> dateSplit = date.toIso8601String().split('T');
  if (!includeTime) return dateSplit[0];
  return "${dateSplit[0]} ${dateSplit.sublist(1).join('')}";
}

String emailValidator(String value) {
  if (value == '') return null;
  return !RegExp(r'^.+@.+\..+$', multiLine: false, caseSensitive: false)
          .hasMatch(value)
      ? "Неверный e-mail"
      : null;
}

/// Convert user time to server time.
///
/// :param: `date` can be either String or DateTime
DateTime toServerTime(date) {
  if (date is String) date = stringToDateTime(date);
  if (date == null) return null;
  return date;
}
