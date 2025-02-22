import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class OpenStreetMapScreen extends StatefulWidget {
  const OpenStreetMapScreen({super.key});

  @override
  State<OpenStreetMapScreen> createState() => _OpenStreetMapScreenState();
}

class _OpenStreetMapScreenState extends State<OpenStreetMapScreen> {
  final MapController  _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Map"),
      ),
      body: Stack(
        children: [
          FlutterMap(children: [
            TileLayer(

            )
          ])
        ],
      ),
    );
  }
}
