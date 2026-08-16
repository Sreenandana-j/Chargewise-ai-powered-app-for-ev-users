import 'package:flutter/material.dart';
import 'app.dart';

void main() {
  // Ensures binding is initialized before any platform-channel calls
  // (useful once real APIs / plugins are wired in).
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EvRoutePlannerApp());
}
