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

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(widget.context).buttonColor;
    final textStyle = TextStyle(fontSize: 16.0, color: color);

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
                                  Expanded(child: 
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                  Container(
                                    child: Text('Предприятие', style: textStyle,))]),
                                  flex: 3),
                                  Expanded(child: 
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                          Text('Статус: ', style: textStyle,),
                                          Text('не проводилась'),
                                          Icon(Icons.circle, color: Colors.red)
                                          ]),
                                  flex: 1)
                                ],)
                              ]))
                    ]))));
  }
}
