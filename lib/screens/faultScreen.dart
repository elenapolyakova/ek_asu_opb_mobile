import 'package:ek_asu_opb_mobile/controllers/fault.dart';
import 'package:ek_asu_opb_mobile/controllers/faultItem.dart';
import 'package:ek_asu_opb_mobile/controllers/koap.dart';
import 'package:ek_asu_opb_mobile/models/fault.dart';
import 'package:ek_asu_opb_mobile/models/faultItem.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';
import 'dart:io';
import 'package:ek_asu_opb_mobile/src/fileStorage.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'dart:typed_data';
import 'package:ek_asu_opb_mobile/models/koap.dart';
import 'package:ek_asu_opb_mobile/src/GPS.dart';

//import 'package:permission_handler/permission_handler.dart';

class FaultScreen extends StatefulWidget {
  int faultId;
  int checkListItemId;
  Function(Map<String, String>, dynamic arg) push;
  Map<String, String> Function() pop;
  GlobalKey key;

  @override
  FaultScreen(
      this.faultId, this.checkListItemId, this.push, this.pop, this.key);
  @override
  State<FaultScreen> createState() => _FaultScreen();
}

class _FaultScreen extends State<FaultScreen> {
  UserInfo _userInfo;
  bool showLoading = true;
  var _tapPosition;
  int faultId;
  int checkListItemId;
  double heightCheckList = 700;
  double widthCheckList = 1000;
  double widthHelp = 700;
  double heightHelp = 550;
  Fault _fault;
  int _koapId;
  final formFaultKey = new GlobalKey<FormState>();
  int _selectedKoapId;
  String _fineName;
  bool showLoadingImage = false;
  List<String> _deletedPath;
  List<Map<String, dynamic>> _created;

  File _image;
  int _imageIndex;
  List<FaultItem> _imageList = [];

  //List<File> _imageList = [];

  // final _picker = ImagePicker();
  // double width;
  // double height;
  // int quality;

  List<Asset> _assetList = List<Asset>();

