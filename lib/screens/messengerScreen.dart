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
import 'package:flutter/services.dart';

final _storage = FlutterSecureStorage();

class MessengerScreen extends StatefulWidget {
  BuildContext context;
  bool stop;

  @override
  MessengerScreen({this.context, this.stop}) {
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
  List<ChatMessage> _messageItems;
  String _msg;
  bool _stop;
  ScrollController _controller;
  TextEditingController _textController;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final formMsgKey = new GlobalKey<FormState>();

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
    _textController = new TextEditingController();

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


      _chatItems = chatItems ?? [];

      List<MyChat> personalChats =
          chatItems.where((chat) => chat.item.type == 1).toList();

      await Future.forEach(personalChats, (personalChat) async {
        var users = await personalChat.item.users;
        await Future.forEach(users, (User reciverUser) async {
          if (reciverUser.id != _myUid) {
            personalChat.name = reciverUser.display_name;
            _myReciver.add(reciverUser.id);
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

  void hideKeyboard() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  void sendMessage() async {
    final form = formMsgKey.currentState;
    hideKeyboard();
    if (form.validate()) {
      form.save();

      if (_msg != null && _msg.length > 0) {
        //Пытаемся сохранить, если успех - добавляем ?
        ChatMessage msg = ChatMessage(
            id: null,
            odooId: null,
            parentId: _selectedChat.item.id,
            message: _msg,
            createDate: DateTime.now(),
            userId: _myUid);
        bool hasErorr = false;

        try {
          Map<String, dynamic> result =
              await Messenger.messenger.addMessage(msg);
          hasErorr = result["code"] < 0;

          if (hasErorr) {
            _scaffoldKey.currentState.showSnackBar(
                errorSnackBar(text: 'Произошла ошибка при отправке сообщения'));
            return;
          }
          msg.id = result["id"];

          setState(() {
            _messageItems.add(msg);
            _msg = '';
            _textController.text = '';
          });
        } catch (e) {
          _scaffoldKey.currentState.showSnackBar(errorSnackBar(
              text: 'Произошла ошибка при при отправке сообщения'));
        }
      }
    }
  }

  addChat(User reciver) async {
    Chat chat = Chat(id: null, odooId: null, groupId: null, type: 1);

    bool hasErorr = false;

    try {
      Map<String, dynamic> result =
          await Messenger.messenger.addChat(chat, [_myUid, reciver.id]);
      hasErorr = result["code"] < 0;

      if (hasErorr) {
        _scaffoldKey.currentState.showSnackBar(
            errorSnackBar(text: 'Произошла ошибка при добавлении нового чата'));
        return;
      }
      chat.id = result["id"];
      String name = reciver.display_name;
      MyChat newChat = MyChat(chat, name);
      _chatItems.add(newChat);
      // _selectedChat.dtLastLoadMessage = null;
      _selectedChat = newChat;
      _availableUser.removeWhere((user) => user.id == reciver.id);
      _messageItems = [];
      setState(() {});
    } catch (e) {
      _scaffoldKey.currentState.showSnackBar(
          errorSnackBar(text: 'Произошла ошибка при добавлении нового чата'));
    }
  }

  Future<void> onChatTap(int chatId) async {
    bool allMsg = _selectedChat != null && _selectedChat.item.id != chatId;
    //_selectedChat.dtLastLoadMessage = null;

    MyChat selectedChat = _chatItems
        .firstWhere((chat) => chat.item.id == chatId, orElse: () => null);
    if (selectedChat == null) return;
    selectedChat.countMessage = 0;

    _selectedChat = selectedChat;
    setState(() {});
    await getMessagesForChat(_selectedChat, allMsg);
  }

  Future<void> getMessagesForChat(MyChat selectedChat, bool allMsg) async {
    if (selectedChat == null) return;
  

    try {
      DateTime lastReadMessage =
          await Messenger.messenger.getLastReadDate(selectedChat.item);
          
      List<ChatMessage> newMessageItems =
          await Messenger.messenger.getMessages(selectedChat.item, allMsg);

     
      if (allMsg)
        _messageItems = [];
      else {
        //now;
        _messageItems.removeWhere((oldMessage) {
          if (lastReadMessage == null || oldMessage.createDate == null)
            return true;
          if (oldMessage.createDate.isAfter(lastReadMessage)) return true;
          return false;
        });
      }
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
              _messageItems[i].message,
              _messageItems[i].createDate,
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
                                            _chatItems[i].name ?? "",
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
                                                      constraints:
                                                          BoxConstraints(
                                                              maxHeight: 150),
                                                      child:
                                                          SingleChildScrollView(
                                                              scrollDirection:
                                                                  Axis.vertical,
                                                              child: Form(
                                                                key: formMsgKey,
                                                                child:
                                                                    TextFormField(
                                                                  // readOnly:
                                                                  //     true,

                                                                  // controller:
                                                                  //     TextEditingController.fromValue(TextEditingValue(text: _msg != null ? _msg.toString() : "")),
                                                                  decoration: new InputDecoration(
                                                                      hintText:
                                                                          'Введите сообщение...',
                                                                      border: OutlineInputBorder(
                                                                          borderSide: BorderSide
                                                                              .none),
                                                                      contentPadding:
                                                                          EdgeInsets.all(
                                                                              5.0)),

                                                                  maxLines:
                                                                      null,
                                                                  // initialValue:
                                                                  //     _msg ??
                                                                  //         '',
                                                                  controller:
                                                                      _textController,
                                                                  onSaved:
                                                                      (val) =>
                                                                          _msg =
                                                                              val,

                                                                  // maxLength: 256,
                                                                ),
                                                              )))),
                                              Container(
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
                                                    onPressed: sendMessage,
                                                    color: Theme.of(context)
                                                        .primaryColorLight,
                                                  ))
                                            ])))
                                ]),
                              )),
                        ],
                      ) //getBodyContent(),
                )));
  }
}
