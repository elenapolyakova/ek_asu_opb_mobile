import 'package:ek_asu_opb_mobile/controllers/checkPlan.dart';
import 'package:ek_asu_opb_mobile/controllers/controllers.dart' as controllers;
import 'package:ek_asu_opb_mobile/models/checkPlan.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import "package:ek_asu_opb_mobile/models/models.dart";

class CheckPlanItem extends Models {
  int id;
  int odooId;
  int parentId; //План проверки
  CheckPlan _parent; //План проверки
  String name; //Наименование
  int departmentId; //Предприятие
  Department _department; //Предприятие
  DateTime date; //Дата
  DateTime dtFrom; //Начало мероприятия
  DateTime dtTo; //Окончание мероприятия
  bool active = true; //Действует

  List<CheckPlanItem> get comUsers {
    //mob.check.plan.com_user
    return [];
  }

  CheckPlanItem({
    this.id,
    this.odooId,
    this.parentId,
    this.name,
    this.departmentId,
    this.date,
    this.dtFrom,
    this.dtTo,
    this.active,
  });

  Future<Department> get department async {
    if (_department == null)
      _department = await controllers.Department.selectById(departmentId);
    return _department;
  }

  Future<CheckPlan> get parent async {
    if (_parent == null)
      _parent = await CheckPlanController.selectById(parentId);
    return _parent;
  }

  factory CheckPlanItem.fromJson(Map<String, dynamic> json) {
    CheckPlanItem res = new CheckPlanItem(
      id: json["odoo_id"],
      odooId: json["id"],
      parentId: (json["parent_id"] is List)
          ? unpackListId(json["parent_id"])['id']
          : json["parent_id"],
      name: getObj(json["name"]),
      departmentId: (json["department_id"] is List)
          ? unpackListId(json["department_id"])['id']
          : json["department_id"],
      date: json["date"] == null ? null : DateTime.parse(json["date"]),
      dtFrom: json["dt_from"] == null ? null : DateTime.parse(json["dt_from"]),
      dtTo: json["dt_to"] == null ? null : DateTime.parse(json["dt_to"]),
      active: json["active"] == 'true',
    );
    return res;
  }

  Map<String, dynamic> toJson([omitId = false]) {
    Map<String, dynamic> res = {
      'id': id,
      'odoo_id': odooId,
      'parent_id': parentId,
      'name': name,
      'department_id': departmentId,
      'date': date.toIso8601String().split(':')[0],
      'dt_from': dtFrom.toIso8601String().split(':')[0],
      'dt_to': dtTo.toIso8601String().split(':')[0],
      'active': (active == null || !active) ? 'false' : 'true',
    };
    if (omitId) {
      res.remove('id');
      res.remove('odoo_id');
    }
    return res;
  }

  @override
  String toString() {
    return 'CheckPlanItem{odooId: $odooId, id: $id, name: $name}';
  }
}
