
import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';
import 'package:search_widget/search_widget.dart';

class Chat {
  int id;
  String name;
  List<int> reciverUserIds;
  Chat(this.id, this.name, this.reciverUserIds);
}

class Message {
  int id;
  int parent_id; //ссылка на чат
  String text;
  DateTime dt;
  User sender;
}

class MessengerScreen extends StatefulWidget {
  //BuildContext context;

  //@override
  //MessengerScreen({this.context});

  @override
  State<MessengerScreen> createState() => _MessengerScreen();
}

class _MessengerScreen extends State<MessengerScreen> {
  UserInfo _userInfo;
  bool showLoading = true;
  List<Chat> _chatItems;

  void hideLoading() {
    setState(() {
      showLoading = false;
      hideDialog(context);
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();

    auth.checkLoginStatus(context).then((isLogin) {
      if (isLogin) {
        showLoadingDialog(context);
        auth.getUserInfo().then((userInfo) {
          _userInfo = userInfo;
          loadData();
        });
      } //isLogin == true
    }); //checkLoginStatus
  }

  Future<void> loadData() async {
    try {
      List<Chat> chatItems = [
        /*  Chat(1, 'Группа 1', [1,2,3,4]),
        Chat(2, 'Группа 2'),
        Chat(3, 'Иванов Иван Иванович'),*/
      ];
      //MessengerController.select(_userInfo.id)

    } finally {
      hideLoading();
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: PreferredSize(
            preferredSize: Size.fromHeight(100),
            child: MyAppBar(
                showIsp: true,
                userInfo: _userInfo,
                syncTask: null,
                showMessenger: false)),
        body: Container(
            child: showLoading
                ? Text("")
                : Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Container(
                            color: Theme.of(context).primaryColor,
                            child: Column(children: [
                              SingleChildScrollView(
                                  child: Row(
                                children: [
                                  /* new SearchWidget<User>(
                                    key: Key('userList${userList.length}'),
                                    dataList: userList,
                                    hideSearchBoxWhenItemSelected: false,
                                    listContainerHeight:
                                        MediaQuery.of(context).size.height / 4,
                                    queryBuilder: (query, list) {
                                      return list
                                          .where((item) => item.display_name
                                              .toLowerCase()
                                              .contains(query.toLowerCase()))
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
                                    textFieldBuilder: (controller, focusNode) {
                                      return MyTextField(controller, focusNode,
                                          hintText: 'Введите ФИО сотрудника');
                                    },
                                    onItemSelected: (item) {
                                      _commissionList.add(Member(item));

                                      userList.removeWhere(
                                          (user) => user.id == item.id);
                                      setState(() {
                                        //_selectedItem = item;
                                      });
                                    },
                                  ),*/
                                  Expanded(child: Text('Чаты'))
                                ],
                              ))
                            ])),
                      ),
                      Expanded(
                          flex: 3,
                          child: Container(
                            decoration: BoxDecoration(
                                image: DecorationImage(
                                    image: AssetImage(
                                        "assets/images/frameScreen.png"),
                                    fit: BoxFit.fill)),
                            child: Column(children: [Text('Переписка')]),
                          )),
                    ],
                  ) //getBodyContent(),
            ));
  }
}
