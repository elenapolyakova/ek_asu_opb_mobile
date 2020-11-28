import 'dart:io';
import 'package:exif/exif.dart';
import 'package:geolocator/geolocator.dart';

class GeoPoint {
  double latitude;
  double longitude;
  GeoPoint(this.latitude, this.longitude);
}

class Geo {
  Geo._();
  static final Geo geo = Geo._();

  Geolocator _gelocator = new Geolocator();

  Future<GeoPoint> getGeoPoint(String path) async {
    if (await _checkGPSData(path)) return await _exifGPSToGeoPoint(path);
    return geolocatorToGeoPoint();
  }

  Future<GeoPoint> geolocatorToGeoPoint() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (LocationPermission.denied == permission)
      permission = await Geolocator.requestPermission();
    if ([LocationPermission.always, LocationPermission.whileInUse]
        .contains(permission)) {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      return GeoPoint(position.latitude, position.longitude);
    }
    return GeoPoint(null, null);
  }

  Future<bool> _checkGPSData(String path) async {
    Map<String, IfdTag> imgTags =
        await readExifFromBytes(File(path).readAsBytesSync());

    if (imgTags.containsKey('GPS GPSLongitude')) return true;
    // _imgLocation = exifGPSToGeoFirePoint(imgTags);
    return false;
  }

  Future<GeoPoint> _exifGPSToGeoPoint(String path) async {
    Map<String, IfdTag> imgTags =
        await readExifFromBytes(File(path).readAsBytesSync());

    final latitudeValue = imgTags['GPS GPSLatitude']
        .values
        .map<double>(
            (item) => (item.numerator.toDouble() / item.denominator.toDouble()))
        .toList();
    final latitudeSignal = imgTags['GPS GPSLatitudeRef'].printable;

    final longitudeValue = imgTags['GPS GPSLongitude']
        .values
        .map<double>(
            (item) => (item.numerator.toDouble() / item.denominator.toDouble()))
        .toList();
    final longitudeSignal = imgTags['GPS GPSLongitudeRef'].printable;

    double latitude =
        latitudeValue[0] + (latitudeValue[1] / 60) + (latitudeValue[2] / 3600);

    double longitude = longitudeValue[0] +
        (longitudeValue[1] / 60) +
        (longitudeValue[2] / 3600);

    if (latitudeSignal == 'S') latitude = -latitude;
    if (longitudeSignal == 'W') longitude = -longitude;

    return GeoPoint(latitude, longitude);
  }
}
