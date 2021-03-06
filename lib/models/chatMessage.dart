import 'package:ek_asu_opb_mobile/controllers/controllers.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import "package:ek_asu_opb_mobile/models/models.dart";

class ChatMessage extends Models {
  int id;
  int odooId;

  ///Id чата
  int parentId;
  Chat _parent;

  ///Сообщение
  String message;

  ///Дата создания
  DateTime createDate;

  /// Id автора сообщения
  int userId;
  User _user;

  ///Группа
  Future<Chat> get parent async {
    if (_parent == null) _parent = await ChatController.selectById(parentId);
    return _parent;
  }

  ///Пользователь
  Future<User> get user async {
    if (_user == null) _user = await UserController.selectById(userId);
    return _user;
  }

  ChatMessage({
    this.id,
    this.odooId,
    this.parentId,
    this.message,
    this.createDate,
    this.userId,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    ChatMessage res = new ChatMessage(
      id: json["id"],
      odooId: json["odoo_id"],
      parentId: unpackListId(json["parent_id"])['id'],
      message: getObj(json["msg"]),
      createDate: stringToDateTime(json['create_date']),
      userId: unpackListId(json["create_uid"])['id'],
    );
    return res;
  }

  Map<String, dynamic> toJson([omitId = false]) {
    Map<String, dynamic> res = {
      'id': id,
      'odoo_id': odooId,
      'parent_id': parentId,
      'msg': message,
      'create_date': dateTimeToString(createDate, true),
      'create_uid': userId,
    };
    if (omitId) {
      res.remove('id');
      res.remove('odoo_id');
    }
    return res;
  }

  @override
  String toString() {
    return 'ChatMessage{odooId: $odooId, id: $id, parentId=$parentId, message=$message';
  }
}
