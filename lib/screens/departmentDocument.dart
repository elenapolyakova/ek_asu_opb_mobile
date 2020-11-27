import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/controllers/departmentDocument.dart';
import 'package:ek_asu_opb_mobile/models/departmentDocument.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';
import 'package:flutter_treeview/tree_view.dart';
import 'package:open_file/open_file.dart';

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

  Map<String, String> sectionName = {
    'air': 'Воздух',
    'waste': 'Отходы',
    'water': 'Вода'
  };

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
      await loadNodes();
      //await loadSections();
      _treeViewController = TreeViewController(
        children: _nodes,
        selectedKey: _selectedNode,
      );
    } catch (e) {} finally {
      hideDialog(context);
      showLoading = false;

      setState(() => {});
    }
  }

  loadNodes() async {
    await DepartmentDocumentController.select(_departmentId, fromServer: true);

    _sectionList =
        await DepartmentDocumentController.getSectionList(_departmentId);
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
          label: sectionName[section],
          icon: NodeIcon.fromIconData(Icons.input),
          expanded: true,
          children: sectionDoc
              .map(
                (doc) => Node(
                        label: doc.fileName,
                        key: doc.id.toString(),
                        data: doc,
                        icon: ['', null].contains(doc.filePath)
                            ? NodeIcon.fromIconData(Icons.get_app)
                            : NodeIcon.fromIconData(Icons.insert_drive_file)),
              )
              .toList()));
    });
  }

  onNodeTap(key) {
    setState(() {
      _selectedNode = key;
      _treeViewController = _treeViewController.copyWith(selectedKey: key);
    });
    Node selectedNode = _treeViewController.getNode(key);
    Document doc = selectedNode.data;

    if (['', null].contains(doc.filePath)) {
      List<Node> updated = _treeViewController.updateNode(
          key,
          selectedNode.copyWith(
              icon: NodeIcon(codePoint: Icons.hourglass_bottom.codePoint)));
      setState(() {
        _treeViewController = _treeViewController.copyWith(children: updated);
      });

      doc.file.then((value) {
        updated = _treeViewController.updateNode(
            key,
            selectedNode.copyWith(
                data: doc,
                icon: NodeIcon(codePoint: Icons.insert_drive_file.codePoint)));
        setState(() {
          _treeViewController = _treeViewController.copyWith(children: updated);
        });

        OpenFile.open(doc.filePath);
      });
    } else
      OpenFile.open(doc.filePath);
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
                            onNodeTap: onNodeTap,
                            theme: getTreeViewTheme(context)),
                      )
                    ]))));
  }
}
