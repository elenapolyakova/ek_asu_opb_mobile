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

  ///Не архивирован
  bool active;

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

  ///Все сообщения
  ///
  ///Обновит `lastRead` на текущее время
  Future<List<ChatMessage>> get messages async {
    DateTime now = DateTime.now();
    Duration timeZoneOffset = now.timeZoneOffset;
    List<ChatMessage> res = await ChatMessageController.select(this);
    await DBProvider.db.update(
        'chat', {'id': id, 'last_read': dateTimeToString(now.toUtc(), true)});
    return res.map((e) {
      e.createDate = e.createDate.add(timeZoneOffset);
      return e;
    }).toList();
  }

  ///Новые сообщения после `lastRead`
  ///
  ///Обновит `lastRead` на текущее время
  Future<List<ChatMessage>> get getNewMessages async {
    DateTime now = DateTime.now();
    Duration timeZoneOffset = now.timeZoneOffset;
    List<ChatMessage> res = await ChatMessageController.select(this);
    if (lastRead != null) {
      res = res
          .where((ChatMessage element) => element.createDate.isAfter(lastRead))
          .toList();
    }
    List<DateTime> dates = res.map((ChatMessage e) => e.createDate).toList();
    if (dates.isNotEmpty) {
      dates.sort();
      await DBProvider.db.update('chat',
          {'id': id, 'last_read': dateTimeToString(dates.last.toUtc(), true)});
    }
    return res.map((e) {
      e.createDate = e.createDate.add(timeZoneOffset);
      return e;
    }).toList();
  }

  Chat({
    this.id,
    this.odooId,
    this.name,
    this.groupId,
    this.type,
    this.active = true,
    this.lastRead,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    Chat res = new Chat(
      id: json["id"],
      odooId: json["odoo_id"],
      name: getObj(json["name"]),
      groupId: unpackListId(json["group_id"])['id'],
      type: getObj(json["type"]),
      active: json["active"] == 'true',
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
      'active': (active == null || !active) ? 'false' : 'true',
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
