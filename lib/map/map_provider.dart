import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final locationProvider = StateProvider<LatLng>((ref) => LatLng(16.0471, 108.2060));

final myCoordinatesProvider = FutureProvider<String>((ref) async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return "Không thể lấy tọa độ";
  }

  Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  ref.read(locationProvider.notifier).state = LatLng(position.latitude, position.longitude);
  return "Tọa độ của bạn: (${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)})";
});

final searchResultsProvider = StateProvider<List<Map<String, dynamic>>>((ref) => []);

final searchRadiusProvider = StateProvider<double>((ref) => 10.0);

final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(baseUrl: "https://nominatim.openstreetmap.org"));
});

final searchCityProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, query) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get("/search", queryParameters: {
    "format": "json",
    "q": query,
    "featuretype": "city", // Giới hạn tìm kiếm ở thành phố
    "accept-language": "utf-8"
  });

  if (response.statusCode == 200) {
    return (response.data as List).map((item) {
      return {
        "name": item["display_name"],
        "lat": double.parse(item["lat"]),
        "lon": double.parse(item["lon"]),
      };
    }).toList();
  }
  return [];
});