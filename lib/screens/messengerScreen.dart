import 'dart:async';
import 'dart:convert';
import 'package:ek_asu_opb_mobile/controllers/controllers.dart';
import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';
import 'package:search_widget/search_widget.dart';
import 'package:ek_asu_opb_mobile/utils/config.dart' as config;
import 'package:ek_asu_opb_mobile/src/messenger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final _storage = FlutterSecureStorage();

class MessengerScreen extends StatefulWidget {
  BuildContext context;
  bool stop;

  @override
  MessengerScreen({this.context, this.stop}) {
    Messenger.messenger.resetCount();
    createState();
  }

  @override
  State<MessengerScreen> createState() => _MessengerScreen(stop);
}

class _MessengerScreen extends State<MessengerScreen> {
  UserInfo _userInfo;
  bool showLoading;
  List<MyChat> _chatItems;
  List<int> _myReciver;
  List<User> _availableUser;
  List<User> allUsers;
  int _myUid;
  Timer _messengerTimer;
  int refreshMessenger;
  Duration seconds;
  MyChat _selectedChat;
  List<MyMessage> _messageItems;
  String _msg;
  bool _stop;
  ScrollController _controller;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  _MessengerScreen(bool stop) {
    _stop = stop;
  }
  void hideLoading() {
    setState(() {
      showLoading = false;
      hideDialog(context);
    });
  }

