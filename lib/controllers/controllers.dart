export 'package:ek_asu_opb_mobile/controllers/railway.dart';
export 'package:ek_asu_opb_mobile/controllers/department.dart';
export 'package:ek_asu_opb_mobile/controllers/userInfo.dart';
export 'package:ek_asu_opb_mobile/controllers/user.dart';
export 'package:ek_asu_opb_mobile/controllers/log.dart';
export 'package:ek_asu_opb_mobile/controllers/plan.dart';
export 'package:ek_asu_opb_mobile/src/db.dart';

abstract class Controllers {
  static Future<dynamic> insert(Map<String, dynamic> json) async {}
  static select() {}
  static update() {}
  static delete() {}
  static loadFromOdoo([limit]) async {}
}
