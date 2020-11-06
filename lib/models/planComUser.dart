import 'package:ek_asu_opb_mobile/models/checkPlan.dart';
import 'package:ek_asu_opb_mobile/models/checkPlanItem.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import "package:ek_asu_opb_mobile/models/models.dart";

class PlanComUser extends Models {
  int id;
  int odooId;
  CheckPlan parent; //План проверки
  User user; //Пользователь
  int comRole; //Роль
  int groupNum; //Номер группы

  static Map<int, String> comRoleSelection = {
    1: 'Председатель комиссии',
    2: 'Руководитель группы',
    3: 'Участник',
  };

  List<CheckPlanItem> get checkPlanItems {
    //mob.check.plan.item
    return [];
  }

  PlanComUser({
    this.id,
    this.odooId,
    this.parent,
    this.user,
    this.comRole,
    this.groupNum,
  });

  factory PlanComUser.fromJson(Map<String, dynamic> json) {
    PlanComUser res = new PlanComUser(
      id: json["odoo_id"],
      odooId: json["id"],
      parent: CheckPlanController.selectById(json["parent_id"]),
      user: UserController.selectById(json["user_id"]),
      comRole: json["com_role"],
      groupNum: json["group_num"],
    );
    return res;
  }

  Map<String, dynamic> toJson([omitId = false]) {
    Map<String, dynamic> res = {
      'id': id,
      'odoo_id': odooId,
      'parent_id': parent.id,
      'user_id': user.id,
      'com_role': comRole,
      'group_num': groupNum,
    };
    if (omitId) {
      res.remove('id');
      res.remove('odoo_id');
    }
    return res;
  }

  @override
  String toString() {
    return 'PlanComUser{odooId: $odooId, id: $id, login: ${user.login}}';
  }
}
