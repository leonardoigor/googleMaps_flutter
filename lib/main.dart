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

  LatLng fromPoint = LatLng(-20.345582, -40.426052);
  LatLng endPoint = LatLng(-20.342634, -40.400520);
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

  @override
  void initState() {
    super.initState();

    getCurrentLocation();
  }

  Future getCurrentLocation() async {
    Position geoposition =
        await getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    setState(() {
      latitudeData = geoposition.latitude;
      longitudeData = geoposition.longitude;
    });
    print("LOCATION $geoposition");
  }

  @override
  Widget build(BuildContext contex) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Container(
          height: size.height,
          child: Stack(
            children: [
              buildMap(),
              Positioned(
                width: size.width * .7,
                child: Container(
                  padding: EdgeInsets.fromLTRB(10, 0, 10, 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.circular(20),
                    ),
                    color: Colors.white,
                  ),
                  child: TextField(
                    onSubmitted: searchEddress,
                    autocorrect: true,
                    decoration: InputDecoration(
                      labelText: 'Search',
                    ),
                  ),
                ),
                left: 50,
                top: 30.0,
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
        ));
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
            initialCameraPosition: CameraPosition(
              target: widget.fromPoint,
              zoom: 15,
            ),
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
        bearing: 192.8334901395799,
        target: position,
        tilt: 0,
        zoom: 19.151926040649414);
  }

  Future<void> searchEddress(String eddress) async {
    print("Edressss $eddress");
    List<geo.Location> locations = await locationFromAddress("$eddress");
    setState(() {
      apiProvider.findDirections(LatLng(latitudeData, longitudeData),
          LatLng(locations[0].latitude, locations[0].longitude));
      widget.fromPoint = LatLng(latitudeData, longitudeData);
      widget.endPoint = LatLng(locations[0].latitude, locations[0].longitude);
    });
    print("daskndasonidansndsanas $locations");
    _centerView();
  }

  void _centerView({bool oneMark: false, LatLng pos}) async {
    await _controller.getVisibleRegion();
    if (!oneMark) {
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
      });
    }
  }

  void _onMapCreated(GoogleMapController controller, DirectionProvider api) {
    // api.findDirections(fromPoint, endPoint);
    setState(() {
      _controller = controller;
      // _centerView();
    });
  }

  placemarkFromCoordinates(double d, double e) {}
}
