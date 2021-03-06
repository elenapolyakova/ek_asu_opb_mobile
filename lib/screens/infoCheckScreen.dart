import 'dart:ui';

import 'package:ek_asu_opb_mobile/controllers/checkPlanItem.dart';
import 'package:ek_asu_opb_mobile/controllers/controllers.dart';
import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';

class InfoCheckScreen extends StatefulWidget {
  int departmentId;
  int checkPlanItemId;
  BuildContext context;
  GlobalKey key;
  @override
  InfoCheckScreen(
      this.context, this.departmentId, this.checkPlanItemId, this.key);

  @override
  State<InfoCheckScreen> createState() =>
      _InfoCheckScreen(departmentId, checkPlanItemId);
}

class _InfoCheckScreen extends State<InfoCheckScreen> {
  UserInfo _userInfo;
  int departmentId;
  int checkPlanItemId;
  bool showLoading = true;
  Department _department;
  final formKey = new GlobalKey<FormState>();
  String saveError;
  String _ogrn;
  String _inn;

  @override
  _InfoCheckScreen(this.departmentId, this.checkPlanItemId);

  @override
  void initState() {
    super.initState();
    showLoading = true;

    auth.checkLoginStatus(context).then((isLogin) {
      if (isLogin) {
        auth.getUserInfo().then((userInfo) {
          _userInfo = userInfo;
          saveError = '';
          _inn = '7708503727';
          _ogrn = '1037739877295';
          loadData();
        });
      } //isLogin == true
    }); //checkLoginStatus
  }

  Future<void> loadData() async {
    try {
      showLoadingDialog(context);
      setState(() => {showLoading = true});

      _department = await DepartmentController.selectById(departmentId);
      if ([null, '', 'null'].contains(_department.f_inn))
        _department.f_inn = _inn;
      if ([null, '', 'null'].contains(_department.f_ogrn))
        _department.f_ogrn = _ogrn;
    } catch (e) {} finally {
      hideDialog(context);
      showLoading = false;
      setState(() => {});
    }
  }

  List<PopupMenuEntry<Object>> getMenu(BuildContext context) {
    List<PopupMenuEntry<Object>> result = [];
    result.add(
      PopupMenuItem<String>(
          child: TextIcon(
            icon: Icons.edit,
            text: "Редактировать данные",
            margin: 5.0,
            /* onTap: () */
            color: Theme.of(context).primaryColorDark,
          ),
          value: 'edit'),
    );

    result.add(PopupMenuDivider(
      height: 20,
    ));

    result.add(
      PopupMenuItem<String>(
          child: TextIcon(
            icon: Icon(FontAwesome5.file_pdf).icon, //Icons.edit,
            text: "Экспорт в PDF",
            margin: 5.0,
            /* onTap: () */
            color: Theme.of(context).primaryColorDark,
          ),
          value: 'pdf'),
    );

    result.add(
      PopupMenuItem<String>(
          child: TextIcon(
            icon: Icon(FontAwesome5.file_excel).icon,
            text: "Экспорт в Excel",
            margin: 5.0,
            /* onTap: () */
            color: Theme.of(context).primaryColorDark,
          ),
          value: 'excel'),
    );

    return result;
  }

  Future<void> editInfoClicked() async {
    saveError = '';
    Department departmentCopy = Department(
      id: _department.id,
      railway_id: _department.railway_id,
      name: _department.name,
      f_inn: _department.f_inn,
      f_ogrn: _department.f_ogrn,
      f_okpo: _department.f_okpo,
      f_addr: _department.f_addr,
      director_fio: _department.director_fio,
      director_email: _department.director_email,
      director_phone: _department.director_phone,
      deputy_fio: _department.deputy_fio,
      deputy_email: _department.deputy_email,
      deputy_phone: _department.deputy_phone,
    );
    setState(() {});
    bool result = await showEditDialog(departmentCopy, setState);
    if (result != null && result) {
      setState(() {});
    }
  }

