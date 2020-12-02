import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ek_asu_opb_mobile/models/chat.dart';
import 'package:ek_asu_opb_mobile/models/chatMessage.dart';
import 'package:ek_asu_opb_mobile/controllers/chat.dart';
import 'package:ek_asu_opb_mobile/controllers/chatMessage.dart';

final _storage = FlutterSecureStorage();

class MyChat {
  Chat item;
  String name;
  int countMessage;
  DateTime dtLastLoadMessage;

  MyChat(this.item, this.name, {this.countMessage = 0, this.dtLastLoadMessage});
}

/*class MyMessage {
  int id;
  int parent_id; //ссылка на чат
  int userId;
  String msg;
  DateTime dt;
  MyMessage(this.id, this.parent_id, this.msg, this.dt, this.userId);
}*/

class Messenger {
  Messenger._();
  static final Messenger messenger = Messenger._();
  int _countMessage = 0;

  /* List<MyMessage> _messageItems = [];
 List<Chat> _chatItems = [];
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
  ];*/

  Future<List<MyChat>> getChatsAndMessageForTimer(int userId) async {
    List<Chat> chatItems = [];
    List<MyChat> myChatItems = [];

    try {
      //загружаем с одоо в бд все новые чаты
      await ChatController.loadFromOdoo();
    } catch (e) {
      print('get new Chats from odoo error: $e');
    }

    try {
      //загружаем с одоо в бд все новые сообщения
      await ChatMessageController.loadFromOdoo();
    } catch (e) {
      print('get new Messages from odoo error: $e');
    }

    //получаем из базы все чаты (без учета времени)

    try {
      chatItems = await ChatController.select();
    } catch (e) {
      print('get chat from DB error: $e');
    }

    chatItems = chatItems ?? [];

    for (var i = 0; i < chatItems.length; i++) {
      try {
        String name;
        if (chatItems[i].groupId != null)
          name = (await chatItems[i].group).groupNum;

        MyChat item = MyChat(chatItems[i], name);

        int countNew = await chatItems[i].getNewMessagesCount(userId);
        item.countMessage = countNew;
        myChatItems.add(item);
      } catch (e) {
        print('get count for chat id  error: $e');
      }
    }

    return myChatItems;
  }

  Future<Map<String, dynamic>> addMessage(ChatMessage msg) async {
    try {
      return await ChatMessageController.insert(msg);
    } catch (e) {
      print('error add message: $e');
    }
  }

  Future<Map<String, dynamic>> addChat(Chat chat, List<int> users) async {
    try {
      return await ChatController.insert(chat, users);
    } catch (e) {
      print('error add chat: $e');
    }
  }

  Future<List<ChatMessage>> getMessages(
      MyChat selectedChat, bool allMsg, int userId) async {
    //получаем все свежие сообщения чата из БД
    //select chatItems[i].id + > lastDate || lastDate is NULL
    List<ChatMessage> messageItems = [];

    try {
      messageItems = await ChatMessageController.newMessagesFromDate(
          selectedChat.item,
          userId,
          allMsg ? null : selectedChat.dtLastLoadMessage);
    } catch (e) {
      print('getMessages from db error $e');
    }
    messageItems = messageItems ?? [];
    return messageItems;
  }

  Future<int> getCountMessage(int userId) async {
    int countNew = 0;
    try {
      await ChatController.loadFromOdoo();
      List<Chat> chatItems = await ChatController.select();
      chatItems = chatItems ?? [];
      Future.forEach(chatItems, (Chat chat) async {
        countNew += await chat.newMessagesFromOdooCount ?? 0;
      });
    } catch (e) {
      print('Error get total count messages from odoo: $e');
    }

    // var domain = lastDate != null ? ['write_date', '>', lastDate] : [];
    //int countNew =
    //await getDataWithAttemp('mob.chat.msg', 'search_count', domain, {});

    _countMessage += countNew;

    return _countMessage;
  }

  void resetCount() {
    _countMessage = 0;
  }
}
