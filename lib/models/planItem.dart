import 'package:ek_asu_opb_mobile/controllers/controllers.dart';
import 'package:ek_asu_opb_mobile/models/checkPlanItem.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import "package:ek_asu_opb_mobile/models/models.dart";

class PlanItem extends Models {
  int id;
  int odooId;
  int parentId; //План проверки
  Plan _parent; //План проверки
  String name; //Наименование
  String departmentTxt; //Подразделения
  int checkType; //Вид проверки
  int period; //Срок проверки
  String responsible; //Ответственные
  String checkResult; //Результат проверки
  bool active = true; //Действует

  static Map<int, String> checkTypeSelection = {
    1: 'Комплексный аудит',
    2: 'Целевая проверка',
    3: 'Внеплановая проверка',
  };

  static Map<int, String> periodSelection = {
    1: 'I Квартал',
    2: 'II Квартал',
    3: 'III Квартал',
    4: 'IV Квартал',
  };

  dynamic get checkTypeDisplay {
    if (checkType != null && checkTypeSelection.containsKey(checkType))
      return checkTypeSelection[checkType];
    return checkType;
  }

  dynamic get periodDisplay {
    if (period != null && periodSelection.containsKey(period))
      return periodSelection[period];
    return period;
  }

  Future<Plan> get parent async {
    if (_parent == null) _parent = await PlanController.selectById(parentId);
    return _parent;
  }

  List<CheckPlanItem> get items {
    //mob.check.plan
    return [];
  }

  PlanItem({
    this.id,
    this.odooId,
    this.parentId,
    this.name,
    this.departmentTxt,
    this.checkType,
    this.period,
    this.responsible,
    this.checkResult,
    this.active,
  });

  factory PlanItem.fromJson(Map<String, dynamic> json) {
    PlanItem res = new PlanItem(
      id: json["id"],
      odooId: json["odoo_id"],
      parentId: (json["parent_id"] is List)
          ? unpackListId(json["parent_id"])['id']
          : json["parent_id"],
      name: getObj(json["name"]),
      departmentTxt: getObj(json["department_txt"]),
      checkType: json["check_type"],
      period: json["period"],
      responsible: getObj(json["responsible"]),
      checkResult: getObj(json["check_result"]),
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
      'department_txt': departmentTxt,
      'check_type': checkType,
      'period': period,
      'responsible': responsible,
      'check_result': checkResult,
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
    return 'PlanItem{odooId: $odooId, id: $id, name: $name}';
  }
}
