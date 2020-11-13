import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';

class InfoCheckScreen extends StatefulWidget {
  int checkPlanItemId;
  BuildContext context;
  @override
  InfoCheckScreen(this.context, this.checkPlanItemId);

  @override
  State<InfoCheckScreen> createState() => _InfoCheckScreen(checkPlanItemId);
}

class _InfoCheckScreen extends State<InfoCheckScreen> {
  UserInfo _userInfo;
  int checkPlanItemId;
  bool showLoading = true;
  String depName;

  @override
  _InfoCheckScreen(this.checkPlanItemId);

  @override
  void initState() {
    super.initState();
    showLoading = true;

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

      //  reloadPlanItems(); //todo убрать отсюда
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
  void editInfoClicked(){
    
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

    return Expanded(
        child: Scaffold(
            body: Container(
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage("assets/images/frameScreen.png"),
                        fit: BoxFit.fitWidth)),
                child: showLoading
                    ? Text("")
                    : Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                                              EditTextField(
                                                text:
                                                    'Наименование структурного подразделения',
                                                value:
                                                    depName, //planItem.departmentTxt,
                                                onSaved: (value) => {
                                                  depName = value
                                                  //planItem.departmentTxt = value
                                                },
                                                context: widget.context,

                                                showEditDialog: true,
                                              ),
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
                                              Icon(Icons.circle,
                                                  color: Colors.red)
                                            ]),
                                        flex: 1)
                                  ],
                                )
                              ]))
                        ])))));
  }
}
