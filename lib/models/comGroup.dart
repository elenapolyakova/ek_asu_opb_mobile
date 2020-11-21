import 'package:ek_asu_opb_mobile/controllers/checkPlan.dart';
import 'package:ek_asu_opb_mobile/controllers/controllers.dart';
import 'package:ek_asu_opb_mobile/controllers/relComGroupUser.dart';
import 'package:ek_asu_opb_mobile/models/checkPlan.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import "package:ek_asu_opb_mobile/models/models.dart";

class ComGroup extends Models {
  int id;
  int odooId;

  ///Id плана проверки
  int parentId;
  CheckPlan _parent;

  ///Id Руководителя
  int headId;
  User _head;

  ///Номер группы
  String groupNum;

  ///Группа - комиссия
  bool isMain;

  ///Действует
  bool active;

  ///Участники
  Future<List<User>> get comUsers async {
    return RelComGroupUserController.selectByComGroupId(id);
  }

  ///План проверки
  Future<CheckPlan> get parent async {
    if (_parent == null)
      _parent = await CheckPlanController.selectById(parentId);
    return _parent;
  }

  ///Руководитель
  Future<User> get head async {
    if (_head == null) _head = await UserController.selectById(headId);
    return _head;
  }

  // set comUsers(Future<List<User>> users) {
  //   //mob.check.plan.com_group
  //   return null;
  // }

  ComGroup({
    this.id,
    this.odooId,
    this.parentId,
    this.headId,
    this.groupNum,
    this.isMain,
    this.active,
  });

  factory ComGroup.fromJson(Map<String, dynamic> json) {
    ComGroup res = new ComGroup(
      id: json["id"],
      odooId: json["odoo_id"],
      parentId: unpackListId(json["parent_id"])['id'],
      headId: unpackListId(json["head_id"])['id'],
      groupNum: getObj(json["group_num"]),
      isMain: json["is_main"] == 'true',
      active: json["active"] == 'true',
    );
    return res;
  }

  Map<String, dynamic> toJson([omitId = false]) {
    Map<String, dynamic> res = {
      'id': id,
      'odoo_id': odooId,
      'parent_id': parentId,
      'head_id': headId,
      'group_num': groupNum,
      'is_main': (isMain == null || !isMain) ? 'false' : 'true',
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
    return 'ComGroup{odooId: $odooId, id: $id, head_id: $headId}';
  }
}
