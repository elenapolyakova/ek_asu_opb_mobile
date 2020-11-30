import 'package:ek_asu_opb_mobile/controllers/controllers.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import "package:ek_asu_opb_mobile/models/models.dart";

class Chat extends Models {
  int id;
  int odooId;

  ///Id рабочей группы
  int groupId;
  ComGroup _group;

  ///Тип
  int type;

  ///Варианты выбора для типа
  static Map<int, String> typeSelection = {
    1: 'С работником',
    2: 'С группой',
  };

  ///Значение принадлежности
  String get typeDisplay {
    if (type != null && typeSelection.containsKey(type))
      return typeSelection[type];
    return type.toString();
  }

  ///Работники
  Future<List<User>> get users async {
    return RelChatUserController.selectByChatId(id);
  }

  ///Группа
  Future<ComGroup> get group async {
    if (_group == null) _group = await ComGroupController.selectById(groupId);
    return _group;
  }

  ///Сообщения
  Future<List<ChatMessage>> get messages async {
    return ChatMessageController.select(id);
  }

  Chat({
    this.id,
    this.odooId,
    this.groupId,
    this.type,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    Chat res = new Chat(
      id: json["id"],
      odooId: json["odoo_id"],
      groupId: unpackListId(json["group_id"])['id'],
      type: getObj(json["type"]),
    );
    return res;
  }

  Map<String, dynamic> toJson([omitId = false]) {
    Map<String, dynamic> res = {
      'id': id,
      'odoo_id': odooId,
      'group_id': groupId,
      'type': type,
    };
    if (omitId) {
      res.remove('id');
      res.remove('odoo_id');
    }
    return res;
  }

  @override
  String toString() {
    return 'Chat{odooId: $odooId, id: $id, type: $typeDisplay${type == 1 ? '' : ', groupId=$groupId'}}';
  }
}
