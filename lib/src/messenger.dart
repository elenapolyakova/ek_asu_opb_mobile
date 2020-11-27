import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final _storage = FlutterSecureStorage();

class Chat {
  int id;
  String name;
  int type;
  List<int> reciverUserIds;
  Chat(this.id, this.name, this.reciverUserIds, this.type);
  static Map<int, String> typeSelection = {1: 'С работником', 2: 'С группой'};
}

class MyChat {
  Chat item;
  int countMessage;
  DateTime dtLastLoadMessage;
  /* MyChat(id, name, reciverUserIds, type,
      {this.countMessage = 0, this.dtLastLoadMessage}) {
    item = Chat(id, name, reciverUserIds, type);
  }*/
  MyChat(this.item, {this.countMessage = 0, this.dtLastLoadMessage});

  ///Варианты  типа чата
  static Map<int, String> typeSelection = {1: 'С работником', 2: 'С группой'};
}

class MyMessage {
  int id;
  int parent_id; //ссылка на чат
  int userId;
  String msg;
  DateTime dt;
  MyMessage(this.id, this.parent_id, this.msg, this.dt, this.userId);
}

class Messenger {
  Messenger._();
  static final Messenger messenger = Messenger._();
  int _countMessage = 0;

  List<MyMessage> _messageItems = [
    MyMessage(
        1,
        3,
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
        DateTime.now().add(Duration(days: -1)),
        28827),
    MyMessage(
        2,
        3,
        'Sed ut perspiciatis, unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam eaque ipsa.',
        DateTime.now().add(Duration(minutes: -15)),
        2710),
    MyMessage(
        3,
        3,
        "Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? Quis autem vel eum iure reprehenderit, qui in ea voluptate velit esse, quam nihil molestiae consequatur, vel illum, qui dolorem eum fugiat, quo voluptas nulla pariatur?",
        DateTime.now().add(Duration(minutes: -5)),
        28827),
    MyMessage(
        4,
        3,
        'At vero eos et accusamus et iusto odio dignissimos ducimus, qui blanditiis praesentium voluptatum deleniti atque corrupti, quos dolores et quas molestias excepturi sint, obcaecati cupiditate non provident, similique sunt in culpa, qui officia deserunt mollitia animi, id est laborum et dolorum fuga.',
        DateTime.now(),
        2710),
  ];

  List<Chat> _chatItems = [
    Chat(1, 'Группа 1', [2710, 28827], 2),
    Chat(2, 'Группа 2', [2710, 28827], 2),
    Chat(3, null, [2710, 28827], 1),
  ];

  Future<List<MyChat>> getChatsAndMessageForTimer(int userId) async {
    String keyDate = 'chatDate';
    dynamic lastDate = (await getLastUpdate(keyDate));
    print('Получаем новые чаты за ${lastDate ?? null}');
    List<Chat> chatItems = [];
    List<MyChat> myChatItems = [];

    try {
      //загружаем с одоо в бд все новые чаты
      //ChatController.select(userId, lastDate)

      print('Получаем новые сообщения за ${lastDate ?? null}');
      try {
        //загружаем с одоо в бд все новые сообщения
        // MessageController.select(userId, lastDate)

      } catch (e) {
        print('getMessages error: e');
      }

      setLastUpdate(keyDate);

      //получаем из базы все чаты (без учета времени)

      _chatItems.forEach((chat) {
        chatItems.add(Chat(chat.id, chat.name, chat.reciverUserIds, chat.type));
      });
      chatItems = chatItems ?? [];

      for (var i = 0; i < chatItems.length; i++) {
        MyChat item = MyChat(chatItems[i]);

        int countNew = await getCount(chatItems[i].id, lastDate, userId);
        item.countMessage = countNew;
        myChatItems.add(item);
      }
    } catch (e) {
      print('getChats error: e');
    }

    return myChatItems;
  }

  Future<int> getCount(int chatId, DateTime lastDate, int userId) async {
    //считаем количество новых чужих сообщений в каждом чате  (с учетом времени)
    //select chatItems[i].id + > lastDate || lastDate is NULL  + userId
    //из БД

    List<MyMessage> messageItems = [];

    //todo delete
    try {
      messageItems = _messageItems.where((msg) {
        return (msg.parent_id == chatId &&
            msg.userId != userId &&
            (lastDate == null || msg.dt.isAfter(lastDate)));
      }).toList();
      //todo delete
      messageItems = messageItems ?? [];
    } catch (e) {
      print(e);
    }

    return messageItems.length;
  }

  Future<Map<String, dynamic>> addMessage(MyMessage msg) async {
    Map<String, dynamic> result;
    int id = _messageItems.length + 1;
    msg.id = id;
    _messageItems.add(msg);//todo добавлять в бд и одоо
    result = {'code': 1, 'message': '', 'id': id};//todo delete
    
    return result; 
  }

  Future<Map<String, dynamic>> addChat(Chat chat) async {
    Map<String, dynamic> result;
    int id = _chatItems.length + 1;
    chat.id = id;
    _chatItems.add(chat); //todo добавлять в бд и одоо
     result = {'code': 1, 'message': '', 'id': id}; //todo delete
    return result; 
  }

  Future<List<MyMessage>> getMessages(int chatId, DateTime lastDate) async {
    //получаем все свежие сообщения чата из БД
    //select chatItems[i].id + > lastDate || lastDate is NULL
    List<MyMessage> messageItems = [];

    //todo delete
    messageItems = _messageItems.where((msg) {
      return (msg.parent_id == chatId &&
          (lastDate == null || msg.dt.isAfter(lastDate)));
    }).toList();
    //todo delete
    messageItems = messageItems ?? [];

    return messageItems;
  }

  Future<int> getCountMessage(int userId) async {
    //для счетчика количества новых сообщений
    String keyDate = 'countMessageDate';
    dynamic lastDate = (await getLastUpdate(keyDate));
    int countNew = 1;
    //await MessageController.selectAll(userId, lastDate)

   // var domain = lastDate != null ? ['write_date', '>', lastDate] : [];
    //int countNew =
    //await getDataWithAttemp('mob.chat.msg', 'search_count', domain, {});

    _countMessage += countNew;

    setLastUpdate(keyDate);
    return _countMessage;
  }

  void resetCount() {
    _countMessage = 0;
  }

  Future<dynamic> getLastUpdate(key) async {
    String sLastUpdate = await _storage.read(key: 'messengerDates');
    if (sLastUpdate == null) return null;
    dynamic lastUpdate = json.decode(sLastUpdate);
    if (lastUpdate[key] != null) return DateTime.parse(lastUpdate[key]);
    return null;
  }

  Future<void> setLastUpdate(key) async {
    String sLastUpdate = await _storage.read(key: 'messengerDates');
    Map<String, dynamic> lastUpdate;
    if (sLastUpdate == null)
      lastUpdate = {key: DateTime.now().toString()};
    else {
      lastUpdate = json.decode(sLastUpdate);
      lastUpdate[key] = DateTime.now().toString();
    }

    await _storage.write(key: 'messengerDates', value: json.encode(lastUpdate));
  }
}
