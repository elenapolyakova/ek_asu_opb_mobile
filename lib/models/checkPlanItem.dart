import 'package:ek_asu_opb_mobile/controllers/checkPlan.dart';
import 'package:ek_asu_opb_mobile/controllers/comGroup.dart';
import 'package:ek_asu_opb_mobile/controllers/controllers.dart';
import 'package:ek_asu_opb_mobile/models/checkPlan.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import "package:ek_asu_opb_mobile/models/models.dart";
import 'package:ek_asu_opb_mobile/models/comGroup.dart';

class CheckPlanItem extends Models {
  int id;
  int odooId;

  ///Id плана проверки
  int parentId;
  CheckPlan _parent;

  ///Наименование
  String name;

  ///Ключ действия
  int type;

  ///Id предприятия
  int departmentId;
  Department _department;

  ///Дата
  DateTime date;

  ///Начало мероприятия (with time)
  DateTime dtFrom;

  ///Окончание мероприятия (with time)
  DateTime dtTo;

  ///Действует
  bool active = true;

  ///ID рабочей группы
  int comGroupId;
  ComGroup _comGroup;

  static Map<int, String> typeSelection = {
    1: 'Приезд',
    2: 'Обед',
    3: 'Выезд на объект',
    4: 'Отъезд',
    99: 'Прочее',
  };

  ///Значение состояния
  String get stateDisplay {
    if (type != null && typeSelection.containsKey(type))
      return typeSelection[type];
    return type.toString();
  }

  /// Рабочая группа
  Future<ComGroup> get comGroup async {
    if (_comGroup == null)
      _comGroup = await ComGroupController.selectById(comGroupId);
    return _comGroup;
  }

  ///Предприятие
  Future<Department> get department async {
    if (_department == null)
      _department = await DepartmentController.selectById(departmentId);
    return _department;
  }

  ///План проверки
  Future<CheckPlan> get parent async {
    if (_parent == null)
      _parent = await CheckPlanController.selectById(parentId);
    return _parent;
  }

  CheckPlanItem({
    this.id,
    this.odooId,
    this.parentId,
    this.name,
    this.type,
    this.departmentId,
    this.date,
    this.dtFrom,
    this.dtTo,
    this.active,
    this.comGroupId,
  });

  factory CheckPlanItem.fromJson(Map<String, dynamic> json) {
    CheckPlanItem res = new CheckPlanItem(
      id: json["id"],
      odooId: json["odoo_id"],
      parentId: unpackListId(json["parent_id"])['id'],
      name: getObj(json["name"]),
      type: getObj(json["type"]),
      departmentId: unpackListId(json["department_id"])['id'],
      date: stringToDateTime(json["date"], forceUtc: false),
      dtFrom: stringToDateTime(json["dt_from"], forceUtc: false),
      dtTo: stringToDateTime(json["dt_to"], forceUtc: false),
      active: json["active"] == 'true',
      comGroupId: unpackListId(json["com_group_id"])['id'],
    );
    return res;
  }

  Map<String, dynamic> toJson([omitId = false]) {
    Map<String, dynamic> res = {
      'id': id,
      'odoo_id': odooId,
      'parent_id': parentId,
      'name': name,
      'type': type,
      'department_id': departmentId,
      'date': dateTimeToString(date),
      'dt_from': dateTimeToString(dtFrom, true),
      'dt_to': dateTimeToString(dtTo, true),
      'active': (active == null || !active) ? 'false' : 'true',
      'com_group_id': comGroupId,
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
