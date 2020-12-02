import 'package:ek_asu_opb_mobile/controllers/controllers.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import "package:ek_asu_opb_mobile/models/models.dart";

class Chat extends Models {
  int id;
  int odooId;

  ///Наименование
  String name;

  ///Тип
  int type;

  ///Id рабочей группы
  int groupId;
  ComGroup _group;

  ///Дата последнего чтения количества сообщений
  DateTime lastUpdate;

  ///Дата последнего чтения сообщений
  DateTime lastRead;

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
  Future<List<ChatMessage>> get messages {
    return ChatMessageController.select(id);
  }

  ///Количество новых сообщений с сервера
  Future<int> get newMessagesFromOdooCount {
    return ChatMessageController.newMessagesFromOdooCount(this);
  }

  ///Количество новых сообщений
  Future<int> getNewMessagesCount(int userId) {
    return ChatMessageController.newMessagesCount(this, userId);
  }

  ///Количество новых сообщений, начиная с даты
  Future<int> newMessagesCountFromDate(int userId, DateTime dateTime) {
    return ChatMessageController.newMessagesCountFromDate(
        this, userId, dateTime);
  }

  Chat({
    this.id,
    this.odooId,
    this.name,
    this.groupId,
    this.type,
    this.lastUpdate,
    this.lastRead,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    Chat res = new Chat(
      id: json["id"],
      odooId: json["odoo_id"],
      name: getObj(json["name"]),
      groupId: unpackListId(json["group_id"])['id'],
      type: getObj(json["type"]),
      lastUpdate: stringToDateTime(json["last_update"]),
      lastRead: stringToDateTime(json["last_read"]),
    );
    return res;
  }

  Map<String, dynamic> toJson([omitId = false]) {
    Map<String, dynamic> res = {
      'id': id,
      'odoo_id': odooId,
      'name': name,
      'group_id': groupId,
      'type': type,
      'last_update': dateTimeToString(lastUpdate, true),
      'last_read': dateTimeToString(lastRead, true),
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
