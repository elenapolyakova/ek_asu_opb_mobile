import 'dart:io';

import 'package:ek_asu_opb_mobile/models/faultItem.dart';
import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'dart:typed_data';
import 'package:ek_asu_opb_mobile/src/fileStorage.dart';
import 'package:ek_asu_opb_mobile/src/GPS.dart';
import 'package:ek_asu_opb_mobile/models/faultFix.dart';
import 'package:ek_asu_opb_mobile/controllers/faultFix.dart';
import 'package:ek_asu_opb_mobile/models/faultFixItem.dart';
import 'package:ek_asu_opb_mobile/controllers/faultFixItem.dart';

class FaultFixScreen extends StatefulWidget {
  int faultId;
  int faultFixId;
  Function(Map<String, String>, dynamic arg) push;
  Map<String, String> Function() pop;
  GlobalKey key;

  @override
  FaultFixScreen(this.faultFixId, this.faultId, this.push, this.pop, this.key);

  @override
  State<FaultFixScreen> createState() => _FaultFixScreen();
}

class _FaultFixScreen extends State<FaultFixScreen> {
  UserInfo _userInfo;
  bool showLoading = true;
  bool showLoadingImage = false;
  FaultFix _faultFix;
  int _faultFixId;
  int _faultId;
  List<String> _deletedPath;
  List<Map<String, dynamic>> _created;

  //final _sizeTextWhite =  TextStyle(fontSize: 20, color: Colors.white);
  final _sizeTextBlack = TextStyle(fontSize: 20, color: Colors.black);

  File _image;
  int _imageIndex;
  List<FaultFixItem> _imageList = [];

  List<Asset> _assetList = List<Asset>();

  @override
  void initState() {
    super.initState();

    auth.checkLoginStatus(context).then((isLogin) {
      if (isLogin) {
        auth.getUserInfo().then((userInfo) {
          _userInfo = userInfo;
          _faultFixId = widget.faultFixId;
          _faultId = widget.faultId;

          loadData();
        });
      } //isLogin == true
    }); //checkLoginStatus
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

          FaultFixItem faultFixItem = FaultFixItem(
              id: null,
              parent3_id: widget.faultFixId,
              file_data: path,
              active: true,
              coord_e: geoPoint.longitude,
              coord_n: geoPoint.latitude);
          _imageList.insert(i, faultFixItem);
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

  Future<void> deleteImage(int index) async {
    bool result = await showConfirmDialog(
        'Вы уверены, что хотите удалить фото?', context);
    if (result != null && result) {
      bool hasErorr = false;
      Map<String, dynamic> result;
      FaultFixItem deletedFile = _imageList[index];

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
        Scaffold.of(context)
            .showSnackBar(errorSnackBar(text: 'Произошла ошибка при удалении'));
      }
    }
  }

  Future<void> loadData() async {
    try {
      showLoadingDialog(context);
      setState(() => {showLoading = true});
      _deletedPath = [];
      _created = [];
      await loadFaultFix();
      await loadImages();
    } catch (e) {} finally {
      hideDialog(context);
      showLoading = false;
      setState(() => {});
    }
  }

  Future<void> loadFaultFix() async {
    if (![null, -1].contains(_faultFixId))
      _faultFix = await FaultFixController.selectById(_faultFixId);
    if (_faultFix == null) {
      _faultFix = new FaultFix(id: null, parent_id: _faultId, active: true);
    }
  }

  Future<void> loadImages() async {
    _imageList = [];
    _imageList = _faultFix.id != null
        ? await FaultFixItemController.select(_faultFix.id)
        : [];
    if (_imageList.length > 0) {
      _image = File(_imageList[0].file_data);
      _imageIndex = 0;
    }
  }

  submitFaultFix() async {
    bool hasErorr = false;
    Map<String, dynamic> result;

    try {
      if ([-1, null].contains(_faultFix.id)) {
        result =
            await FaultFixController.create(_faultFix, _created, _deletedPath);
      } else {
        result =
            await FaultFixController.update(_faultFix, _created, _deletedPath);
      }
      hasErorr = result["code"] < 0;

      if (hasErorr) {
        // Navigator.pop<bool>(context, false);
        Scaffold.of(context).showSnackBar(errorSnackBar());
      } else {
        if ([-1, null].contains(_faultFix.id)) {
          _faultFix.id = result["id"];
        }

        _created = [];
        _deletedPath = [];
        setState(() {});

        // Navigator.pop<bool>(context, true);
        Scaffold.of(context).showSnackBar(successSnackBar);
      }
    } catch (e) {
      //Navigator.pop<bool>(context, false);
      Scaffold.of(context).showSnackBar(errorSnackBar());
    }
    // widget.pop();
  }

