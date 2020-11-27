import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/controllers/departmentDocument.dart';
import 'package:ek_asu_opb_mobile/models/departmentDocument.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';
import 'package:flutter_treeview/tree_view.dart';

class DepartmentDocumentScreen extends StatefulWidget {
  int departmentId;

  @override
  DepartmentDocumentScreen(this.departmentId);

  @override
  State<DepartmentDocumentScreen> createState() => _DepartmentDocumentScreen();
}

class _DepartmentDocumentScreen extends State<DepartmentDocumentScreen> {
  UserInfo _userInfo;
  bool showLoading = true;
  String _selectedNode;
  bool docsOpen = true;
  bool deepExpanded = true;
  TreeViewController _treeViewController;
  List<Node> _nodes = [];
  List<Document> _documentList;
  List<String> _sectionList;
  int _departmentId;

  @override
  void initState() {
    super.initState();

    auth.checkLoginStatus(context).then((isLogin) {
      if (isLogin) {
        auth.getUserInfo().then((userInfo) {
          _userInfo = userInfo;
          _departmentId = widget.departmentId;
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
      loadSections();
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
              label: 'Воздух',
              key: 'air',
              icon: NodeIcon.fromIconData(Icons.input),
              expanded: true,
              children: [
                Node(
                    label: 'ПДВ.docx',
                    key: 'air_1',
                    icon: NodeIcon.fromIconData(Icons.get_app)),
                Node(
                    label: 'ВСВ.pdf',
                    key: 'air_2',
                    icon: NodeIcon.fromIconData(Icons.insert_drive_file)),
              ]),
          Node(
              label: 'Вода',
              key: 'water',
              expanded: true,
              icon: NodeIcon.fromIconData(Icons.input),
              children: [
                Node(
                    label: 'ПДС.pdf',
                    key: 'water_1',
                    icon: NodeIcon.fromIconData(Icons.insert_drive_file)),
                Node(
                    label: 'ВСС.pdf',
                    key: 'water_2',
                    icon: NodeIcon.fromIconData(Icons.insert_drive_file)),
              ]),
          Node(
              label: 'Отходы',
              key: 'waste',
              expanded: true,
              icon: NodeIcon.fromIconData(Icons.input),
              children: [
                Node(
                    label: 'Лимит.docx',
                    key: 'waste_1',
                    icon: NodeIcon.fromIconData(Icons.insert_drive_file)),
                Node(
                    label: 'Разрешение.docx',
                    key: 'waste_2',
                    icon: NodeIcon.fromIconData(Icons.insert_drive_file)),
              ]),
        ],
      )
    ];
  }

  loadSections() async {
    _sectionList =
        await DepartmentDocumentController.getSectionList(_departmentId);
    _documentList = await DepartmentDocumentController.select(_departmentId,
        fromServer: true);
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
          children: [])
    ];

    await Future.forEach(_sectionList, (String section) async {
      List<Document> sectionDoc = await DepartmentDocumentController.select(
          _departmentId,
          section: section,
          fromServer: false);

      _nodes[0].children.add(Node(
          key: section,
          label: section,
          icon: NodeIcon.fromIconData(Icons.input),
          expanded: true,
          children: List.generate(
            sectionDoc.length,
            (i) => Node(
                label: sectionDoc[i].fileName,
                key: sectionDoc[i].id.toString(),
                icon: ['', null].contains(sectionDoc[i].filePath)
                    ? NodeIcon.fromIconData(Icons.get_app)
                    : NodeIcon.fromIconData(Icons.insert_drive_file)),
          )));
    });

    _documentList = await DepartmentDocumentController.select(_departmentId,
        fromServer: true);

    print(_documentList.length);
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
    return Expanded(
        child: Container(
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage("assets/images/frameScreen.png"),
                    fit: BoxFit.fitWidth)),
            child: showLoading
                ? Text("")
                : Padding(
                    padding: EdgeInsets.symmetric(horizontal: 80, vertical: 10),
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
                    ]))));
  }
}
