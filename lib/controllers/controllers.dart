export 'package:ek_asu_opb_mobile/controllers/railway.dart';
export 'package:ek_asu_opb_mobile/controllers/department.dart';
export 'package:ek_asu_opb_mobile/controllers/userInfo.dart';
export 'package:ek_asu_opb_mobile/controllers/user.dart';
export 'package:ek_asu_opb_mobile/controllers/log.dart';
export 'package:ek_asu_opb_mobile/controllers/plan.dart';
export 'package:ek_asu_opb_mobile/controllers/planItem.dart';
export 'package:ek_asu_opb_mobile/controllers/checkPlan.dart';
export 'package:ek_asu_opb_mobile/src/db.dart';

abstract class Controllers {
  static Future<dynamic> insert(Map<String, dynamic> json) async {}
  static select() {}
  static selectById() {}
  static update() {}
  static delete() {}
  static loadFromOdoo([limit]) async {}
  static Map<String, dynamic> getNullSafeWhere(Map<String, dynamic> args) {
    List where = [];
    List whereArgs = [];
    args.entries.forEach((el) {
      String whereEl = el.key;
      if (el.value == null)
        whereEl += ' IS NULL';
      else {
        whereEl += ' = ?';
        whereArgs.add(el.value);
      }
      where.add(whereEl);
    });
    return {'where': where.join(' and '), 'whereArgs': whereArgs};
  }
}