  Future<bool> showEditDialog(Department departmentCopy, setState) {
    return showDialog<bool>(
        context: context,
        barrierDismissible: true,
        barrierColor: Color(0x88E6E6E6),
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, StateSetter setState) {
            return
                // AlertDialog(
                //shape: RoundedRectangleBorder(
                //    borderRadius: BorderRadius.all(Radius.circular(12.0))),
                // backgroundColor: Theme.of(context).primaryColor,
                //   content:

                Stack(alignment: Alignment.center, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  "assets/images/app.jpg",
                  fit: BoxFit.fill,
                  height: 700,
                  width: 1000,
                ),
              ),
              Container(
                  width: 1000.0,
                  margin: EdgeInsets.symmetric(horizontal: 13, vertical: 13),
                  padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
                  child: Scaffold(
                      backgroundColor: Colors
                          .transparent, //  Theme.of(context).primaryColor,
                      body: Form(
                          key: formKey,
                          child: Container(
                              child: Column(children: [
                            FormTitle(
                                'Общие сведения о проверяемом предприятии'),
                            Expanded(
                                child: Center(
                                    child: SingleChildScrollView(
                                        child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                  MyRichText(
                                    'Наименование структурного подразделения: ',
                                    departmentCopy.name,
                                    color: Theme.of(context).primaryColorDark,
                                  ),
                                  Row(children: [
                                    Expanded(
                                      child: EditTextField(
                                        text: 'ИНН',
                                        value: departmentCopy.f_inn,
                                        onSaved: (value) =>
                                            {departmentCopy.f_inn = value},
                                        context: context,
                                      ),
                                    ),
                                    Expanded(
                                      child: EditTextField(
                                        text: 'ОГРН',
                                        value: departmentCopy.f_ogrn,
                                        onSaved: (value) =>
                                            {departmentCopy.f_ogrn = value},
                                        context: context,
                                      ),
                                    ),
                                    Expanded(
                                      child: EditTextField(
                                        text: 'ОКПО',
                                        value: departmentCopy.f_okpo,
                                        onSaved: (value) =>
                                            {departmentCopy.f_okpo = value},
                                        context: context,
                                      ),
                                    ),
                                  ]),
                                  Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                            margin: EdgeInsets.only(
                                                top: 20, bottom: 0),
                                            child: Text(
                                              'Директор:',
                                              textAlign: TextAlign.center,
                                            ))
                                      ]),
                                  Row(children: [
                                    Expanded(
                                      child: EditTextField(
                                        text: 'ФИО',
                                        value: departmentCopy.director_fio,
                                        onSaved: (value) => {
                                          departmentCopy.director_fio = value
                                        },
                                        context: context,
                                      ),
                                    ),
                                    Expanded(
                                      child: EditTextField(
                                        text: 'Телефон',
                                        value: departmentCopy.director_phone,
                                        onSaved: (value) => {
                                          departmentCopy.director_phone = value
                                        },
                                        context: context,
                                        textInputType: TextInputType.phone,
                                      ),
                                    ),
                                    Expanded(
                                      child: EditTextField(
                                        text: 'E-mail',
                                        value: departmentCopy.director_email,
                                        onSaved: (value) => {
                                          departmentCopy.director_email = value
                                        },
                                        context: context,
                                        textInputType:
                                            TextInputType.emailAddress,
                                        validator: emailValidator,
                                      ),
                                    ),
                                  ]),
                                  Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                            margin: EdgeInsets.only(
                                                top: 20, bottom: 0),
                                            child: Text(
                                              'Ответственное лицо:',
                                              textAlign: TextAlign.center,
                                            ))
                                      ]),
                                  Row(children: [
                                    Expanded(
                                      child: EditTextField(
                                        text: 'ФИО',
                                        value: departmentCopy.deputy_fio,
                                        onSaved: (value) =>
                                            {departmentCopy.deputy_fio = value},
                                        context: context,
                                      ),
                                    ),
                                    Expanded(
                                      child: EditTextField(
                                        text: 'Телефон',
                                        value: departmentCopy.deputy_phone,
                                        onSaved: (value) => {
                                          departmentCopy.deputy_phone = value
                                        },
                                        context: context,
                                        textInputType: TextInputType.phone,
                                      ),
                                    ),
                                    Expanded(
                                      child: EditTextField(
                                        text: 'E-mail',
                                        value: departmentCopy.deputy_email,
                                        onSaved: (value) => {
                                          departmentCopy.deputy_email = value
                                        },
                                        context: context,
                                        textInputType:
                                            TextInputType.emailAddress,
                                        validator: emailValidator,
                                      ),
                                    ),
                                  ]),
                                  MyRichText(
                                    'Адрес: ',
                                    departmentCopy.f_addr,
                                    color: Theme.of(context).primaryColorDark,
                                  ),
                                ])))),
                            Container(
                                child: Column(children: [
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MyButton(
                                        text: 'принять',
                                        parentContext: context,
                                        onPress: () {
                                          submitPlan(departmentCopy, setState);
                                        }),
                                    MyButton(
                                        text: 'отменить',
                                        parentContext: context,
                                        onPress: () {
                                          cancelDepartment();
                                        }),
                                  ]),
                              Container(
                                  width: double.infinity,
                                  height: 20,
                                  color: (saveError != "")
                                      ? Color(0xAAE57373)
                                      : Color(0x00E57373),
                                  child: Text('$saveError',
                                      textAlign: TextAlign.center,
                                      style:
                                          TextStyle(color: Color(0xFF252A0E))))
                            ]))
                          ])))))
            ]);
          });
        });
  }

  Future<void> cancelDepartment() async {
    Navigator.pop<bool>(context, null);
  }

  void submitPlan(Department departmentCopy, setState) async {
    //  var formPlanKey2 = formKey;
    final form = formKey.currentState;
    hideKeyboard();
    if (form.validate()) {
      form.save();
      bool hasErorr = false;
      Map<String, dynamic> result;
      try {
        result = await DepartmentController.update(departmentCopy);

        hasErorr = result["code"] < 0; //TODO вернуть

        if (hasErorr) {
          Navigator.pop<bool>(context, false);
          Scaffold.of(context).showSnackBar(errorSnackBar());
        } else {
          setState(() {
            _department = departmentCopy;
          });

          Navigator.pop<bool>(context, true);
          Scaffold.of(context).showSnackBar(successSnackBar);
        }
      } catch (e) {
        Navigator.pop<bool>(context, false);
        Scaffold.of(context).showSnackBar(errorSnackBar());
      }
    }
  }

  Future<void> exportToExcel() async {
    try {
      showLoadingDialog(context);
      CheckPlanItem checkPlanItem =
          await CheckPlanItemController.selectById(checkPlanItemId);
      File file = await checkPlanItem.xlsReport;
      hideDialog(context);
      if (file != null) {
        OpenFile.open(file.path);
      }
    } catch (e) {
      hideDialog(context);
    }
  }

  Future<void> exportToPdf() async {
    try {
      showLoadingDialog(context);
       CheckPlanItem checkPlanItem =
          await CheckPlanItemController.selectById(checkPlanItemId);
      File file = await checkPlanItem.pdfReport;
      hideDialog(context);
      if (file != null) {
        OpenFile.open(file.path);
      }
    } catch (e) {
      hideDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(widget.context).buttonColor;
    final textStyle = TextStyle(fontSize: 16.0, color: color);

    final menu = PopupMenuButton(
      itemBuilder: (_) => getMenu(context),
      padding: EdgeInsets.all(0.0),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            editInfoClicked();
            break;
          case 'pdf':
            exportToPdf();
            return;
          case 'excel':
            exportToExcel();
            return;
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

    String director = '';
    String deputy = '';

    if (!showLoading) {
      director = (!['', null].contains(_department.director_fio)
              ? '${_department.director_fio}, '
              : '') +
          (!['', null].contains(_department.director_phone)
              ? '${_department.director_phone}, '
              : '') +
          (!['', null].contains(_department.director_email)
              ? '${_department.director_email}, '
              : '');
      if (director != '') director = slice(director, 0, -2);

      deputy = (!['', null].contains(_department.deputy_fio)
              ? '${_department.deputy_fio}, '
              : '') +
          (!['', null].contains(_department.deputy_phone)
              ? '${_department.deputy_phone}, '
              : '') +
          (!['', null].contains(_department.deputy_email)
              ? '${_department.deputy_email}, '
              : '');
      if (deputy != '') deputy = slice(deputy, 0, -2);
    }
    return Expanded(
        child: Container(
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage("assets/images/frameScreen.png"),
                    fit: BoxFit.fill)),
            child: showLoading
                ? Text("")
                : Padding(
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                    child: Column(children: [
                      Expanded(
                          child: ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ListTile(
                                              trailing: menu,
                                              contentPadding: EdgeInsets.all(0),
                                              title: FormTitle(
                                                  'Сведения о предприятии'),
                                              onTap: () {}),
                                          Container(
                                            margin: EdgeInsets.symmetric(
                                                vertical: 10),
                                            child: MyRichText(
                                              'Наименование структурного подразделения: \n ',
                                              _department.name,
                                            ),
                                          ),
                                          Container(
                                            margin: EdgeInsets.symmetric(
                                                vertical: 10),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                    child: MyRichText(
                                                  'ОГРН: ',
                                                  _department.f_ogrn,
                                                )),
                                                Expanded(
                                                    child: MyRichText(
                                                  'ИНН: ',
                                                  _department.f_inn,
                                                )),
                                                Expanded(
                                                    child: MyRichText(
                                                  'ОКПО: ',
                                                  _department.f_okpo,
                                                )),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            margin: EdgeInsets.symmetric(
                                                vertical: 10),
                                            child: MyRichText(
                                                'Директор: ', director),
                                          ),
                                          Container(
                                            margin: EdgeInsets.symmetric(
                                                vertical: 10),
                                            child: MyRichText(
                                                'Ответственное лицо: ', deputy),
                                          ),
                                          Container(
                                            margin: EdgeInsets.symmetric(
                                                vertical: 10),
                                            child: MyRichText(
                                                'Адрес: ', _department.f_addr),
                                          ),
                                        ]),
                                    flex: 3),
                              ],
                            )
                          ]))
                    ]))));
  }
}
