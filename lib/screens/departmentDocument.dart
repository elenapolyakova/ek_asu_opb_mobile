import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';
import 'package:flutter_treeview/tree_view.dart';

class DepartmentDocumentScreen extends StatefulWidget {
  @override
  State<DepartmentDocumentScreen> createState() => _DepartmentDocumentScreen();
}

class _DepartmentDocumentScreen extends State<DepartmentDocumentScreen> {
  UserInfo _userInfo;
  bool showLoading = true;
  bool docsOpen;

//////////////////////////////////////////////
  List<Node> nodes = [
    Node(
      label: 'Documents',
      key: 'docs',
      expanded: true,
      icon: NodeIcon(
        codePoint:
            // docsOpen ? Icons.folder_open.codePoint :
            Icons.folder.codePoint,
        color: "blue",
      ),
      children: [
        Node(
            label: 'Job Search',
            key: 'd3',
            icon: NodeIcon.fromIconData(Icons.input),
            children: [
              Node(
                  label: 'Resume.docx',
                  key: 'pd1',
                  icon: NodeIcon.fromIconData(Icons.insert_drive_file)),
              Node(
                  label: 'Cover Letter.docx',
                  key: 'pd2',
                  icon: NodeIcon.fromIconData(Icons.insert_drive_file)),
            ]),
        Node(
          label: 'Inspection.docx',
          key: 'd1',
        ),
        Node(
            label: 'Invoice.docx',
            key: 'd2',
            icon: NodeIcon.fromIconData(Icons.insert_drive_file)),
      ],
    ),
    Node(
        label: 'MeetingReport.xls',
        key: 'mrxls',
        icon: NodeIcon.fromIconData(Icons.insert_drive_file)),
    Node(
        label: 'MeetingReport.pdf',
        key: 'mrpdf',
        icon: NodeIcon.fromIconData(Icons.insert_drive_file)),
    Node(
        label: 'Demo.zip',
        key: 'demo',
        icon: NodeIcon.fromIconData(Icons.archive)),
  ];
//////////////////////////////////////////////

  @override
  void initState() {
    super.initState();

    auth.checkLoginStatus(context).then((isLogin) {
      if (isLogin) {
        auth.getUserInfo().then((userInfo) {
          _userInfo = userInfo;
          docsOpen = false;
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

  dynamic _expandNodeHandler(String key, bool isExpand) {}

  @override
  Widget build(BuildContext context) {
    TreeViewController _treeViewController =
        TreeViewController(children: nodes);

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
                        child: TreeView(
                            controller: _treeViewController,
                            allowParentSelect: false,
                            supportParentDoubleTap: false,
                            onExpansionChanged: _expandNodeHandler,
                            onNodeTap: (key) {
                              setState(() {
                                _treeViewController = _treeViewController
                                    .copyWith(selectedKey: key);
                              });
                            }),
                      )
                    ]))));
  }
}
