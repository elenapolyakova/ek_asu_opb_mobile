import 'dart:collection';
class Manager {
  Manager._();
  static final Manager manager = Manager._();

  int checkPlanItemId;
  int checkListId;
  int checkListItemId;
  int faultId;
  dynamic args;
  String checkListName;
  String checkListItemName;
  Map<String, dynamic> _screenList = {};
  String selectedPage = '';
  Queue<Map<String, String>> _navigation = Queue<Map<String, String>>();
}
