import 'package:flutter/material.dart';
import 'screens/population_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Population Analysis',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: PopulationScreen(),
    );
  }
}