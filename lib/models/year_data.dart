import 'dart:math';

import 'population_data.dart';

class YearData {
  final String year;
  final double? Function(PopulationData) extractor;

  YearData(this.year, this.extractor);
}

class BoxPlotDataSet {
  final String year;
  final List<double> values;
  final double min;
  final double q1;
  final double median;
  final double q3;
  final double max;
  final List<double> outliers;

  BoxPlotDataSet(this.year, this.values)
      : min = _calculateMin(values),
        q1 = _calculateQuantile(values, 0.25),
        median = _calculateQuantile(values, 0.5),
        q3 = _calculateQuantile(values, 0.75),
        max = _calculateMax(values),
        outliers = _calculateOutliers(values);
}
double _calculateMin(List<double> values) {
  if (values.isEmpty) return 0;
  return values.first;
}

double _calculateMax(List<double> values) {
  if (values.isEmpty) return 0;
  return values.last;
}

double _calculateQuantile(List<double> values, double quantile) {
  if (values.isEmpty) return 0;
  
  final index = (values.length * quantile).floor();
  return values[index.clamp(0, values.length - 1)];
}

List<double> _calculateOutliers(List<double> values) {
  if (values.length < 4) return [];
  
  final q1 = _calculateQuantile(values, 0.25);
  final q3 = _calculateQuantile(values, 0.75);
  final iqr = q3 - q1;
  final lowerBound = q1 - 1.5 * iqr;
  final upperBound = q3 + 1.5 * iqr;
  
  return values.where((value) => value < lowerBound || value > upperBound).toList();
}

