import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';
import 'package:ek_asu_opb_mobile/screens/faultListScreen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import 'package:multi_image_picker/multi_image_picker.dart';

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
  double heightHelp = 550;
  Fault _fault;
  List<Koap> _koapItems;
  int _koapId;
  final formFaultKey = new GlobalKey<FormState>();
  int _selectedKoapId;
  String _fineName;

  File _image;
  int _imageIndex;
  List<File> _imageList = [];
  final _picker = ImagePicker();
  double width;
  double height;
  int quality;

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
      _fineName = '';
      await loadKoap();
      await loadFault();
      await loadImages();
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
        desc: '',
        date: DateTime.now(),
        fine_desc: 'Описание штрафа',
        fine: 1000,
        koap_id: 1);

    if (![null, -1].contains(faultId)) _fault = fault;
    //await FaultController.select(faultId)

    if (_fault != null)
      _fineName = getFineName(_fault.koap_id) ?? '';
    else {
      _fault = _fault ?? new Fault();
      _fineName = '';
    }
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
          firm_stop: 90),
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
          firm_stop: 90),
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
          firm_stop: 90),
    ];

    _koapItems = koapItems;
    //await KoapController.selectAll()

    _koapItems = _koapItems ?? [];
  }

  List<Map<String, dynamic>> choices = [
    {'title': "Сделать фото", 'icon': Icons.camera_alt, 'key': 'camera'},
    {
      'title': 'Выбрать из галереи',
      'icon': Icons.photo_library,
      'key': 'gallery'
    },
  ];

  void _showPhotoMenu() {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject();
    showMenu(
        context: context,
        position: RelativeRect.fromRect(
            _tapPosition & const Size(1, 1), Offset.zero & overlay.size),
        items: <PopupMenuEntry<Map<String, dynamic>>>[
          CustomPopMenu(
            context: context,
            choices: choices,
          )
        ]).then<void>((Map<String, dynamic> choice) {
      if (choice == null) return;
      switch (choice["key"]) {
        case 'camera':
          _onImageButtonPressed(ImageSource.camera);
          break;
        case 'gallery':
          _onImageButtonPressed(ImageSource.gallery);
          break;
      }
    });
  }

  Future<void> loadImages() async {
    _imageList = _imageList ?? [];
    if (faultId == 1) {
      _imageList.insert(0, await loadFileFromAssets("assets/test/1.jpg"));
      _imageList.insert(0, await loadFileFromAssets("assets/test/2.jpg"));
      _imageList.insert(0, await loadFileFromAssets("assets/test/3.jpg"));
      _imageList.insert(0, await loadFileFromAssets("assets/test/4.jpg"));
      _imageList.insert(0, await loadFileFromAssets("assets/test/5.jpg"));
    }
    if (_imageList.length > 0) {
      _image = _imageList[0];
      _imageIndex = 0;
    }
    ;
  }

  String getFineDesc(int koapId) {
    if (koapId == null) return null;
    Koap koapItem =
        _koapItems.firstWhere((koap) => koap.id == koapId, orElse: () => null);
    if (koapItem != null) {
      String fineMan = (koapItem.man_fine_from != null
              ? 'от ${koapItem.man_fine_from.toString()}'
              : '') +
          (koapItem.man_fine_to != null
              ? ' до ${koapItem.man_fine_to.toString()}'
              : '');

      String fineFirm = (koapItem.firm_fine_from != null
              ? 'от ${koapItem.firm_fine_from.toString()}'
              : '') +
          (koapItem.firm_fine_to != null
              ? ' до ${koapItem.firm_fine_to.toString()}'
              : '');

      String stopFirm = (koapItem.firm_stop != null
          ? '. Срок приостановки деятельности ${koapItem.firm_stop.toString()} дней'
          : '');

      return (koapItem.article != null ? 'ст. ${koapItem.article}' : '') +
          (koapItem.paragraph != null ? ' п. ${koapItem.paragraph}' : '') +
          (koapItem.text != null ? ' ${koapItem.text}' : '') +
          (fineMan != '' ? '. Штраф на должностное лицо $fineMan рублей' : '') +
          (fineFirm != ''
              ? '. Штраф на юридическое лицо $fineFirm рублей'
              : '') +
          stopFirm;
    }
    ;
    return null;
  }

  String getFineName(int koapId) {
    if (koapId == null) return null;
    Koap koapItem =
        _koapItems.firstWhere((koap) => koap.id == koapId, orElse: () => null);
    if (koapItem != null)
      return (koapItem.article != null ? 'ст. ${koapItem.article}' : '') +
          (koapItem.paragraph != null ? ' п. ${koapItem.paragraph}' : '');
    return null;
  }

  Future<List<dynamic>> onSearch(String template) async {
    List<Koap> list = _koapItems
        .where((item) =>
            ((item.article ?? '') + (item.paragraph ?? "") + (item.text ?? ""))
                .contains(template))
        .toList();
    // await DepartmentController.select(template, railwayId);
    if (list == null) return null;
    List<dynamic> result = List.generate(list.length, (index) {
      String fineName = getFineName(list[index].id);
      return {
        'id': list[index].id,
        'value':
            '${list[index].text} ' + (fineName != null ? ' ($fineName)' : '')
      };
    });
    return result;
  }

  /* Future getImage() async {
    final pickedFile = await _picker.getImage(source: ImageSource.camera);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        _imageList.insert(0, _image);
        _imageIndex = 0;
      } else {
        print('No image selected.');
      }
    });
  }*/

  Future _onImageButtonPressed(ImageSource source,
      {BuildContext context}) async {
    try {
      final pickedFile = await _picker.getImage(
        source: source,
        maxWidth: width,
        maxHeight: height,
        imageQuality: quality,
      );
      setState(() {
        if (pickedFile != null) {
          _image = File(pickedFile.path);
          _imageList.insert(0, _image);
          _imageIndex = 0;
        } else {
          print('No image selected.');
        }
      });
    } catch (e) {}
  }

  Future<Koap> showSearchKoap() async {
    //  Koap sourceKoap = _koapItems.firstWhere((koap) => koap.id == _fault.koap_id,
    //    orElse: () => null);

    return showDialog<Koap>(
        context: context,
        barrierDismissible: true,
        barrierColor: Color(0x88E6E6E6),
        builder: (context) {
          return StatefulBuilder(builder: (context, StateSetter setState) {
            return Stack(
                alignment: Alignment.center,
                key: Key('KoaptList'),
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
                      height: heightCheckList,
                      width: widthCheckList,
                      child: Scaffold(
                          backgroundColor: Colors.transparent,
                          body: Form(
                              child: SingleChildScrollView(
                                  child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                SearchBox(
                                  (newValue) => setState(
                                      () => _selectedKoapId = newValue),
                                  (template) {
                                    return onSearch(template);
                                  },
                                  context,
                                  text: 'Выбрать статью КОАП',
                                  width: widthCheckList - 50,
                                  height: heightCheckList - 100,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MyButton(
                                        text: 'принять',
                                        parentContext: context,
                                        onPress: () async {
                                          Koap selecteKoap =
                                              _koapItems.firstWhere(
                                                  (koap) =>
                                                      koap.id ==
                                                      _selectedKoapId,
                                                  orElse: () => null);

                                          Navigator.pop<Koap>(
                                              context, selecteKoap);
                                        }),
                                    MyButton(
                                        text: 'отменить',
                                        parentContext: context,
                                        onPress: () {
                                          Navigator.pop<Koap>(context, null);
                                        }),
                                  ],
                                )
                              ])
                                  //Navigator.pop<bool>(context, result);
                                  ))))
                ]);
          });
        });
  }

  showToolTip() {
    //   if (_fault.koap_id == null) return;
    Koap sourceKoap = _koapItems.firstWhere((koap) => koap.id == _fault.koap_id,
        orElse: () => null);
    if (_fault.koap_id == null || sourceKoap == null) return;
    TextStyle style = TextStyle(
        color: Theme.of(context).buttonColor,
        fontSize: 16,
        fontWeight: FontWeight.w600);
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
                      height: heightHelp,
                      width: widthHelp,
                    ),
                  ),
                  Container(
                      height: heightHelp,
                      width: widthHelp,
                      child: Scaffold(
                          backgroundColor: Colors.transparent,
                          body: Form(
                              child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 40.0, vertical: 30.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                              child: FormTitle(
                                                  getFineName(_fault.koap_id)))
                                        ],
                                      ),
                                      Container(
                                        margin:
                                            EdgeInsets.symmetric(vertical: 10),
                                        child: EditTextField(
                                          text: 'Описание статьи',
                                          value: sourceKoap.text,
                                          context: context,
                                          borderColor: Theme.of(context)
                                              .primaryColorLight,
                                          readOnly: true,
                                          backgroundColor: Theme.of(context)
                                              .primaryColorLight,
                                          height: 140,
                                          maxLines: 7,
                                          margin: 0,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            margin: EdgeInsets.only(top: 10),
                                            child: Text(
                                              'Штраф на должностное лицо, руб',
                                              style: style,
                                            ),
                                          )
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              margin:
                                                  EdgeInsets.only(right: 10),
                                              child: EditTextField(
                                                text: 'От',
                                                value: sourceKoap.man_fine_from,
                                                context: context,
                                                borderColor: Theme.of(context)
                                                    .primaryColorLight,
                                                readOnly: true,
                                                backgroundColor:
                                                    Theme.of(context)
                                                        .primaryColorLight,
                                                margin: 0,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Container(
                                              margin: EdgeInsets.only(left: 10),
                                              child: EditTextField(
                                                text: 'До',
                                                value: sourceKoap.man_fine_to,
                                                context: context,
                                                borderColor: Theme.of(context)
                                                    .primaryColorLight,
                                                readOnly: true,
                                                backgroundColor:
                                                    Theme.of(context)
                                                        .primaryColorLight,
                                                margin: 0,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            margin: EdgeInsets.only(top: 20),
                                            child: Text(
                                              'Штраф на юридическое лицо, руб',
                                              style: style,
                                            ),
                                          )
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              margin:
                                                  EdgeInsets.only(right: 10),
                                              child: EditTextField(
                                                text: 'От',
                                                value:
                                                    sourceKoap.firm_fine_from,
                                                context: context,
                                                borderColor: Theme.of(context)
                                                    .primaryColorLight,
                                                readOnly: true,
                                                backgroundColor:
                                                    Theme.of(context)
                                                        .primaryColorLight,
                                                margin: 0,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Container(
                                              margin: EdgeInsets.only(left: 10),
                                              child: EditTextField(
                                                text: 'До',
                                                value: sourceKoap.firm_fine_to,
                                                context: context,
                                                borderColor: Theme.of(context)
                                                    .primaryColorLight,
                                                readOnly: true,
                                                backgroundColor:
                                                    Theme.of(context)
                                                        .primaryColorLight,
                                                margin: 0,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            child: Container(
                                              margin: EdgeInsets.only(
                                                  right: 10, top: 20),
                                              child: EditTextField(
                                                text:
                                                    'Срок приостановки деятельности, дней',
                                                value: sourceKoap.firm_stop,
                                                context: context,
                                                borderColor: Theme.of(context)
                                                    .primaryColorLight,
                                                readOnly: true,
                                                backgroundColor:
                                                    Theme.of(context)
                                                        .primaryColorLight,
                                                margin: 0,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                              child: Container(
                                            margin: EdgeInsets.only(left: 140),
                                            child: MyButton(
                                                text: 'Закрыть',
                                                parentContext: context,
                                                onPress: () {
                                                  Navigator.pop(context, true);
                                                }),
                                          )),
                                        ],
                                      ),
                                    ],
                                  )))))
                ]);
          });
        });
  }

  submitFault() {
    widget.pop();
  }

  Future<void> deleteImage(int index) async {
    bool result = await showConfirmDialog(
        'Вы уверены, что хотите удалить фото?', context);
    if (result != null && result) {
      bool hasErorr = false;
      Map<String, dynamic> result;
      try {
        //  result = await ComGroupController.delete(groupId);
        //  hasErorr = result["code"] < 0;

        //  if (hasErorr) {
        //    Scaffold.of(context).showSnackBar(
        //        errorSnackBar(text: 'Произошла ошибка при удалении'));
        //   return;
        //   }
        _imageList.removeAt(index);
        if (index <= _imageIndex && _imageIndex != 0) _imageIndex--;

        if (_imageList.length > 0)
          _image = _imageList[_imageIndex];
        else
          _image = null;

        setState(() {});
      } catch (e) {
        Scaffold.of(context)
            .showSnackBar(errorSnackBar(text: 'Произошла ошибка при удалении'));
      }
    }
  }

  void _storePosition(TapDownDetails details) {
    _tapPosition = details.globalPosition;
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
                      child: SingleChildScrollView(
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
                                              color: Theme.of(context)
                                                  .primaryColor),
                                          onTap: () => showToolTip(),
                                        ),
                                      )
                                    ]),
                                    Container(
                                      margin: EdgeInsets.only(bottom: 20),
                                      height: 45,
                                      decoration: new BoxDecoration(
                                        border: Border.all(
                                            color: Theme.of(context)
                                                .primaryColorDark,
                                            width: 1.5),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(12)),
                                        color: Colors.white,
                                      ),
                                      padding: EdgeInsets.all(0),
                                      child: TextFormField(
                                        readOnly: true,
                                        controller:
                                            TextEditingController.fromValue(
                                                TextEditingValue(
                                                    text: _fineName ?? "")),
                                        // initialValue: _fineName ?? "",
                                        decoration: new InputDecoration(
                                          suffixIcon: Icon(Icons.description,
                                              color: Theme.of(context)
                                                  .primaryColor),
                                          border: OutlineInputBorder(
                                              borderSide: BorderSide.none),
                                        ),
                                        maxLines: 1,
                                        cursorColor:
                                            Theme.of(context).cursorColor,
                                        onTap: () =>
                                            showSearchKoap().then((Koap koap) {
                                          if (koap == null) return;
                                          _fault.koap_id = koap.id ?? null;
                                          _fineName = getFineName(koap.id);
                                          _fault.fine_desc =
                                              getFineDesc(koap.id);
                                          setState(() {});
                                        }),
                                      ),
                                    ),
                                    Container(
                                      margin:
                                          EdgeInsets.symmetric(vertical: 20),
                                      child: EditTextField(
                                        text: 'Наименование',
                                        value: _fault.name,
                                        onSaved: (value) =>
                                            {_fault.name = value},
                                        context: context,
                                        borderColor:
                                            Theme.of(context).primaryColorDark,
                                        height: 40,
                                        margin: 0,
                                      ),
                                    ),
                                    Container(
                                      margin:
                                          EdgeInsets.symmetric(vertical: 20),
                                      child: EditTextField(
                                        text: 'Описание штрафа',
                                        value: _fault.fine_desc,
                                        onSaved: (value) =>
                                            {_fault.fine_desc = value},
                                        context: context,
                                        borderColor:
                                            Theme.of(context).primaryColorDark,
                                        height: 180,
                                        maxLines: 9,
                                        margin: 0,
                                      ),
                                    ),
                                    Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Expanded(
                                              flex: 2,
                                              child: Container(
                                                margin: EdgeInsets.only(
                                                    top: 10,
                                                    right: 20,
                                                    bottom: 5),
                                                child: EditTextField(
                                                  text:
                                                      'Сумма итогового штрафа, руб',
                                                  value: _fault.fine != null
                                                      ? _fault.fine.toString()
                                                      : '',
                                                  onSaved: (value) => {
                                                    _fault.fine =
                                                        int.tryParse(value)
                                                  },
                                                  context: context,
                                                  borderColor: Theme.of(context)
                                                      .primaryColorDark,
                                                  height: 40,
                                                  inputFormatters: <
                                                      TextInputFormatter>[
                                                    FilteringTextInputFormatter
                                                        .digitsOnly
                                                  ], // Only numbers can be entered
                                                  textInputType: TextInputType
                                                      .numberWithOptions(
                                                          decimal: true),
                                                  margin: 0,
                                                ),
                                              )),
                                          Expanded(
                                              flex: 1,
                                              child: Container(
                                                alignment:
                                                    Alignment.bottomCenter,
                                                margin:
                                                    EdgeInsets.only(bottom: 0),
                                                // EdgeInsets.only(top: 20),
                                                child: MyButton(
                                                    text: 'принять',
                                                    parentContext: context,
                                                    onPress: () {
                                                      submitFault();
                                                    }),
                                              ))
                                        ]),
                                  ])))),
                  Expanded(
                      flex: 2,
                      child: Container(
                        padding: EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                                flex: 5,
                                child: Container(
                                    padding: EdgeInsets.only(bottom: 10),
                                    child: _image == null
                                        ? GestureDetector(
                                            child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.add_a_photo,
                                                    color: Theme.of(context)
                                                        .primaryColor,
                                                    size: 150,
                                                  ),
                                                  Text('Добавить фото',
                                                      style: TextStyle(
                                                          color:
                                                              Theme.of(context)
                                                                  .primaryColor,
                                                          fontSize: 20))
                                                ]),
                                            onTapDown: (details) {
                                              _storePosition(details);
                                              _showPhotoMenu();
                                            },
                                          )
                                        : GestureDetector(
                                            onLongPress: () =>
                                                deleteImage(_imageIndex),
                                            child: Image.file(
                                              _image,
                                              fit: BoxFit.fill,
                                            )),
                                    constraints: BoxConstraints.expand())),
                            _imageList.length > 0
                                ? Expanded(
                                    flex: 1,
                                    child: Container(
                                      child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                              children: List.generate(
                                            _imageList.length,
                                            (i) => GestureDetector(
                                              // onLongPress: () => deleteImage(i),
                                              onTap: () => setState(() {
                                                _image = _imageList[i];
                                                _imageIndex = i;
                                              }),
                                              child: Container(
                                                  constraints:
                                                      BoxConstraints.tight(
                                                          Size(95, 80)),
                                                  padding: i == 0
                                                      ? EdgeInsets.only(
                                                          right: 5)
                                                      : i ==
                                                              _imageList
                                                                      .length -
                                                                  1
                                                          ? EdgeInsets.only(
                                                              left: 5)
                                                          : EdgeInsets
                                                              .symmetric(
                                                                  horizontal:
                                                                      5),
                                                  child: Image.file(
                                                    _imageList[i],
                                                    fit: BoxFit.cover,
                                                  )),
                                            ),
                                          ))),
                                      constraints: BoxConstraints.expand(),
                                    ))
                                : Text(''),
                          ],
                        ),
                      )),
                  Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          GestureDetector(
                            child: Container(
                              padding: EdgeInsets.only(left: 20),
                              height: 25,
                              child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo,
                                        size: 30,
                                        color: Theme.of(context).primaryColor),
                                    Padding(
                                        padding: EdgeInsets.only(left: 10),
                                        child: Text('Добавить фото',
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .primaryColor))),
                                  ]),
                            ),
                            onTapDown: (details) {
                              _storePosition(details);
                              _showPhotoMenu();
                            },
                          ),
                          Expanded(
                              child: SingleChildScrollView(
                                  child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                              margin: EdgeInsets.symmetric(vertical: 10),
                              child: EditTextField(
                                text: 'Описание нарушения',
                                value: _fault.desc,
                                onSaved: (value) => {_fault.desc = value},
                                context: context,
                                borderColor: Theme.of(context).primaryColorDark,
                                height: 470,
                                maxLines: 23,
                                margin: 0,
                              ),
                            ),
                          )))
                        ],
                      )),
                ],
              ))
            ]));
  }
}
