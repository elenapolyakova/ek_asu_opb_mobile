// import 'package:permission_handler/permission_handler.dart';
// import 'package:multi_image_picker/multi_image_picker.dart';

// Future<bool> checkAndRequestCameraPermissions() async {
//   PermissionStatus permission =
//       await PermissionHandler().checkPermissionStatus(PermissionGroup.camera);
//   if (permission != PermissionStatus.granted) {
//     Map<PermissionGroup, PermissionStatus> permissions =
//         await PermissionHandler().requestPermissions([PermissionGroup.camera]);
//     return permissions[PermissionGroup.camera] == PermissionStatus.granted;
//   } else {
//     return true;
//   }
// }
