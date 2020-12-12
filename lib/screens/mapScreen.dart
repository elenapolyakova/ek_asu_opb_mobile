import 'package:ek_asu_opb_mobile/controllers/controllers.dart';
import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:ek_asu_opb_mobile/components/user_location/user_location.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

Marker getMarker(double lat, double lng,
    [IconData icon = Icons.circle,
    Color color = Colors.blue,
    double size = 40]) {
  return Marker(
    width: size,
    height: size,
    point: new LatLng(lat, lng),
    builder: (ctx) => new Container(
      child: Icon(
        icon,
        color: color,
        size: size,
        semanticLabel: 'Text to announce in accessibility modes',
      ),
    ),
  );
}

List<Marker> getMarkers(List<Map<String, double>> latLngArr) {
  return latLngArr
      .map((e) => getMarker(e['latitude'], e['longitude']))
      .toList();
}

class MapScreen extends StatefulWidget {
  final int departmentId;
  final int checkPlanId;

  @override
  MapScreen({this.departmentId, this.checkPlanId});

  @override
  State<MapScreen> createState() => _MapScreen();
}

class _MapScreen extends State<MapScreen> {
  // UserInfo _userInfo;
  bool showLoading = true;
  int departmentId;
  int checkPlanId;
  double lon = 0;
  double lat = 0;
  bool focusOnUser = false;
  LatLng userLocation;

  MapController mapController = MapController();
  UserLocationOptions userLocationOptions;
  List<Marker> markers = [];

  @override
  void initState() {
    super.initState();

    auth.checkLoginStatus(context).then((isLogin) {
      if (isLogin) {
        auth.getUserInfo().then((userInfo) {
          // _userInfo = userInfo;
          departmentId = widget.departmentId;
          checkPlanId = widget.checkPlanId;
          loadData();
        });
      } //isLogin == true
    }); //checkLoginStatus
  }

  Future<void> loadData() async {
    try {
      showLoadingDialog(context);
      setState(() => {});
      Department dep = await DepartmentController.selectById(departmentId);
      bool properCoordinatesFound = false;
      if (dep != null && !(dep.f_coord_e == 0.0 && dep.f_coord_n == 0.0)) {
        if (!(dep.f_coord_e == 0.0 && dep.f_coord_n == 0.0)) {
          lon = dep.f_coord_e;
          lat = dep.f_coord_n;
          properCoordinatesFound = true;
        }
      } else {
        CheckPlan check = await CheckPlanController.selectById(checkPlanId);
        if (check != null) {
          List<CheckPlanItem> items = await check.items;
          items =
              items.where((element) => element.departmentId != null).toList();
          if (items.isNotEmpty) {
            int i = 0;
            while (true) {
              dep = await items[i].department;
              if (i < items.length &&
                  (dep == null || dep.f_coord_e == 0.0 && dep.f_coord_n == 0.0))
                i++;
              else
                break;
            }
            if (dep != null &&
                !(dep.f_coord_e == 0.0 && dep.f_coord_n == 0.0)) {
              lon = dep.f_coord_e;
              lat = dep.f_coord_n;
              properCoordinatesFound = true;
            }
          }
        }
      }
      if (!properCoordinatesFound) {
        focusOnUser = true;
        if (userLocationOptions != null) {
          userLocationOptions.zoomToCurrentLocationOnLoad = true;
        }
        if (mapController != null && userLocation != null) {
          mapController.move(userLocation, 17);
        }
      }
      showLoading = true;
    } catch (e) {} finally {
      hideDialog(context);
      showLoading = false;
      setState(() => {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // You can use the userLocationOptions object to change the properties
    // of UserLocationOptions in runtime
    userLocationOptions = UserLocationOptions(
        updateMapLocationOnPositionChange: false,
        zoomToCurrentLocationOnLoad: focusOnUser, //departmentId == null,
        showMoveToCurrentLocationFloatingActionButton: true,
        context: context,
        mapController: mapController,
        markers: markers,
        locationUpdateIntervalMs: 10000,
        onLocationUpdate: (LatLng latLng) {
          userLocation = latLng;
        });
    return showLoading
        ? Expanded(child: Text(""))
        : Expanded(
            child: Scaffold(
                body: FlutterMap(
            options: MapOptions(
              center: LatLng(lat, lon),
              zoom: 10,
              plugins: [
                UserLocationPlugin(),
                MarkerClusterPlugin(),
              ],
              maxZoom: 10,
              // minZoom: 8,
            ),
            layers: [
              TileLayerOptions(
                // urlTemplate:
                // "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                // subdomains: ['a', 'b', 'c'],
                urlTemplate: "http://172.22.3.173/russia/map/{z}/{x}/{y}.png",
              ),
              MarkerLayerOptions(markers: markers),
              userLocationOptions,
              MarkerClusterLayerOptions(
                maxClusterRadius: 120,
                size: Size(40, 40),
                fitBoundsOptions: FitBoundsOptions(
                  padding: EdgeInsets.all(50),
                ),
                markers: getMarkers([
                  {'latitude': lat, 'longitude': lon},
                ]),
                polygonOptions: PolygonOptions(
                    borderColor: Colors.blueAccent,
                    color: Colors.black12,
                    borderStrokeWidth: 3),
                builder: (context, markers) {
                  return FloatingActionButton(
                    child: Text(markers.length.toString()),
                    onPressed: null,
                  );
                },
              ),
            ],
            mapController: mapController,
          )));
  }
}
