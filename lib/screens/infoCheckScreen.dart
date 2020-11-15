import 'dart:ui';

import 'package:ek_asu_opb_mobile/controllers/controllers.dart';
import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';

//TODO delete
class MyDepartment {
  int department_id;
  String inn;
  String ogrn;
  String okpo;
  String addr;
  String director_fio;
  String director_email;
  String director_phone;
  String deputy_fio;
  String deputy_email;
  String deputy_phone;
  String name;
  MyDepartment(
      {this.department_id,
      this.inn,
      this.ogrn,
      this.okpo,
      this.addr,
      this.director_fio,
      this.director_email,
      this.deputy_phone,
      this.deputy_fio,
      this.deputy_email,
      this.director_phone,
      this.name});
}

//TODO delete

class InfoCheckScreen extends StatefulWidget {
  int departmentId;
  BuildContext context;
  @override
  InfoCheckScreen(this.context, this.departmentId);

  @override
  State<InfoCheckScreen> createState() => _InfoCheckScreen(departmentId);
}

class _InfoCheckScreen extends State<InfoCheckScreen> {
  UserInfo _userInfo;
  int departmentId;
  bool showLoading = true;
  Department department;
  MyDepartment _department;
  final formKey = new GlobalKey<FormState>();
  String saveError;

  @override
  _InfoCheckScreen(this.departmentId);

  @override
  void initState() {
    super.initState();
    showLoading = true;

    auth.checkLoginStatus(context).then((isLogin) {
      if (isLogin) {
        auth.getUserInfo().then((userInfo) {
          _userInfo = userInfo;
          saveError = '';
          loadData();
        });
      } //isLogin == true
    }); //checkLoginStatus
  }

  Future<void> loadData() async {
    try {
      showLoadingDialog(context);
      setState(() => {showLoading = true});

      department = await DepartmentController.selectById(departmentId);
      _department = MyDepartment(
          department_id: departmentId,
          inn: '7708503727',
          ogrn: '1037739877295',
          name: department.name,
          director_fio: 'Иванов И.И.');
    } catch (e) {} finally {
      hideDialog(context);
      showLoading = false;
      setState(() => {});
    }
  }

  List<PopupMenuItem<String>> getMenu(BuildContext context) {
    List<PopupMenuItem<String>> result = [];
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

    return result;
  }

  Future<void> editInfoClicked() async {
    saveError = '';
    MyDepartment departmentCopy = MyDepartment(
      department_id: _department.department_id,
      name: _department.name,
      inn: _department.inn,
      ogrn: _department.ogrn,
      okpo: _department.okpo,
      addr: _department.addr,
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

  Future<bool> showEditDialog(MyDepartment departmentCopy, setState) {
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
                                  ),
                                  Row(children: [
                                    Expanded(
                                      child: EditTextField(
                                        text: 'ИНН',
                                        value: departmentCopy.inn,
                                        onSaved: (value) =>
                                            {departmentCopy.inn = value},
                                        context: context,
                                      ),
                                    ),
                                    Expanded(
                                      child: EditTextField(
                                        text: 'ОГРН',
                                        value: departmentCopy.ogrn,
                                        onSaved: (value) =>
                                            {departmentCopy.ogrn = value},
                                        context: context,
                                      ),
                                    ),
                                    Expanded(
                                      child: EditTextField(
                                        text: 'ОКПО',
                                        value: departmentCopy.okpo,
                                        onSaved: (value) =>
                                            {departmentCopy.okpo = value},
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
                                    departmentCopy.addr,
                                  ),
                                ])))),
                            Container(
                                child: Column(children: [
                              MyButton(
                                  text: 'принять',
                                  parentContext: context,
                                  onPress: () {
                                    submitPlan(departmentCopy, setState);
                                  }),
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

  void submitPlan(MyDepartment departmentCopy, setState) async {
    //  var formPlanKey2 = formKey;
    final form = formKey.currentState;
    hideKeyboard();
    if (form.validate()) {
      form.save();
      bool hasErorr = false;
      Map<String, dynamic> result;
      try {
        // result = await controllers.PlanController.update(departmentCopy);

        hasErorr = false; //result["code"] < 0; TODO вернуть

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
                    fit: BoxFit.fitWidth)),
            child: showLoading
                ? Text("")
                : Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                                              title: Text(
                                                  'Сведения о предприятии',
                                                  textAlign: TextAlign.center),
                                              onTap: () {}),
                                          MyRichText(
                                            'Наименование структурного подразделения: ',
                                            _department.name,
                                          ),
                                          Row(
                                            children: [
                                              Expanded(
                                                  child: MyRichText(
                                                'ОГРН: ',
                                                _department.ogrn,
                                              )),
                                              Expanded(
                                                  child: MyRichText(
                                                'ИНН: ',
                                                _department.inn,
                                              )),
                                              Expanded(
                                                  child: MyRichText(
                                                'ОКПО: ',
                                                _department.okpo,
                                              )),
                                            ],
                                          ),
                                          MyRichText('Директор: ', director),
                                          MyRichText(
                                              'Ответственное лицо: ', deputy),
                                          MyRichText(
                                              'Адрес: ', _department.addr)
                                        ]),
                                    flex: 3),
                                Expanded(
                                    child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Text(
                                            'Статус: ',
                                            style: textStyle,
                                          ),
                                          Text('не проводилась'),
                                          Icon(Icons.circle, color: Colors.red)
                                        ]),
                                    flex: 1)
                              ],
                            )
                          ]))
                    ]))));
  }
}
