import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mapteste2/DirectionsProvider.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DirectionProvider(),
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: MyHomePage(title: 'google map teste'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  LatLng fromPoint = LatLng(0, 0);
  LatLng endPoint = LatLng(0, 0);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  GoogleMapController _controller;
  double latitudeData = 0;
  double longitudeData = 0;
  Set<Marker> tmp = Set<Marker>();
  DirectionProvider apiProvider;
  bool init = true;
  bool mapHasCreated = false;

  @override
  void initState() {
    super.initState();
    getCurrentLocation();

    Timer.periodic(new Duration(seconds: 1), (timer) {
      getCurrentLocation(realTime: true);
    });
  }

  Future getCurrentLocation({bool realTime: false}) async {
    Position geoposition =
        await getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    setState(() {
      latitudeData = geoposition.latitude;
      longitudeData = geoposition.longitude;
    });
    // _centerView(oneMark: true, pos: LatLng(latitudeData, longitudeData));

    if (realTime) {
      print('realTime');
      _createMarkers(Marker(
        markerId: MarkerId('My locations'),
        position: LatLng(geoposition.latitude, geoposition.longitude),
      ));
    }
    if (init) {
      print('init');
      setState(() {
        init = false;
        _centerView(oneMark: true, pos: LatLng(latitudeData, longitudeData));
      });
    }
  }

  @override
  Widget build(BuildContext contex) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        height: size.height,
        child: Stack(
          alignment: AlignmentDirectional.bottomEnd,
          children: <Widget>[
            buildMap(),
            DraggableScrollableSheet(
              maxChildSize: 1,
              initialChildSize: 0.97,
              minChildSize: 0.03,
              builder:
                  (BuildContext context, ScrollController scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  child: Container(
                    height: MediaQuery.of(context).size.height,
                    color: Colors.white,
                    child: Text("$latitudeData -- $longitudeData"),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FloatingActionButton(
              onPressed: _centerView,
              child: Icon(
                Icons.zoom_out_map,
              ),
            ),
            FloatingActionButton(
              onPressed: () => _centerView(
                  oneMark: true, pos: LatLng(latitudeData, longitudeData)),
              child: Icon(
                Icons.my_location,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Consumer<DirectionProvider> buildMap() {
    return Consumer<DirectionProvider>(
      builder: (BuildContext ctx, DirectionProvider api, Widget child) {
        DirectionProvider api = Provider.of<DirectionProvider>(context);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            apiProvider = api;
          });
        });

        return Container(
          height: MediaQuery.of(ctx).size.height,
          child: GoogleMap(
            initialCameraPosition:
                CameraPosition(target: widget.fromPoint, zoom: 15, bearing: 0),
            markers: tmp,
            onMapCreated: (GoogleMapController _googleControler) =>
                _onMapCreated(_googleControler, api),
            polylines: api.currentRoute,
          ),
        );
      },
    );
  }

  void _createMarkers(Marker marks) {
    setState(() {
      tmp.add(marks);
    });
  }

  static CameraPosition _kLake(LatLng position) {
    return CameraPosition(
        bearing: 0, target: position, tilt: 0, zoom: 19.151926040649414);
  }

  Future<void> searchEddress(String eddress) async {
    List<geo.Location> locations = await locationFromAddress("$eddress");
    setState(() {
      apiProvider.findDirections(LatLng(latitudeData, longitudeData),
          LatLng(locations[0].latitude, locations[0].longitude));
      widget.fromPoint = LatLng(latitudeData, longitudeData);
      widget.endPoint = LatLng(locations[0].latitude, locations[0].longitude);
    });
  }

  void _centerView({bool oneMark: false, LatLng pos}) async {
    print('center');
    if (mapHasCreated) {
      await _controller.getVisibleRegion();
      if (!oneMark) {
        print('moreMarks');
        double left = min(widget.fromPoint.latitude, widget.endPoint.latitude);
        double right = max(widget.fromPoint.latitude, widget.endPoint.latitude);
        double top = max(widget.fromPoint.longitude, widget.endPoint.longitude);
        double bottom =
            min(widget.fromPoint.longitude, widget.endPoint.longitude);
        LatLngBounds bounds = LatLngBounds(
          southwest: LatLng(left, bottom),
          northeast: LatLng(right, top),
        );
        var cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 50);
        _controller.animateCamera(cameraUpdate);
      } else {
        getCurrentLocation().then((value) {
          var cameraUpdate = CameraUpdate.newCameraPosition(_kLake(pos));
          _controller.animateCamera(cameraUpdate);
          _createMarkers(Marker(
            markerId: MarkerId('My locations'),
            position: pos,
          ));
          print('oneeee');
        }).catchError((err) {
          print('erro');
        });
      }
    }
  }

  void _onMapCreated(GoogleMapController controller, DirectionProvider api) {
    // api.findDirections(fromPoint, endPoint);
    setState(() {
      _controller = controller;
      mapHasCreated = true;
    });
    _centerView(oneMark: true, pos: LatLng(latitudeData, longitudeData));
  }

  placemarkFromCoordinates(double d, double e) {}
}
