import 'dart:convert';
import 'dart:ffi';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {

  LatLng? _currentLocation; // Default to center of the map
  LatLng? _destination; // Randomly generated destination
  List<Polyline> _polylines = [];
  @override

  void initState() {
    // TODO: implement initState
    super.initState();
    _getDeviceLocation();

  }

  Future<void> _getDeviceLocation() async {
    PermissionStatus permissionStatus = await Permission.location.request();
    if (permissionStatus.isGranted) {
      // Location permission granted, proceed to get device location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude); // Update current location
        _generateRandomDestination();
      });

      // Print current location for debugging
      print('CURRENT LOCATION LATITUDE: ${position.latitude}');
      print('CURRENT LOCATION LONGITUDE: ${position.longitude}');
    } else {
      // Location permission denied, handle accordingly
      // For example, display a message to the user or request permission again
    }
  }

  void _generateRandomDestination() {
    // Generate random coordinates within a certain range
    final double minLat = _currentLocation!.latitude - 0.05;
    final double maxLat = _currentLocation!.latitude + 0.05;
    final double minLng = _currentLocation!.longitude - 0.05;
    final double maxLng = _currentLocation!.longitude + 0.05;

    final random = Random();
    final lat = minLat + random.nextDouble() * (maxLat - minLat);
    final lng = minLng + random.nextDouble() * (maxLng - minLng);

    setState(() {
      _destination = LatLng(lat, lng); // Update destination
      // Fetch route between current location and destination
      _getRoute();
    });
  }

  Future<void> _getRoute() async{
    if(_currentLocation!=null && _destination!=null){
      // Construct the OSRM API query to retrieve the route between two points
      final String apiUrl = 'https://router.project-osrm.org/route/v1/driving/${_currentLocation!.longitude},${_currentLocation!.latitude};${_destination!.longitude},${_destination!.latitude}?overview=full&geometries=geojson';

      // Make the HTTP GET request to fetch route data
      http.Response response = await http.get(Uri.parse(apiUrl));
      print('API RESPONSE: ${response.body}');

      if(response.statusCode==200){
        // Parse the response JSON
        Map<String, dynamic> data = json.decode(response.body);
        List<dynamic> coordinates = data['routes'][0]['geometry']['coordinates'];

        // Extract coordinates from the response
        List<LatLng> routeCoords = coordinates.map((coord){
          return LatLng(coord[1], coord[0]);
        }).toList();

        _createMultiColorPolylines(routeCoords);
      }
      else{
        // Handle error if the request fails
        print('Failed to fetch route. Status code: ${response.statusCode}');
      }
    }
  }

  void _createMultiColorPolylines(List<LatLng> routeCoords){
    final List<Color> colors = [Colors.red, Colors.green, Colors.orange];
    final int segmentLength = (routeCoords.length / colors.length).ceil();

    List<Polyline> polylines = [];

    for (int i = 0; i < colors.length; i++) {
      int start = i * segmentLength;
      int end = min((i + 1) * segmentLength, routeCoords.length);

      if (start < end) {
        polylines.add(
          Polyline(
            points: routeCoords.sublist(start, end),
            strokeWidth: 5.0,
            color: colors[i],
          ),
        );
      }
    }

    setState(() {
      _polylines = polylines;
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Maps Demo'),
      ),
      body: _currentLocation == null || _destination == null
          ? Center(child: CircularProgressIndicator()) :FlutterMap(
        options: MapOptions(
            center: _currentLocation! ?? LatLng(0, 0),
            zoom: 14.0,
          onTap: (_, __) => _hidePopup(), // Hide popup when tapping outside
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          PolylineLayer(polylines: _polylines
          ),
          MarkerLayer(markers: [
            if(_currentLocation !=null)
              Marker(
                  width: 40.0,
                  height: 40.0,
                  point: _currentLocation!,
                  child: Builder(
                    builder: (context) {
                      return InkWell(
                        onTap: (){
                          _showPopup(context, _currentLocation!);
                        },
                        child: Icon(
                          Icons.location_on,
                          color: Colors.green,
                        ),
                      );
                    }
                  )
              ),
            if(_destination!=null)
              Marker(
                width: 40.0,
                height: 40.0,
                point: _destination!,
                child: Builder(
                  builder: (context) {
                    return InkWell(
                      onTap: (){
                        _showPopup(context, _destination!);
                      },
                      child: Icon(
                        Icons.location_on,
                        color: Colors.red, // Color of the destination marker
                      ),
                    );
                  }
                ),
              ),
          ])
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _generateRandomDestination();
        },
        tooltip: 'New Destination',
        child: Icon(Icons.location_on),
      ),
    );
  }

  void _showPopup(BuildContext ctx, LatLng location) {
    final popup = AlertDialog(
      title: Text('Location'),
      content: Text('Latitude: ${location.latitude}\nLongitude: ${location.longitude}'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(ctx, rootNavigator: true).pop();
          },
          child: Text('Close'),
        ),
      ],
    );

    showDialog(
      context: ctx,
      builder: (BuildContext context) => popup,
    );
  }

  void _hidePopup() {
    Navigator.of(context, rootNavigator: true).pop();
  }
}

