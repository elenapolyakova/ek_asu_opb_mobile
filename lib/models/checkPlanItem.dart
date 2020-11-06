import 'package:ek_asu_opb_mobile/controllers/department.dart'
    as departmentController;
import 'package:ek_asu_opb_mobile/models/checkPlan.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import "package:ek_asu_opb_mobile/models/models.dart";

class CheckPlanItem extends Models {
  int id;
  int odooId;
  CheckPlan parent; //План проверки
  String name; //Наименование
  Department department; //Предприятие
  DateTime date; //Дата
  DateTime dtFrom; //Начало мероприятия
  DateTime dtTo; //Окончание мероприятия
  bool active; //Действует

  List<CheckPlanItem> get comUsers {
    //mob.check.plan.com_user
    return [];
  }

  CheckPlanItem({
    this.id,
    this.odooId,
    this.parent,
    this.name,
    this.department,
    this.date,
    this.dtFrom,
    this.dtTo,
    this.active,
  });

  factory CheckPlanItem.fromJson(Map<String, dynamic> json) {
    CheckPlanItem res = new CheckPlanItem(
      id: json["odoo_id"],
      odooId: json["id"],
      parent: CheckPlanController.selectById(json["parent_id"]),
      name: getObj(json["name"]),
      department:
          departmentController.Department.selectById(json["department_id"]),
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
      'parent_id': parent.id,
      'name': name,
      'department_id': department.id,
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
