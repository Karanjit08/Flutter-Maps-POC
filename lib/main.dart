import 'package:flutter/material.dart';
import 'package:flutter_maps_poc/pages/map_page.dart';

void main(){
  runApp(flutterApp());
}

class flutterApp extends StatelessWidget {
  const flutterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MapPage(),
    );
  }
}