  @override
  Widget build(BuildContext context) {
    return showLoading
        ? Text("")
        : Padding(
            padding: EdgeInsets.symmetric(vertical: 5, horizontal: 40),
            child: Column(children: [
              Expanded(
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Container(
                        width: 400,
                        child: SingleChildScrollView(
                            child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        FormTitle("Устранение нарушения"),
                                      ]),
                                      Row(children: [
                                        Container(
                                            height: 40.0,
                                            width: 170.0,
                                            alignment: Alignment.center,
                                            padding: new EdgeInsets.all(5.0),
                                            margin: new EdgeInsets.all(5.0),
                                            decoration: new BoxDecoration(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(10)),
                                                color: _faultFix.is_finished ==
                                                        true
                                                    ? Colors.green
                                                    : Colors.grey),
                                            child: new MaterialButton(
                                              onPressed: () {
                                                setState(() {
                                                  _faultFix.is_finished = true;
                                                });
                                              },
                                              child: new Text(
                                                'Проверено',
                                                style: _sizeTextBlack,
                                              ),
                                            )),
                                        Container(
                                            height: 40.0,
                                            width: 170.0,
                                            alignment: Alignment.center,
                                            padding: new EdgeInsets.all(5.0),
                                            margin: new EdgeInsets.all(5.0),
                                            decoration: new BoxDecoration(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(10)),
                                                color: _faultFix.is_finished ==
                                                        false
                                                    ? Colors.red
                                                    : Colors.grey),
                                            child: new MaterialButton(
                                              onPressed: () {
                                                setState(() {
                                                  _faultFix.is_finished = false;
                                                });
                                              },
                                              child: new Text(
                                                'Отклонено',
                                                style: _sizeTextBlack,
                                              ),
                                            )),
                                      ]),
                                      Row(
                                        children: [
                                          Expanded(
                                              flex: 1,
                                              child: Column(children: [
                                                GestureDetector(
                                                  child: Container(
                                                    height: 30,
                                                    child: Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .end,
                                                        children: [
                                                          Icon(
                                                              Icons.add_a_photo,
                                                              size: 30,
                                                              color: Theme.of(
                                                                      context)
                                                                  .primaryColor),
                                                          Padding(
                                                              padding: EdgeInsets
                                                                  .only(
                                                                      left: 10),
                                                              child: Text(
                                                                  'Добавить фото',
                                                                  style: TextStyle(
                                                                      color: Theme.of(
                                                                              context)
                                                                          .primaryColor))),
                                                        ]),
                                                  ),
                                                  onTap:
                                                      _onGalleryButtonPressed,
                                                ),
                                              ]))
                                        ],
                                      ),
                                      Container(
                                        margin:
                                            EdgeInsets.symmetric(vertical: 10),
                                        child: EditTextField(
                                          text: 'Описание устранения нарушения',
                                          value: _faultFix.desc,
                                          onSaved: (value) =>
                                              {_faultFix.desc = value},
                                          context: context,
                                          borderColor: Theme.of(context)
                                              .primaryColorDark,
                                          height: 270,
                                          // maxLines: 13,
                                          margin: 0,
                                        ),
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Expanded(
                                              child: Container(
                                            margin: EdgeInsets.only(
                                                bottom: 5, right: 20),
                                            child: DatePicker(
                                                parentContext: context,
                                                text: "Дата устранения",
                                                width: 200,
                                                height: 40,
                                                borderColor: Theme.of(context)
                                                    .buttonColor,
                                                selectedDate:
                                                    _faultFix.date // ??
                                                //DateTime.now().toUtc()
                                                ,
                                                onChanged: ((DateTime date) {
                                                  setState(() {
                                                    _faultFix.date = date;
                                                  });
                                                })),
                                          )),
                                          Expanded(
                                              flex: 1,
                                              child: Container(
                                                  alignment:
                                                      Alignment.bottomCenter,
                                                  margin: EdgeInsets.only(
                                                      bottom: 5),
                                                  // EdgeInsets.only(top: 20),
                                                  child: new Container(
                                                    width: 150,
                                                    height: 40.0,
                                                    padding:
                                                        new EdgeInsets.all(0),
                                                    margin:
                                                        new EdgeInsets.all(0),
                                                    decoration:
                                                        new BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.all(
                                                              Radius.circular(
                                                                  10)),
                                                      color: Theme.of(context)
                                                          .buttonColor,
                                                    ),
                                                    child: new MaterialButton(
                                                      onPressed: () async {
                                                        if (!showLoadingImage)
                                                          return await submitFaultFix();
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

                                                  /* child: MyButton(
                                                    text: 'принять',
                                                    fontSize: 17,
                                                    margin: 0,
                                                    parentContext: context,
                                                    onPress: () async {
                                                      await submitFaultFix();
                                                    }),
                                              )*/
                                                  ))
                                        ],
                                      )
                                    ])))),
                    Expanded(
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
                                                      MainAxisAlignment.center,
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
                                                fit: BoxFit.cover,
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
                                              _image =
                                                  File(_imageList[i].file_data);
                                              _imageIndex = i;
                                            }),
                                            child: Container(
                                                constraints:
                                                    BoxConstraints.tight(
                                                        Size(95, 80)),
                                                padding: i == 0
                                                    ? EdgeInsets.only(right: 5)
                                                    : i == _imageList.length - 1
                                                        ? EdgeInsets.only(
                                                            left: 5)
                                                        : EdgeInsets.symmetric(
                                                            horizontal: 5),
                                                child: Image.file(
                                                  File(_imageList[i].file_data),
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
                  ]))
            ]));
  }
}
