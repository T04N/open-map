import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_street_map/main_non_state.dart';

import 'map/map.dart';

void main() {
  runApp(ProviderScope(child: MaterialApp(debugShowCheckedModeBanner: false, home: MapScreen())));
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