  void cancelTimer() {
    if (_messengerTimer != null) {
      _messengerTimer.cancel();
      _messengerTimer = null;
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    showLoading = true;
    //  WidgetsFlutterBinding.ensureInitialized();
    _controller = ScrollController();

    auth.checkLoginStatus(context).then((isLogin) {
      if (isLogin) {
        showLoadingDialog(context);
        auth.getUserInfo().then((userInfo) {
          _userInfo = userInfo;
          _myUid = _userInfo.id;
          _chatItems = [];
          _myReciver = [];
          _availableUser = [];
          _messageItems = [];

          loadData();
        });
      } //isLogin == true
    }); //checkLoginStatus
  }

  Future<void> loadData() async {
    try {
      allUsers = await UserController.selectAll();
      await _storage.delete(key: 'messengerDates'); //todo delete
    } finally {
      hideLoading();
    }
  }

  Future<void> loadChat() async {
    try {
      List<MyChat> chatItems =
          await Messenger.messenger.getChatsAndMessageForTimer(_myUid);

      if (chatItems != null) {
        chatItems.forEach((newChat) {
          MyChat oldChat = _chatItems.firstWhere(
              (chat) => chat.item.id == newChat.item.id,
              orElse: () => null);
          if (oldChat != null) {
            newChat.countMessage =
                (newChat.countMessage ?? 0) + oldChat.countMessage;
            newChat.dtLastLoadMessage = oldChat.dtLastLoadMessage;
          }
        });
      }

      _chatItems = chatItems ?? [];

      List<MyChat> personalChats =
          chatItems.where((chat) => chat.item.type == 1).toList();

      await Future.forEach(personalChats, (personalChat) async {
        await Future.forEach(personalChat.item.reciverUserIds,
            (reciverId) async {
          if (reciverId != _myUid) {
            personalChat.item.name =
                (await UserController.selectById(reciverId)).display_name;
            _myReciver.add(reciverId);
          }
        });
      });

      for (var i = 0; i < allUsers.length; i++) {
        if (!_myReciver.contains(allUsers[i].id))
          _availableUser.add(allUsers[i]);
      }

      if (_selectedChat != null) await onChatTap(_selectedChat.item.id);
      setState(() {});
    } catch (e) {
      print(e);
    }
  }

  void createTimer() {
    refreshMessenger = refreshMessenger ??
        int.tryParse(config.getItem("refreshMessenger").toString());
    seconds = seconds ??
        new Duration(
            seconds: (refreshMessenger != null ? refreshMessenger : 30));

    _messengerTimer = Timer(seconds, timerTick);
  }

  @override
  void dispose() {
    print('dispose');
    if (_messengerTimer != null) {
      _messengerTimer.cancel();
    }
    super.dispose();
  }

  void timerTick() {
    createTimer();

    if (widget.stop) {
      cancelTimer();
      return;
    }

    print('get new message for user ${_userInfo.id} from messengerScreen');
    loadChat();
  }

  void sendMessage() async {
    //Пытаемся сохранить, если успех - добавляем ?
    MyMessage msg =
        MyMessage(null, _selectedChat.item.id, _msg, DateTime.now(), _myUid);
    bool hasErorr = false;

    try {
      Map<String, dynamic> result = await Messenger.messenger.addMessage(msg);
      hasErorr = result["code"] < 0;

      if (hasErorr) {
        _scaffoldKey.currentState.showSnackBar(
            errorSnackBar(text: 'Произошла ошибка при отправке сообщения'));
        return;
      }
      msg.id = result["id"];
      _msg = '';

      setState(() {
        _messageItems.add(msg);
      });
    } catch (e) {
      _scaffoldKey.currentState.showSnackBar(
          errorSnackBar(text: 'Произошла ошибка при при отправке сообщения'));
    }
  }

  addChat(User reciver) async {
    Chat chat = Chat(null, null, [_myUid, reciver.id], 1);
    bool hasErorr = false;

    try {
      Map<String, dynamic> result = await Messenger.messenger.addChat(chat);
      hasErorr = result["code"] < 0;

      if (hasErorr) {
        _scaffoldKey.currentState.showSnackBar(
            errorSnackBar(text: 'Произошла ошибка при отправке сообщения'));
        return;
      }
      chat.id = result["id"];
      chat.name = (await UserController.selectById(reciver.id)).display_name;
      MyChat newChat = MyChat(chat);
      _chatItems.add(newChat);
      _selectedChat.dtLastLoadMessage = null;
      _selectedChat = newChat;
      _availableUser.removeWhere((user) => user.id == reciver.id);
      _messageItems = [];
      setState(() {});
    } catch (e) {
      _scaffoldKey.currentState.showSnackBar(
          errorSnackBar(text: 'Произошла ошибка при при отправке сообщения'));
    }
  }

  Future<void> onChatTap(int chatId) async {
    if (_selectedChat != null && _selectedChat.item.id != chatId)
      _selectedChat.dtLastLoadMessage = null;

    MyChat selectedChat = _chatItems
        .firstWhere((chat) => chat.item.id == chatId, orElse: () => null);
    selectedChat.countMessage = 0;

    _selectedChat = selectedChat;
    setState(() {});
    await getMessagesForChat(_selectedChat);
  }

  Future<void> getMessagesForChat(MyChat selectedChat) async {
    if (selectedChat == null) return;
    DateTime now = DateTime.now();
    DateTime lastLoadMessage = selectedChat.dtLastLoadMessage;

    try {
      List<MyMessage> newMessageItems = await Messenger.messenger
          .getMessages(selectedChat.item.id, lastLoadMessage);

      _selectedChat.dtLastLoadMessage = now;
      _messageItems.removeWhere((oldMessage) {
        if (lastLoadMessage == null || oldMessage.dt == null) return true;
        if (oldMessage.dt.isAfter(lastLoadMessage)) return true;
        return false;
      });
      _messageItems = _messageItems ?? [];

      setState(() {
        _messageItems.addAll(newMessageItems);
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.stop) {
      if (!showLoading && _messengerTimer == null) {
        cancelTimer();
        timerTick();
      }
    }

    List<Widget> msgs = _messageItems != null && _messageItems.length > 0
        ? List.generate(_messageItems.length, (i) {
            String userName = '';
            if (_myUid != _messageItems[i].userId) {
              User sender = allUsers.firstWhere(
                  (user) => user.id == _messageItems[i].userId,
                  orElse: () => null);
              if (sender != null) userName = sender.display_name;
            }

            return MyMessageContainer(
              _messageItems[i].id,
              userName,
              _messageItems[i].msg,
              _messageItems[i].dt,
              _myUid == _messageItems[i].userId,
            );
          })
        : [Text('')];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_controller.hasClients) return;
      _controller.animateTo(_controller.position.maxScrollExtent,
          duration: Duration(milliseconds: 200), curve: Curves.ease);
    });

    return new Scaffold(
        key: _scaffoldKey,
        appBar: PreferredSize(
            preferredSize: Size.fromHeight(100),
            child: MyAppBar(
                showIsp: true,
                userInfo: _userInfo,
                syncTask: null,
                showMessenger: false)),
        body: Builder(
            builder: (context) => Container(
                child: showLoading
                    ? Text("")
                    : Row(
                        children: [
                          Expanded(
                              flex: 1,
                              child: Container(
                                  color: Theme.of(context).primaryColor,
                                  child: Column(
                                    children: [
                                      SearchWidget<User>(
                                        key: Key(
                                            'userList${_availableUser.length}'),
                                        dataList: _availableUser,
                                        hideSearchBoxWhenItemSelected: false,
                                        listContainerHeight:
                                            MediaQuery.of(context).size.height /
                                                2,
                                        queryBuilder: (query, list) {
                                          return list
                                              .where((item) => item.display_name
                                                  .toLowerCase()
                                                  .contains(
                                                      query.toLowerCase()))
                                              .toList();
                                        },
                                        popupListItemBuilder: (item) {
                                          return PopupListItemWidget(
                                              item.display_name);
                                        },
                                        selectedItemBuilder:
                                            (selectedItem, deleteSelectedItem) {
                                          return Text('');
                                          // return SelectedItemWidget(
                                          //      selectedItem, deleteSelectedItem);
                                        },
                                        // widget customization
                                        noItemsFoundWidget: NoItemsFound(),
                                        textFieldBuilder:
                                            (controller, focusNode) {
                                          return MyTextField(
                                              controller, focusNode,
                                              hintText:
                                                  'Введите ФИО сотрудника');
                                        },
                                        onItemSelected: (item) async {
                                          await addChat(item);
                                          //setState(() {});
                                        },
                                      ),
                                      Expanded(
                                          child: SingleChildScrollView(
                                              child: Column(
                                                  children: List.generate(
                                                      _chatItems.length, (i) {
                                        int id = _chatItems[i].item.id;
                                        return MyChatContainer(
                                            _chatItems[i].item.id,
                                            _chatItems[i].item.name ?? "",
                                            _chatItems[i].countMessage,
                                            _selectedChat != null &&
                                                _chatItems[i].item.id ==
                                                    _selectedChat.item.id,
                                            onChatTap);
                                      }))))
                                    ],
                                  ))),
                          Expanded(
                              flex: 3,
                              child: Container(
                                decoration: BoxDecoration(
                                    image: DecorationImage(
                                        image: AssetImage(
                                            "assets/images/frameScreen.png"),
                                        fit: BoxFit.fill)),
                                child: Column(children: [
                                  Expanded(
                                      child: SingleChildScrollView(
                                    scrollDirection: Axis.vertical,
                                    child: Column(children: msgs),
                                    controller: _controller,
                                  )),
                                  if (_selectedChat != null)
                                  Container(
                                      child: Container(
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Theme.of(context)
                                                      .primaryColorLight,
                                                  width: 1.5),
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(0)),
                                              color: Theme.of(context)
                                                  .primaryColorLight),
                                          child: Row(children: [
                                            Expanded(
                                                child: ConstrainedBox(
                                                    constraints: BoxConstraints(
                                                        maxHeight: 150),
                                                    child:
                                                        SingleChildScrollView(
                                                            scrollDirection:
                                                                Axis.vertical,
                                                            child:
                                                                GestureDetector(
                                                                    onTap: () {
                                                                      showEdit(
                                                                        _msg,
                                                                        'Сообщение',
                                                                        context,
                                                                      ).then((newValue) =>
                                                                          setState(
                                                                              () {
                                                                            _msg =
                                                                                newValue ?? "";
                                                                          }));
                                                                    },
                                                                    child:
                                                                        AbsorbPointer(
                                                                      child:
                                                                          TextField(
                                                                        readOnly:
                                                                            true,

                                                                        controller: TextEditingController.fromValue(TextEditingValue(
                                                                            text: _msg != null
                                                                                ? _msg.toString()
                                                                                : "")),
                                                                        decoration: new InputDecoration(
                                                                            hintText:
                                                                                'Введите сообщение...',
                                                                            border:
                                                                                OutlineInputBorder(borderSide: BorderSide.none),
                                                                            contentPadding: EdgeInsets.all(5.0)),

                                                                        maxLines:
                                                                            null,
                                                                        // maxLength: 256,
                                                                      ),
                                                                    ))))),
                                            _msg != null && _msg.length > 0
                                                ? Container(
                                                    margin: EdgeInsets.all(5),
                                                    height: 40,
                                                    width: 40,
                                                    alignment: Alignment.center,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.all(
                                                              Radius.circular(
                                                                  12)),
                                                      color: Theme.of(context)
                                                          .primaryColor,
                                                    ),
                                                    child: IconButton(
                                                      icon: Icon(Icons.send),
                                                      iconSize: 24,
                                                      onPressed: _msg != null &&
                                                              _msg.length > 0
                                                          ? () => sendMessage()
                                                          : null,
                                                      color: Theme.of(context)
                                                          .primaryColorLight,
                                                    ))
                                                : Text('')
                                          ])))
                                ]),
                              )),
                        ],
                      ) //getBodyContent(),
                )));
  }
}
