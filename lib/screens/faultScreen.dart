import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';
import 'package:ek_asu_opb_mobile/screens/faultListScreen.dart';

class Koap {
  int id;
  String article; //Статья
  String paragraph; // Пункт // Параграф
  String text; //Описание
  int man_fine_from; //Штраф на должностное лицо. От
  int man_fine_to; //Штраф на должностное лицо. До
  int firm_fine_from; //Штраф на юридическое  лицо. От
  int firm_fine_to; //Штраф на юридическое  лицо. До
  int firm_stop; //Срок приостановки деятельности, дней
  int desc; //Дополнительное описание

  Koap(
      {this.id,
      this.article,
      this.paragraph,
      this.text,
      this.man_fine_from,
      this.man_fine_to,
      this.firm_fine_from,
      this.firm_fine_to,
      this.firm_stop,
      this.desc});
}

class FaultScreen extends StatefulWidget {
  int faultId;
  Function(Map<String, String>, dynamic arg) push;
  Map<String, String> Function() pop;

  @override
  FaultScreen(this.faultId, this.push, this.pop);
  @override
  State<FaultScreen> createState() => _FaultScreen();
}

class _FaultScreen extends State<FaultScreen> {
  UserInfo _userInfo;
  bool showLoading = true;
  var _tapPosition;
  int faultId;
  double heightCheckList = 700;
  double widthCheckList = 1000;
  double widthHelp = 700;
  Fault _fault;
  List<Koap> _koapItems;
  int _koapId;
  final formFaultKey = new GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    auth.checkLoginStatus(context).then((isLogin) {
      if (isLogin) {
        auth.getUserInfo().then((userInfo) {
          _userInfo = userInfo;
          faultId = widget.faultId;
          loadData();
        });
      } //isLogin == true
    }); //checkLoginStatus
  }

  Future<void> loadData() async {
    try {
      showLoadingDialog(context);
      setState(() => {showLoading = true});
      await loadFault();
      await loadKoap();
    } catch (e) {} finally {
      hideDialog(context);
      showLoading = false;
      setState(() => {});
    }
  }

  Future<void> loadFault() async {
    Fault fault = Fault(
        id: 1,
        odooId: 1,
        name: 'Разлив',
        desc: 'Описание нарушения',
        date: DateTime.now(),
        fine_desc: 'Описание штрафа',
        // fine: 1000,
        koap_id: 1);
    _fault = fault;
    //await FaultController.select(faultId)

    _fault = _fault ?? [];
  }

  Future<void> loadKoap() async {
    List<Koap> koapItems = [
      Koap(
          id: 1,
          article: '6.3.',
          paragraph: '1',
          text:
              'Нарушение законодательства в области обеспечения санитарно-эпидемиологического благополучия населения, выразившееся в нарушении действующих санитарных правил и гигиенических нормативов, невыполнении санитарно-гигиенических и противоэпидемических мероприятий',
          man_fine_from: 500,
          man_fine_to: 1000,
          firm_fine_from: 10000,
          firm_fine_to: 20000,
          desc: 90),
      Koap(
          id: 2,
          article: '6.3.',
          paragraph: '2',
          text:
              'Те же действия (бездействие), совершенные в период режима чрезвычайной ситуации или при возникновении угрозы распространения заболевания, представляющего опасность для окружающих, либо в период осуществления на соответствующей территории ограничительных мероприятий (карантина), либо невыполнение в установленный срок выданного в указанные периоды законного предписания (постановления) или требования органа (должностного лица), осуществляющего федеральный государственный санитарно-эпидемиологический надзор, о проведении санитарно-противоэпидемических (профилактических) мероприятий',
          man_fine_from: 50000,
          man_fine_to: 50000,
          firm_fine_from: 200000,
          firm_fine_to: 500000,
          desc: 90),
      Koap(
          id: 3,
          article: '6.3.',
          paragraph: '3',
          text:
              'Действия (бездействие), предусмотренные частью 2 настоящей статьи, повлекшие причинение вреда здоровью человека или смерть человека, если эти действия (бездействие) не содержат уголовно наказуемого деяния',
          man_fine_from: 300000,
          man_fine_to: 500000,
          firm_fine_from: 500000,
          firm_fine_to: 1000000,
          desc: 90),
    ];

    _koapItems = koapItems;
    //await KoapController.selectAll()

    _fault = _fault ?? [];
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
  showToolTip() {
    // if (_koapId = null) return;
    return showDialog<bool>(
        context: context,
        barrierDismissible: true,
        barrierColor: Color(0x88E6E6E6),
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, StateSetter setState) {
            return Stack(alignment: Alignment.center, key: Key('FaultList'),

                //     'checkList${_currentCheckList.items != null ? _currentCheckList.items.length : '0'}'),
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      "assets/images/app.jpg",
                      fit: BoxFit.fill,
                      height: 500,
                      width: widthHelp,
                    ),
                  ),
                  Container(
                      height: 500,
                      width: widthHelp,
                      child: Scaffold(
                          backgroundColor: Colors.transparent,
                          body: Form(
                              child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 30.0, vertical: 20.0),
                                  child: Text('Ясно, понятно')))))
                ]);
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return showLoading
        ? Text("")
        : Padding(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 50),
            child: Column(children: [
              Expanded(
                  child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      flex: 2,
                      child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Row(children: [
                                  FormTitle("Нарушение"),
                                  Container(
                                    padding: EdgeInsets.only(left: 20),
                                    child: GestureDetector(
                                      child: Icon(Icons.help_outline,
                                          size: 35,
                                          color:
                                              Theme.of(context).primaryColor),
                                      onTap: () => showToolTip(),
                                    ),
                                  )
                                ]),
                                Container(
                                  margin: EdgeInsets.only(bottom: 10),
                                  height: 45,
                                  decoration: new BoxDecoration(
                                    border: Border.all(
                                        color:
                                            Theme.of(context).primaryColorDark,
                                        width: 1.5),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(12)),
                                    color: Colors.white,
                                  ),
                                  padding: EdgeInsets.all(0),
                                  child: TextFormField(
                                    decoration: new InputDecoration(
                                      suffixIcon: Icon(Icons.description,
                                          color:
                                              Theme.of(context).primaryColor),
                                      border: OutlineInputBorder(
                                          borderSide: BorderSide.none),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    maxLines: 1,
                                    cursorColor: Theme.of(context).cursorColor,
                                    onSaved: (val) => null, //_email = val,
                                    onTap: () => null,
                                  ),
                                ),
                                Container(
                                  margin: EdgeInsets.symmetric(vertical: 20),
                                  child: EditTextField(
                                    text: 'Наименование',
                                    value: _fault.name,
                                    onSaved: (value) => {_fault.name = value},
                                    context: context,
                                    borderColor:
                                        Theme.of(context).primaryColorDark,
                                    height: 40,
                                    margin: 0,
                                  ),
                                ),
                                Container(
                                  margin: EdgeInsets.symmetric(vertical: 20),
                                  child: EditTextField(
                                    text: 'Описание штрафа',
                                    value: _fault.fine_desc,
                                    onSaved: (value) =>
                                        {_fault.fine_desc = value},
                                    context: context,
                                    borderColor:
                                        Theme.of(context).primaryColorDark,
                                    height: 140,
                                    maxLines: 7,
                                    margin: 0,
                                  ),
                                ),
                                Container(
                                  margin: EdgeInsets.symmetric(vertical: 20),
                                  child: EditTextField(
                                    text: 'Сумма итогового штрафа',
                                    value: _fault.fine != null
                                        ? _fault.fine.toString()
                                        : '',
                                    onSaved: (value) =>
                                        {_fault.fine = int.tryParse(value)},
                                    context: context,
                                    borderColor:
                                        Theme.of(context).primaryColorDark,
                                    height: 40,
                                    inputFormatters: <TextInputFormatter>[
                                      FilteringTextInputFormatter.digitsOnly
                                    ], // Only numbers can be entered
                                    textInputType:
                                        TextInputType.numberWithOptions(
                                            decimal: true),
                                    margin: 0,
                                  ),
                                ),
                              ]))),
                  Expanded(flex: 2, child: Text('Фото')),
                  Expanded(flex: 1, child: Text('Описание')),
                ],
              ))
            ]));
  }
}
