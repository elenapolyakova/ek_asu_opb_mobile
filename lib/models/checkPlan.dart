import 'package:ek_asu_opb_mobile/controllers/railway.dart'
    as railwayController;
import 'package:ek_asu_opb_mobile/models/checkPlanItem.dart';
import 'package:ek_asu_opb_mobile/models/planItem.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import "package:ek_asu_opb_mobile/models/models.dart";

class CheckPlan extends Models {
  int id;
  int odooId;
  PlanItem parent; //План проверки
  String name; //Наименование
  Railway railway; //Дорога
  DateTime dateFrom; //Начало проверки
  DateTime dateTo; //Окончание проверки
  DateTime dateSet; //Дата утверждения
  String state; //Состояние
  String signerName; //Подписант. Имя
  String signerPost; //Подписант. Должность
  String appName; //Кто утвердил. Имя
  String appPost; //Кто утвердил. Должность
  String numSet; //Номер
  bool active; //Действует

  static Map<String, String> stateSelection = {
    'draft': 'Черновик',
    'approved': 'Утверждено',
  };

  String get stateDisplay {
    if (state != null && stateSelection.containsKey(state))
      return stateSelection[state];
    return state;
  }

  List<CheckPlanItem> get items {
    //mob.check.plan.item
    return [];
  }

  List<CheckPlanItem> get comUsers {
    //mob.check.plan.com_user
    return [];
  }

  CheckPlan({
    this.id,
    this.odooId,
    this.parent,
    this.name,
    this.railway,
    this.dateFrom,
    this.dateTo,
    this.dateSet,
    this.state,
    this.signerName,
    this.signerPost,
    this.appName,
    this.appPost,
    this.numSet,
    this.active,
  });

  factory CheckPlan.fromJson(Map<String, dynamic> json) {
    CheckPlan res = new CheckPlan(
      odooId: json["odoo_id"],
      id: json["id"],
      parent: PlanItemController.selectById(json["parent_id"]),
      name: getObj(json["name"]),
      railway: railwayController.Railway.selectById((json["railway_id"] is List)
          ? unpackListId(json["railway_id"])['id']
          : json["railway_id"]),
      dateFrom:
          json["date_from"] == null ? null : DateTime.parse(json["date_from"]),
      dateTo: json["date_to"] == null ? null : DateTime.parse(json["date_to"]),
      dateSet:
          json["date_set"] == null ? null : DateTime.parse(json["date_set"]),
      state: getObj(json["state"]),
      signerName: getObj(json["signer_name"]),
      signerPost: getObj(json["signer_post"]),
      appName: getObj(json["app_name"]),
      appPost: getObj(json["app_post"]),
      numSet: getObj(json["num_set"]),
      active: json["active"] == 'true',
    );
    return res;
  }

  Map<String, dynamic> toJson([omitId = false]) {
    Map<String, dynamic> res = {
      'odoo_id': odooId,
      'id': id,
      'parent_id': parent.id,
      'name': name,
      'railway_id': railway.id,
      'date_from': dateFrom.toIso8601String().split(':')[0],
      'date_to': dateTo.toIso8601String().split(':')[0],
      'date_set': dateSet.toIso8601String().split(':')[0],
      'state': state,
      'signer_name': signerName,
      'signer_post': signerPost,
      'app_name': appName,
      'app_post': appPost,
      'num_set': numSet,
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
    return 'CheckPlan{odooId: $odooId, id: $id, name: $name}';
  }
}
