import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapController mapController = MapController();
  LatLng selectedLocation = LatLng(16.0471, 108.2060);
  double searchRadius = 10.0;
  TextEditingController searchController = TextEditingController();
  String? myCoordinates;
  List<Map<String, dynamic>> searchResults = [];
  List<Map<String, dynamic>> nearbyPlaces = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      selectedLocation = LatLng(position.latitude, position.longitude);
      myCoordinates = "Tọa độ của bạn: (${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)})";
    });
    _fetchNearbyPlaces();
  }

  Future<void> _searchCity(String query) async {
    final url = Uri.parse("https://nominatim.openstreetmap.org/search?format=json&q=$query&accept-language=utf-8");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      setState(() {
        searchResults = data.map((item) {
          return {
            "name": item["display_name"],
            "lat": double.parse(item["lat"]),
            "lon": double.parse(item["lon"]),
          };
        }).toList();
      });
    }
  }

  void moveToLocation(double lat, double lon) {
    setState(() {
      selectedLocation = LatLng(lat, lon);
    });
    mapController.move(LatLng(lat, lon), 12.0);
    _fetchNearbyPlaces();
  }

  Future<void> _fetchNearbyPlaces() async {
    final url = Uri.parse("https://overpass-api.de/api/interpreter");
    final query = """
    [out:json];
    node
      ["place"~"city|town|village"]
      (around:${(searchRadius * 1000).toInt()},${selectedLocation.latitude},${selectedLocation.longitude});
    out body;
    """;

    final response = await http.post(url, body: {"data": query});

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        nearbyPlaces = (data["elements"] as List).map((item) {
          return {
            "name": item["tags"]["name"] ?? "Không có tên",
            "lat": item["lat"],
            "lon": item["lon"],
          };
        }).toList();
      });
    }
  }

  void _updateRadius(double newRadius) {
    setState(() {
      searchRadius = newRadius;
    });
    _fetchNearbyPlaces();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bản đồ & Tìm kiếm")),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: selectedLocation,
              initialZoom: 6.0,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 40.0,
                    height: 40.0,
                    point: selectedLocation,
                    child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: [
                  if (myCoordinates != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(myCoordinates!, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                    ),
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Nhập tên thành phố...",
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          _searchCity(searchController.text);
                        },
                      ),
                    ),
                  ),
                  if (searchResults.isNotEmpty)
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final city = searchResults[index];
                          return ListTile(
                            title: Text(city["name"]),
                            onTap: () {
                              moveToLocation(city["lat"], city["lon"]);
                              searchController.clear();
                              setState(() {
                                searchResults.clear();
                              });
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 10,
            right: 10,
            child: Column(
              children: [
                Text("Bán kính: ${searchRadius.toStringAsFixed(1)} km"),
                Slider(
                  value: searchRadius,
                  min: 1,
                  max: 50,
                  divisions: 49,
                  label: "${searchRadius.toStringAsFixed(1)} km",
                  onChanged: _updateRadius,
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 300,
            left: 10,
            right: 10,
            child: Container(
              height: 200,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: ListView.builder(
                itemCount: nearbyPlaces.length,
                itemBuilder: (context, index) {
                  final place = nearbyPlaces[index];
                  return ListTile(
                    title: Text(utf8.decode(place["na"
                        "me"].runes.toList())),
                    onTap: () {
                      moveToLocation(place["lat"], place["lon"]);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}