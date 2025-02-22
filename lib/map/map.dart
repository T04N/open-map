import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'map_provider.dart';

final tempRadiusProvider = StateProvider<double>((ref) => 10.0);

class MapScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(locationProvider);
    final myCoordinates = ref.watch(myCoordinatesProvider);
    final searchResults = ref.watch(searchResultsProvider);
    final searchRadius = ref.watch(tempRadiusProvider);
    final mapController = MapController();

    return Scaffold(
      appBar: AppBar(title: const Text("Bản đồ & Tìm kiếm")),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: location,
              initialZoom: 12.0,
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
                    point: location,
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
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.all(10),
              child: Column(
                children: [

                  TextField(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: "Nhập tên thành phố...",
                      suffixIcon: Icon(Icons.search),
                    ),
                    // onChanged: (query) async {
                    //   if (query.isNotEmpty) {
                    //     final results = await ref.read(searchCityProvider(query).future);
                    //     ref.read(searchResultsProvider.notifier).state = results;
                    //   }
                    // },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Flexible(
                          child: GestureDetector(
                            onTap: () => _showCitySelectionBottomSheet(context, ref),
                            child: Row(
                              children: [
                                Icon(Icons.location_on, color: Colors.blue),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    "${searchResults.isNotEmpty ? searchResults.first["name"] : "Chưa chọn"}",
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => _showRadiusSelectionBottomSheet(context, ref),
                          child: Row(
                            children: [
                              Icon(Icons.car_repair_rounded, color: Colors.blue),
                              Text(" ${searchRadius.toStringAsFixed(1)} km"),
                              SizedBox(width: 5),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCitySelectionBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        final searchResults = ref.watch(searchResultsProvider);
        return Column(
          children: [     TextField(
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: "Nhập tên thành phố...",
              suffixIcon: Icon(Icons.search),
            ),
            onChanged: (query) async {
              if (query.isNotEmpty) {
                final results = await ref.read(searchCityProvider(query).future);
                ref.read(searchResultsProvider.notifier).state = results;
              }
            },
          ),
            Container(
              padding: EdgeInsets.all(16),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final city = searchResults[index];
                  return ListTile(
                    leading: Icon(Icons.location_city, color: Colors.blue),
                    title: Text(city["name"]),
                    subtitle: Text("${city["lat"]}, ${city["lon"]}"),
                    onTap: () {
                      ref.read(locationProvider.notifier).state = LatLng(city["lat"], city["lon"]);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showRadiusSelectionBottomSheet(BuildContext context, WidgetRef ref) {
    final searchResults = ref.watch(searchResultsProvider);
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final tempRadius = ref.watch(tempRadiusProvider);
            return Container(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => _showCitySelectionBottomSheet(context, ref),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue, width: 2),
                      ),
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.blue),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              "${searchResults.isNotEmpty ? searchResults.first["name"] : "Chưa chọn"}",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text("Chỉnh Khoảng cách tìm kiếm", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  SizedBox(height: 8),
                  Text(" ${tempRadius.toStringAsFixed(1)} km", style: TextStyle(fontSize: 16)),
                  Row(
                    children: [
                      Text("1 km"),
                      Expanded(
                        child: Slider(
                          value: tempRadius,
                          min: 1,
                          max: 50,
                          divisions: 49,
                          label: "${tempRadius.toStringAsFixed(1)} km",
                          onChanged: (value) {
                            ref.read(tempRadiusProvider.notifier).state = value;
                          },
                        ),
                      ),
                      Text("50 km"),
                    ],
                  ),
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(searchRadiusProvider.notifier).state = ref.read(tempRadiusProvider);
                        Navigator.pop(context);
                      },
                      child: Text("Lưu"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

void main() {
  runApp(ProviderScope(child: MaterialApp(debugShowCheckedModeBanner: false, home: MapScreen())));
}
