import 'package:ek_asu_opb_mobile/controllers/checkPlan.dart';
import 'package:ek_asu_opb_mobile/controllers/controllers.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import "package:ek_asu_opb_mobile/models/models.dart";

class PlanItem extends Models {
  int id;
  int odooId;

  ///Id плана проверки
  int parentId;
  Plan _parent;

  ///Наименование
  String name;

  ///Подразделения
  String departmentTxt;

  ///Ключ вида проверки
  int checkType;

  ///Ключ срока проверки
  int period;

  ///Ответственные
  String responsible;

  ///Результат проверки
  String checkResult;

  ///Действует
  bool active = true;

  ///Варианты вида проверки
  static Map<int, String> checkTypeSelection = {
    1: 'Комплексный аудит',
    2: 'Целевая проверка',
    3: 'Внеплановая проверка',
  };

  ///Варианты срока проверки
  static Map<int, String> periodSelection = {
    1: 'I Квартал',
    2: 'II Квартал',
    3: 'III Квартал',
    4: 'IV Квартал',
  };

  ///Значение вида проверки
  String get checkTypeDisplay {
    if (checkType != null && checkTypeSelection.containsKey(checkType))
      return checkTypeSelection[checkType];
    return checkType.toString();
  }

  ///Значение срока проверки
  String get periodDisplay {
    if (period != null && periodSelection.containsKey(period))
      return periodSelection[period];
    return period.toString();
  }

  ///Плана проверки
  Future<Plan> get parent async {
    if (_parent == null) _parent = await PlanController.selectById(parentId);
    return _parent;
  }

  ///Пункты плана
  Future<List<CheckPlan>> get items async {
    return await CheckPlanController.select(id);
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
      parentId: unpackListId(json["parent_id"])['id'],
      name: getObj(json["name"]),
      departmentTxt: getObj(json["department_txt"]),
      checkType: getObj(json["check_type"]),
      period: getObj(json["period"]),
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
