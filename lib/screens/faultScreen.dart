import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';

class Fault {
  int id;
  int odooId;
  int parentId; //checkListItem.id
  String name; //Наименование
  String desc; //Описание
  DateTime date; //Дата фиксации
  String fine_desc; //Штраф. Описание
  int fine; //Штраф. Сумма
  int koap_id;
  Fault(
      {this.id,
      this.odooId,
      this.parentId,
      this.name,
      this.desc,
      this.date,
      this.fine,
      this.fine_desc,
      this.koap_id}); //Статья КОАП
}

class FaultScreen extends StatefulWidget {
  int checkListItemId;
  Function(Map<String, String>, dynamic arg) push;
  Map<String, String> Function() pop;

  @override
  FaultScreen(this.checkListItemId, this.push, this.pop);
  @override
  State<FaultScreen> createState() => _FaultScreen();
}

class _FaultScreen extends State<FaultScreen> {
  UserInfo _userInfo;
  bool showLoading = true;
  var _tapPosition;
  double heightCheckList = 700;
  double widthCheckList = 1200;
  final formFaultKey = new GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    auth.checkLoginStatus(context).then((isLogin) {
      if (isLogin) {
        auth.getUserInfo().then((userInfo) {
          _userInfo = userInfo;

          loadData();
        });
      } //isLogin == true
    }); //checkLoginStatus
  }

  Future<void> loadData() async {
    try {
      showLoadingDialog(context);
      setState(() => {showLoading = true});
    } catch (e) {} finally {
      hideDialog(context);
      showLoading = false;
      setState(() => {});
    }
  }

  /*Future<bool> showFaultDialog(StateSetter setState) {
    StateSetter dialogSetter;
    final menu = PopupMenuButton(
      itemBuilder: (_) => getMenuItem(context),
      padding: EdgeInsets.all(0.0),
      onSelected: (value) {
        switch (value) {
          case 'add':
            setState(() {
              if (_currentCheckListItem.faultItems == null)
                _currentCheckListItem.faultItems = [];
              _currentCheckListItem.faultItems.add(Fault(
                  id: null, odooId: null, parentId: _currentCheckListItem.id));
              dialogSetter(() {});
              //refresh = true;
            });
            break;
        }
      },
      icon: Icon(
        Icons.more_vert,
        color: Theme.of(context).primaryColorDark,
        size: 30,
      ),
      color: Theme.of(context).primaryColor,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12.0))),
    );

    return showDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierColor: Color(0x88E6E6E6),
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, StateSetter setState) {
            dialogSetter = setState;
            return Stack(alignment: Alignment.center, key: Key('FaultList'),

                //     'checkList${_currentCheckList.items != null ? _currentCheckList.items.length : '0'}'),
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      "assets/images/app.jpg",
                      fit: BoxFit.fill,
                      height: heightCheckList,
                      width: widthCheckList,
                    ),
                  ),
                  Container(
                      width: widthCheckList,
                      padding: EdgeInsets.symmetric(
                          horizontal: 30.0, vertical: 20.0),
                      child: Scaffold(
                          backgroundColor: Colors.transparent,
                          body: Form(
                              key: formFaultKey,
                              child: Container(
                                  child: Column(children: [
                                ListTile(
                                    trailing: menu,
                                    contentPadding: EdgeInsets.all(0),
                                    title: Center(
                                        child: FormTitle(
                                            'Перечень нарушений к ${_currentCheckListItem.name} ${_currentCheckListItem.question}')),
                                    onTap: () {}),
                                //   Container(child: refresh ? Text('') : Text('')),

                                Expanded(
                                    child: ListView(
                                        key: Key(_currentCheckList.items.length
                                            .toString()),
                                        children: [
                                      Column(children: [
                                        generateFualtTable(
                                            context,
                                            /*itemHeader,*/
                                            _currentCheckListItem.faultItems,
                                            dialogSetter: dialogSetter
                                            // setState: setState
                                            )
                                      ])
                                    ])),
                                Container(
                                    child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                      MyButton(
                                          text: 'принять',
                                          parentContext: context,
                                          onPress: () {
                                            submitFaultList();
                                          }),
                                      MyButton(
                                          text: 'отменить',
                                          parentContext: context,
                                          onPress: () {
                                            cancelCheckList();
                                          }),
                                    ])),
                              ])))))
                ]);
          });
        });
  }

  Widget generateFualtTable(
      BuildContext context,
      /*List<Map<String, dynamic>> headers,*/ List<Fault> rows,
      {/*StateSetter setState,*/ StateSetter dialogSetter}) {
    return Text('Тут будет список нарушений');
  }

  Future<void> submitFaultList() async {
    Navigator.pop<bool>(context, true);
    Scaffold.of(context).showSnackBar(successSnackBar);
  }
*/

  @override
  Widget build(BuildContext context) {
    return showLoading
        ? Text("")
        : Padding(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 40),
            child: Column(
              children: [
              Row(children: [Expanded(child: FormTitle("Нарушение:"))]),
              Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: Text('КОАП')),
                  Expanded(flex: 2, child: Text('Фото')),
                  Expanded(flex: 1, child: Text('Описание')),
                ],
              ))
            ]));
  }
}
