
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';
import 'package:flutter_treeview/tree_view.dart';
import 'package:open_file/open_file.dart';

class DocList {
  int parent_id;
  int id;
  String name;
  DocList(this.parent_id, this.id, this.name);
}

class DocFile {
  int parent_id;
  int id;
  String name;
  DateTime date;
  String number;
  String file_name;
  String filePath;
  String description;
  bool isNew;
  DocFile(this.parent_id, this.id, this.name, this.file_name, this.isNew);
}

List<DocList> docList = [
  DocList(null, 1, '1'),
  DocList(1, 2, '2'),
  DocList(1, 3, '3'),
];

List<DocFile> allFileList = [
  DocFile(2, 1, '1', '1', true),
  DocFile(2, 2, '2', '2', false),
  DocFile(3, 3, '3', '3', false),
  DocFile(3, 4, '4', '4', false),
  DocFile(1, 5, '5', '5', false),
  DocFile(1, 6, '6', '6', true),
];

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
      loadNodes();
      // loadNodesTest();
    } catch (e) {} finally {
      hideDialog(context);

      showLoading = false;

      _treeViewController = TreeViewController(
        children: _nodes,
        selectedKey: _selectedNode,
      );
      setState(() => {});
    }
  }

  loadNodes() async {
    List<DocList> rootList = docList
        .where((folder) => folder.parent_id == null)
        .toList(); //загружаем все корневые каталоги (parent_id = null)
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

    await Future.forEach(rootList, (DocList root) async {
      List<Node<dynamic>> children = [];
      List<Node<dynamic>> folders = await getFolders(root.id);
      if (folders != null && folders.length > 0) children.addAll(folders);

      List<Node<DocFile>> files = await getFiles(root.id);
      if (files != null && files.length > 0) children.addAll(files);

      _nodes[0].children.add(Node(
          key: 'dir_${root.id}',
          label: root.name,
          icon: NodeIcon.fromIconData(Icons.folder),
          expanded: true,
          children: children));
    });
  }

  Future<List<Node<dynamic>>> getFolders(int parent_id) async {
    List<DocList> folderList = docList
        .where((folder) => folder.parent_id == parent_id)
        .toList(); //загружаем все каталоги (по parent_id)
    List<Node> result = [];

    await Future.forEach(folderList, (DocList folder) async {
      List<Node<dynamic>> children = [];

      List<Node<dynamic>> folders = await getFolders(folder.id);
      if (folders != null && folders.length > 0) children.addAll(folders);

      List<Node<DocFile>> files = await getFiles(folder.id);
      if (files != null && files.length > 0) children.addAll(files);

      result.add(Node(
          key: 'dir_${folder.id}',
          label: folder.name,
          icon: NodeIcon.fromIconData(Icons.folder),
          expanded: true,
          children: children));
    });

    return result;
  }

  Future<List<Node<DocFile>>> getFiles(int parent_id) async {
    List<DocFile> fileList = allFileList
        .where((file) => file.parent_id == parent_id)
        .toList(); //загружаем все файлы (по parent_id)

    return fileList
        .map(
          (file) => Node(
              label: file.name,
              key: 'file_${file.id}',
              data: file,
              icon: ['', null].contains(file.filePath)
                  ? (file.isNew
                      ? NodeIcon(codePoint: Icons.new_releases.codePoint, color: 'red400')
                      : NodeIcon.fromIconData(Icons.get_app))
                  : NodeIcon.fromIconData(Icons.insert_drive_file)),
        )
        .toList();
  }

  onNodeTap(String key) {
    setState(() {
      _selectedNode = key;
      _treeViewController = _treeViewController.copyWith(selectedKey: key);
    });
    if (key.indexOf('dir_') > -1) return;

    Node selectedNode = _treeViewController.getNode(key);
    DocFile doc = selectedNode.data;
    if (doc != null) {
      if (['', null].contains(doc.filePath)) {
        List<Node> updated = _treeViewController.updateNode(
            key,
            selectedNode.copyWith(
                icon: NodeIcon(codePoint: Icons.hourglass_bottom.codePoint)));
        setState(() {
          _treeViewController = _treeViewController.copyWith(children: updated);
        });

        downloadFile(doc.id).then((file) {
          if (file != null) {
            updated = _treeViewController.updateNode(
                key,
                selectedNode.copyWith(
                    data: doc,
                    icon: NodeIcon(
                        codePoint: Icons.insert_drive_file.codePoint)));
            setState(() {
              _treeViewController =
                  _treeViewController.copyWith(children: updated);
            });

            OpenFile.open(file.path);
          }
        });
      } else
        OpenFile.open(doc.filePath);
    }
  }

  Future<File> downloadFile(int fileId) async {
    Future.delayed(Duration(seconds: 5));
    return null;
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
