import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';
import 'package:flutter_treeview/tree_view.dart';

class ISPScreen extends StatefulWidget {
  BuildContext context;
  bool stop;
  @override
  ISPScreen({this.context, this.stop});

  @override
  State<ISPScreen> createState() => _ISPScreen();
}

class _ISPScreen extends State<ISPScreen> {
  UserInfo _userInfo;
  bool showLoading = true;
  String _selectedNode;
  bool docsOpen = true;
  bool deepExpanded = true;
  TreeViewController _treeViewController;
  List<Node> _nodes = [];

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
      loadNodes();
      _treeViewController = TreeViewController(
        children: _nodes,
        selectedKey: _selectedNode,
      );
      setState(() => {});
    }
  }

  Future<void> loadNodes() async {
    _nodes = [
      Node(
        label: 'Документы',
        key: 'docs',
        expanded: docsOpen,
        icon: NodeIcon(
          codePoint:
              docsOpen ? Icons.folder_open.codePoint : Icons.folder.codePoint,
          // color: 'green'//Theme.of(context).primaryColor.toString(),
        ),
        children: [
          Node(
              label: 'Нормативно-правовые акты',
              key: 'waste',
              expanded: false,
              icon: NodeIcon.fromIconData(Icons.folder),
              children: [
                Node(
                    label: 'Приказ Росстата.docx',
                    key: 'order_1',
                    icon: NodeIcon.fromIconData(Icons.insert_drive_file)),
                Node(
                    label: 'ФЗ-123.docx',
                    key: 'FL1',
                    icon: NodeIcon.fromIconData(Icons.insert_drive_file)),
              ]),
          Node(
              label: 'Распорядительные документы',
              key: 'water',
              expanded: false,
              icon: NodeIcon.fromIconData(Icons.folder),
              children: [
                Node(
                    label: 'Распоряжение №217.pdf',
                    key: 'order_2',
                    icon: NodeIcon.fromIconData(Icons.insert_drive_file)),
                Node(
                    label: 'Письмо в ГВЦ.pdf',
                    key: 'letter1',
                    icon: NodeIcon.fromIconData(Icons.insert_drive_file)),
              ]),
          Node(
              label: 'Рабочая документация',
              key: 'docs_work',
              icon: NodeIcon.fromIconData(Icons.folder),
              expanded: false,
              children: [
                Node(
                    label: 'Руководство пользователя.docx',
                    key: 'user_manual',
                    icon: NodeIcon.fromIconData(Icons.insert_drive_file)),
                Node(
                    label: 'Руководство администратора.pdf',
                    key: 'admin_manual',
                    icon: NodeIcon.fromIconData(Icons.insert_drive_file)),
                Node(
                    label: 'Руководство по инсталяции.pdf',
                    key: 'install_manual',
                    icon: NodeIcon.fromIconData(Icons.insert_drive_file)),
                Node(
                    label: 'Программа и методика испытаний.pdf',
                    key: 'test_manual',
                    icon: NodeIcon.fromIconData(Icons.insert_drive_file)),
              ]),
        ],
      )
    ];
  }

  _expandNodeHandler(String key, bool expanded) {
    String msg = '${expanded ? "Expanded" : "Collapsed"}: $key';
    debugPrint(msg);
    Node node = _treeViewController.getNode(key);
    if (node != null) {
      List<Node> updated;
      if (key == 'docs') {
        updated = _treeViewController.updateNode(
          key,
          node.copyWith(
              expanded: expanded,
              icon: NodeIcon(
                codePoint: expanded
                    ? Icons.folder_open.codePoint
                    : Icons.folder.codePoint,
                // color: expanded ? "blue600" : "grey700",
              )),
        );
      } else {
        updated = _treeViewController.updateNode(
            key, node.copyWith(expanded: expanded));
      }
      setState(() {
        if (key == 'docs') docsOpen = expanded;
        _treeViewController = _treeViewController.copyWith(children: updated);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: PreferredSize(
            preferredSize: Size.fromHeight(100),
            child: MyAppBar(
                showIsp: false,
                userInfo: _userInfo,
                syncTask: null,
                 stop: widget.stop,
                parentScreen: 'ISPScreen')),
        body: Container(
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
                            onExpansionChanged: (key, expanded) =>
                                _expandNodeHandler(key, expanded),
                            onNodeTap: (key) {
                              debugPrint('Selected: $key');
                              setState(() {
                                _selectedNode = key;
                                _treeViewController = _treeViewController
                                    .copyWith(selectedKey: key);
                              });
                            },
                            theme: getTreeViewTheme(context)),
                      )
                    ]))) //getBodyContent(),
        );
  }
}
