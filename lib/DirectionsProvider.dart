import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_webservice/directions.dart';
import "package:google_maps_flutter/google_maps_flutter.dart" as maps;

class DirectionProvider extends ChangeNotifier {
  GoogleMapsDirections directionsApi =
      GoogleMapsDirections(apiKey: 'AIzaSyBISXtDvHMEC1KLC8y4thvH153bVwHIW10');

  Set<maps.Polyline> _route = Set();
  Set<maps.Polyline> get currentRoute => _route;

  findDirections(maps.LatLng from, maps.LatLng to) async {
    Location origin = Location(from.latitude, from.longitude);
    Location destination = Location(to.latitude, to.longitude);
    var result =
        await directionsApi.directionsWithLocation(origin, destination);
    Set<maps.Polyline> newRoute = Set();
    if (result.isOkay) {
      var route = result.routes[0];
      var leg = route.legs[0];

      List<maps.LatLng> points = [];

      leg.steps.forEach((step) {
        points.add(maps.LatLng(step.startLocation.lat, step.startLocation.lng));
        points.add(maps.LatLng(step.endLocation.lat, step.endLocation.lng));
      });

      var line = maps.Polyline(
        points: points,
        polylineId: maps.PolylineId('minha rota'),
        color: Colors.blue,
        width: 4,
      );
      newRoute.add(line);

      _route = newRoute;
      notifyListeners();
    } else {
      print("EOORRRR!!!! ${result.errorMessage} AND ${result.status}");
    }

    print(result);
  }
}
