import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';
////////////////////////////////////////////////////////
import 'package:user_location/user_location.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

class MapScreen extends StatefulWidget {
  int departmentId;
  int checkPlanId;

  @override
  MapScreen({this.departmentId, this.checkPlanId});

  @override
  State<MapScreen> createState() => _MapScreen();
}

class _MapScreen extends State<MapScreen> {
  UserInfo _userInfo;
  bool showLoading = true;
  int departmentId;
  int checkPlanId;

  // ADD THIS
  MapController mapController = MapController();
  UserLocationOptions userLocationOptions;
  // ADD THIS
  List<Marker> markers = [];

  @override
  void initState() {
    super.initState();

    auth.checkLoginStatus(context).then((isLogin) {
      if (isLogin) {
        auth.getUserInfo().then((userInfo) {
          _userInfo = userInfo;
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
      setState(() => {showLoading = true});
      //<-----сюда вставить загрузку данных

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
      context: context,
      mapController: mapController,
      markers: markers,
    );
    return 
     showLoading
            ? Expanded(child: Text("")) :

    Expanded(
        child: Scaffold(
            appBar: AppBar(title: Text("User Location Plugin")),
            body: FlutterMap(
              options: MapOptions(
                center: LatLng(0, 0),
                zoom: 15.0,
                plugins: [
                  // ADD THIS
                  UserLocationPlugin(),
                ],
              ),
              layers: [
                /* vasvas 21nov20
                TileLayerOptions(
                  urlTemplate: "https://api.tiles.mapbox.com/v4/"
                      "{id}/{z}/{x}/{y}@2x.png?access_token={accessToken}",
                  additionalOptions: {
                    'accessToken':
                        'pk.eyJ1IjoidmFzdmFzIiwiYSI6ImNraHFha3FmcDFpemUzOG14Y25jYzQxdDAifQ.ZobEXR5Lq9mfXfSs28dh6A',
                    'id': 'mapbox.streets',
                  },
                ),
                */
                TileLayerOptions(
                  urlTemplate: "https://api.mapbox.com/styles/v1/"
                      "{id}/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}",
                  additionalOptions: {
                    'accessToken':
                        'pk.eyJ1IjoidmFzdmFzIiwiYSI6ImNraHFha3FmcDFpemUzOG14Y25jYzQxdDAifQ.ZobEXR5Lq9mfXfSs28dh6A',
                    'id': 'mapbox/streets-v8',
                  },
                ),

                // ADD THIS
                MarkerLayerOptions(markers: markers),
                // ADD THIS
                userLocationOptions,
              ],
              // ADD THIS
              mapController: mapController,
            )));
  }
}
