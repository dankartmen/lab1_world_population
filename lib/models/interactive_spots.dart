import 'package:fl_chart/fl_chart.dart';

class InteractiveSpot {
  final ScatterSpot spot;
  final String countryName;
  final double area;
  final double growthRate;
  final double population;

  InteractiveSpot({
    required this.spot,
    required this.countryName,
    required this.area,
    required this.growthRate,
    required this.population,
  });
}