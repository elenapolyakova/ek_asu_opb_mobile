import 'package:ek_asu_opb_mobile/controllers/checkPlan.dart';
import 'package:ek_asu_opb_mobile/controllers/controllers.dart' as controllers;
import 'package:ek_asu_opb_mobile/models/checkPlan.dart';
import 'package:ek_asu_opb_mobile/models/checkPlanItem.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import "package:ek_asu_opb_mobile/models/models.dart";

class PlanComUser extends Models {
  int id;
  int odooId;
  int parentId; //План проверки
  CheckPlan _parent; //План проверки
  int userId; //Пользователь
  User _user; //Пользователь
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
    this.parentId,
    this.userId,
    this.comRole,
    this.groupNum,
  });

  Future<CheckPlan> get parent async {
    if (_parent == null)
      _parent = await CheckPlanController.selectById(parentId);
    return _parent;
  }

  Future<User> get user async {
    if (_user == null) _user = await controllers.User.selectById(userId);
    return _user;
  }

  factory PlanComUser.fromJson(Map<String, dynamic> json) {
    PlanComUser res = new PlanComUser(
      id: json["odoo_id"],
      odooId: json["id"],
      parentId: (json["parent_id"] is List)
          ? unpackListId(json["parent_id"])['id']
          : json["parent_id"],
      userId: (json["user_id"] is List)
          ? unpackListId(json["user_id"])['id']
          : json["user_id"],
      comRole: json["com_role"],
      groupNum: json["group_num"],
    );
    return res;
  }

  Map<String, dynamic> toJson([omitId = false]) {
    Map<String, dynamic> res = {
      'id': id,
      'odoo_id': odooId,
      'parent_id': parentId,
      'user_id': userId,
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
    return 'PlanComUser{odooId: $odooId, id: $id, user_id: $userId}';
  }
}