  @override
  void initState() {
    super.initState();

    auth.checkLoginStatus(context).then((isLogin) {
      if (isLogin) {
        auth.getUserInfo().then((userInfo) {
          _userInfo = userInfo;
          faultId = widget.faultId;
          checkListItemId = widget.checkListItemId;
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
      _deletedPath = [];
      _created = [];
      await loadFault();
      await loadImages();
    } catch (e) {} finally {
      hideDialog(context);
      showLoading = false;
      setState(() => {});
    }
  }

  Future<void> loadFault() async {
    if (![null, -1].contains(faultId))
      _fault = await FaultController.selectById(faultId);
    if (_fault == null) {
      _fault = new Fault(id: null, parent_id: checkListItemId, active: true);
    }

    if (_fault != null) {
      _fineName = await getFineName(_fault.koap_id);
    } else {
      _fault = _fault ?? new Fault();
      _fineName = '';
    }
  }

  List<Map<String, dynamic>> choices = [
    {'title': "Сделать фото", 'icon': Icons.camera_alt, 'key': 'camera'},
    {
      'title': 'Выбрать из галереи',
      'icon': Icons.photo_library,
      'key': 'gallery'
    },
  ];

  /*void _showPhotoMenu() {
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
          _onGalleryButtonPressed();
          //_onImageButtonPressed(ImageSource.gallery);
          break;
      }
    });
  }*/

  Future<void> loadImages() async {
    _imageList = [];
    _imageList =
        _fault.id != null ? await FaultItemController.select(_fault.id) : [];

    if (_imageList.length > 0) {
      _image = File(_imageList[0].file_data);
      _imageIndex = 0;
    }
  }

  Future<String> getFineDesc(int koapId) async {
    if (koapId == null) return null;
    Koap koapItem = await KoapController.selectById(koapId);
    //   _koapItems.firstWhere((koap) => koap.id == koapId, orElse: () => null);
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
    return null;
  }

  Future<String> getFineName(int koapId) async {
    if (koapId == null) return null;
    Koap koap = await KoapController.selectById(koapId);
    return koap != null ? await koap.fineName : '';
  }

  Future<List<dynamic>> onSearch(String template) async {
    List<Koap> list = await KoapController.select(template);
    /*_koapItems
        .where((item) =>
            ((item.article ?? '') + (item.paragraph ?? "") + (item.text ?? ""))
                .contains(template))
        .toList();*/
    // await DepartmentController.select(template, railwayId);
    if (list == null) return null;
    List<dynamic> result = [];
    for (var i = 0; i < list.length; i++) {
      // = List.generate(list.length, (index) async {
      String fineName = await getFineName(list[i].id);
      result.add({
        'id': list[i].id,
        'value': '${list[i].text} ' + (fineName != null ? ' ($fineName)' : ''),
        'widget':
            MyArticleItem(fineName != null ? ' $fineName  ' : '', list[i].text),
        'widgetSelected': MyArticleItem(
            fineName != null ? ' $fineName  ' : '', list[i].text,
            color: Theme.of(context).primaryColorLight,
            colorTitle: Theme.of(context).primaryColor)
      });
    }
    return result;
  }

  Future<void> _onGalleryButtonPressed({imageCount = 5}) async {
    _assetList = List<Asset>();

    try {
      _assetList = await MultiImagePicker.pickImages(
        maxImages: imageCount,
        enableCamera: true,
        //selectedAssets: images,
        cupertinoOptions: CupertinoOptions(takePhotoIcon: "chat"),
        materialOptions: MaterialOptions(
          actionBarColor: "#465C0B",
          actionBarTitleColor: "#EFF0D7",
          selectCircleStrokeColor: "#ADB439",
          actionBarTitle: "Выберите фото",
          allViewTitle: "Все изображения",
          textOnNothingSelected: 'Не выбрано ни одного изображения',
          startInAllView: true,
          useDetailsView: false,

          // okButtonDrawable: "Принять"
        ),
      );

      if (_assetList != null && _assetList.length > 0) {
        setState(() {
          showLoadingImage = true;
        });
        for (var i = 0; i < _assetList.length; i++) {
          ByteData bytes = await _assetList[i].getByteData();
          String path = await getPath();
          await loadFileFromBytes(bytes, path);
          GeoPoint geoPoint = await Geo.geo.getGeoPoint(path);
          _created.add({
            'path': path,
            'coord_e': geoPoint.longitude,
            'coord_n': geoPoint.latitude
          });

          FaultItem faultItems = FaultItem(
              id: null,
              parent_id: _fault.id,
              file_data: path,
              active: true,
              coord_e: geoPoint.longitude,
              coord_n: geoPoint.latitude);
          _imageList.insert(i, faultItems);
        }
        _image = File(_imageList[0].file_data);
        _imageIndex = 0;
        setState(() {
          showLoadingImage = false;
        });
      }
      /* _assetList = await MultiImagePicker.pickImages(
        maxImages: 300,
      );*/
    } on Exception catch (e) {
      setState(() {
        showLoadingImage = false;
      });
      print(e.toString());
    }
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }

  /*Future _onImageButtonPressed(ImageSource source,
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
  }*/

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
                                          Koap selectedKoap =
                                              await KoapController.selectById(
                                                  _selectedKoapId);
                                          /* _koapItems.firstWhere(
                                                  (koap) =>
                                                      koap.id ==
                                                      _selectedKoapId,
                                                  orElse: () => null);*/

                                          Navigator.pop<Koap>(
                                              context, selectedKoap);
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

  showToolTip() async {
    //   if (_fault.koap_id == null) return;
    Koap sourceKoap = await KoapController.selectById(_fault
        .koap_id); //_koapItems.firstWhere((koap) => koap.id == _fault.koap_id,
    //   orElse: () => null);
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
                                          Expanded(child: FormTitle(
                                              //getFineName(_fault.koap_id))
                                              _fineName ?? ""))
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

  submitFault() async {
    bool hasErorr = false;
    Map<String, dynamic> result;
    _fault.date = DateTime.now().toUtc();
    try {
      if ([-1, null].contains(_fault.id)) {
        result = await FaultController.create(_fault, _created, _deletedPath);
      } else {
        result = await FaultController.update(_fault, _created, _deletedPath);
      }
      hasErorr = result["code"] < 0;

      if (hasErorr) {
        // Navigator.pop<bool>(context, false);

        if (context != null) Scaffold.of(context).showSnackBar(errorSnackBar());
      } else {
        if ([-1, null].contains(_fault.id)) {
          _fault.id = result["id"];
        }

        _created = [];
        _deletedPath = [];
        setState(() {});

        // Navigator.pop<bool>(context, true);
        if (context != null) Scaffold.of(context).showSnackBar(successSnackBar);
      }
    } catch (e) {
      //Navigator.pop<bool>(context, false);
      if (context != null) Scaffold.of(context).showSnackBar(errorSnackBar());
    }
    // widget.pop();
  }

  Future<void> deleteImage(int index) async {
    bool result = await showConfirmDialog(
        'Вы уверены, что хотите удалить фото?', context);
    if (result != null && result) {
      bool hasErorr = false;
      Map<String, dynamic> result;
      FaultItem deletedFile = _imageList[index];

      try {
        //  result = await ComGroupController.delete(groupId);
        //  hasErorr = result["code"] < 0;

        //  if (hasErorr) {
        //    Scaffold.of(context).showSnackBar(
        //        errorSnackBar(text: 'Произошла ошибка при удалении'));
        //   return;
        //   }

        if (deletedFile.id == null) {
          _created
              .removeWhere((image) => image['path'] == deletedFile.file_data);
          //await File(deletedFile.file_data).delete();
        } //если файл добавили, в бд не сохранили и тут же удалили - не передаём его в _createdPath

        _deletedPath.add(deletedFile.file_data);

        _imageList.removeAt(index);
        if (index <= _imageIndex && _imageIndex != 0) _imageIndex--;

        if (_imageList.length > 0)
          _image = File(_imageList[_imageIndex].file_data);
        else
          _image = null;

        setState(() {});
      } catch (e) {
        if (context != null)
          Scaffold.of(context).showSnackBar(
              errorSnackBar(text: 'Произошла ошибка при удалении'));
      }
    }
  }

  void _storePosition(TapDownDetails details) {
    _tapPosition = details.globalPosition;
  }

  Future<void> faultDamageClicked(int faultId) async {
    if ([null, -1].contains(faultId)) return;
    return widget.push({
      "pathTo": 'faultDamage',
      "pathFrom": 'fault',
      'text': 'Назад к нарушению'
    }, {
      'faultId': faultId
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).buttonColor;
    final textStyle = TextStyle(fontSize: 16.0, color: color);

    return showLoading
        ? Text("")
        : Padding(
            padding: EdgeInsets.symmetric(vertical: 5, horizontal: 40),
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
                                      margin: EdgeInsets.only(bottom: 10),
                                      height: 45,
                                      decoration: new BoxDecoration(
                                        border: Border.all(
                                            color: Theme.of(context)
                                                .primaryColorDark,
                                            width: 1.5),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(12)),
                                        color:
                                            Theme.of(context).primaryColorLight,
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
                                        onTap: () => showSearchKoap()
                                            .then((Koap koap) async {
                                          if (koap == null) return;
                                          _fault.koap_id = koap.id ?? null;
                                          _fineName =
                                              await getFineName(koap.id);
                                          _fault.fine_desc =
                                              await getFineDesc(koap.id);
                                          setState(() {});
                                        }),
                                      ),
                                    ),
                                    Container(
                                      margin: EdgeInsets.symmetric(vertical: 5),
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
                                      margin: EdgeInsets.symmetric(vertical: 5),
                                      child: EditTextField(
                                        text: 'Описание штрафа',
                                        value: _fault.fine_desc,
                                        onSaved: (value) =>
                                            {_fault.fine_desc = value},
                                        context: context,
                                        borderColor:
                                            Theme.of(context).primaryColorDark,
                                        height: 160,
                                        maxLines: 9,
                                        margin: 0,
                                      ),
                                    ),
                                    Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Expanded(
                                              flex: 3,
                                              child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      margin: EdgeInsets.only(
                                                          top: 5, right: 20),
                                                      child: EditTextField(
                                                        text:
                                                            'Сумма итогового штрафа, руб',
                                                        value:
                                                            _fault.fine != null
                                                                ? _fault.fine
                                                                    .toString()
                                                                : '',
                                                        onSaved: (value) => {
                                                          _fault.fine =
                                                              int.tryParse(
                                                                  value)
                                                        },
                                                        context: context,
                                                        borderColor: Theme.of(
                                                                context)
                                                            .primaryColorDark,
                                                        height: 40,
                                                        inputFormatters: <
                                                            TextInputFormatter>[
                                                          FilteringTextInputFormatter
                                                              .digitsOnly
                                                        ], // Only numbers can be entered
                                                        textInputType:
                                                            TextInputType
                                                                .numberWithOptions(
                                                                    decimal:
                                                                        true),
                                                        margin: 0,
                                                      ),
                                                    ),
                                                    Container(
                                                      margin: EdgeInsets.only(
                                                          bottom: 5, right: 20),
                                                      child: DatePicker(
                                                          parentContext:
                                                              context,
                                                          text:
                                                              "Плановая дата устранения",
                                                          width:
                                                              double.infinity,
                                                          height: 40,
                                                          borderColor:
                                                              Theme.of(context)
                                                                  .buttonColor,
                                                          selectedDate: _fault
                                                              .plan_fix_date // ??
                                                          //DateTime.now().toUtc()
                                                          ,
                                                          onChanged:
                                                              ((DateTime date) {
                                                            setState(() {
                                                              _fault.plan_fix_date =
                                                                  date;
                                                            });
                                                          })),
                                                    )
                                                  ])),
                                          Expanded(
                                              flex: 2,
                                              child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      margin: EdgeInsets.only(
                                                          top: 5, bottom: 35),
                                                      child: EditTextField(
                                                          backgroundColor:
                                                           _fault.id != null ?
                                                              Theme.of(context)
                                                                  .primaryColorLight:
                                                                  Theme.of(context)
                                                                  .shadowColor,
                                                          text:
                                                              'Размер вреда, руб',
                                                          value: _fault
                                                                      .damageAmount !=
                                                                  null
                                                              ? _fault
                                                                  .damageAmount
                                                                  .toString()
                                                                  .replaceAll(
                                                                      '.', ',')
                                                              : '',
                                                          readOnly: true,
                                                          context: context,
                                                          borderColor: Theme.of(
                                                                  context)
                                                              .primaryColorDark,
                                                          height: 40,
                                                          margin: 0,
                                                          onTap: () =>
                                                              faultDamageClicked(
                                                                  _fault.id)),
                                                    ),
                                                    Container(
                                                        alignment: Alignment
                                                            .bottomCenter,
                                                        padding:
                                                            EdgeInsets.only(
                                                                bottom: 5),
                                                        // EdgeInsets.only(top: 20),
                                                        child: new Container(
                                                          width: 150,
                                                          height: 40.0,
                                                          decoration:
                                                              new BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .all(Radius
                                                                        .circular(
                                                                            10)),
                                                            color: Theme.of(
                                                                    context)
                                                                .buttonColor,
                                                          ),
                                                          child:
                                                              new MaterialButton(
                                                            onPressed:
                                                                () async {
                                                              if (!showLoadingImage)
                                                                return await submitFault();
                                                            },
                                                            child: (!showLoadingImage)
                                                                ? new Text(
                                                                    "принять",
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            17.0,
                                                                        color: Colors
                                                                            .white),
                                                                  )
                                                                : CircularProgressIndicator(
                                                                    valueColor: AlwaysStoppedAnimation<
                                                                        Color>(Theme.of(
                                                                            context)
                                                                        .primaryColorLight),
                                                                  ),
                                                          ),
                                                        )

                                                        /*MyButton(
                                                    text: 'принять',
                                                    fontSize: 17, margin: 0,
                                                    parentContext: context,
                                                    onPress: () async {
                                                      await submitFault();
                                                    }),*/
                                                        )
                                                  ]))
                                        ]),
                                  ])))),
                  Expanded(
                      flex: 2,
                      child: Container(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                                flex: 5,
                                child: Container(
                                    padding: EdgeInsets.only(bottom: 10),
                                    child: showLoadingImage
                                        ? Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                                CircularProgressIndicator(
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                              Color>(
                                                          Theme.of(context)
                                                              .primaryColor),
                                                ),
                                              ])
                                        : _image == null
                                            ? GestureDetector(
                                                child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.add_a_photo,
                                                        color: Theme.of(context)
                                                            .primaryColor,
                                                        size: 120,
                                                      ),
                                                      Text('Добавить фото',
                                                          style: TextStyle(
                                                              color: Theme.of(
                                                                      context)
                                                                  .primaryColor,
                                                              fontSize: 20))
                                                    ]),
                                                /* onTapDown: (details) {
                                              _storePosition(details);
                                              _showPhotoMenu();
                                            },*/
                                                onTap: _onGalleryButtonPressed,
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
                                                _image = File(
                                                    _imageList[i].file_data);
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
                                                    File(_imageList[i]
                                                        .file_data),
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
                            /*  onTapDown: (details) {
                              _storePosition(details);
                              _showPhotoMenu();
                            },*/
                            onTap: _onGalleryButtonPressed,
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
                                height: 440,
                                maxLines: 22,
                                margin: 0,
                              ),
                            ),
                          ))),
                        ],
                      )),
                ],
              ))
            ]));
  }
}
