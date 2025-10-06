import 'package:flutter/material.dart';

import '../models/year_data.dart';

class BoxPlotChart extends StatelessWidget {
  final BoxPlotChartData data;

  const BoxPlotChart(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(double.infinity, 400),
      painter: _BoxPlotPainter(data),
    );
  }
}

class BoxPlotChartData {
  final List<BoxPlotDataSet> boxPlots;
  final double minY;
  final double maxY;

  BoxPlotChartData({
    required this.boxPlots,
    required this.minY,
    required this.maxY,
  });
}

class _BoxPlotPainter extends CustomPainter {
  final BoxPlotChartData data;
  final double boxWidth = 30;
  final double whiskerWidth = 10;

  _BoxPlotPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final fillPaint = Paint()
      ..color = Colors.blue.withAlpha(3)
      ..style = PaintingStyle.fill;

    final outlierPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final textStyle = TextStyle(
      color: Colors.black,
      fontSize: 12,
    );
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Рисуем оси
    _drawAxes(canvas, size, paint, textPainter, textStyle);

    // Рисуем box plots для каждого года
    for (int i = 0; i < data.boxPlots.length; i++) {
      final dataSet = data.boxPlots[i];
      final x = _calculateXPosition(i, data.boxPlots.length, size.width);
      
      _drawBoxPlot(canvas, size, dataSet, x, paint, fillPaint, outlierPaint);
      _drawYearLabel(canvas, x, size, dataSet.year, textPainter, textStyle);
    }
  }

  void _drawAxes(Canvas canvas, Size size, Paint paint, TextPainter textPainter, TextStyle textStyle) {
    // Ось Y
    canvas.drawLine(
      Offset(50, 20),
      Offset(50, size.height - 50),
      paint,
    );

    // Ось X
    canvas.drawLine(
      Offset(40, size.height - 50),
      Offset(size.width - 20, size.height - 50),
      paint,
    );

    // Метки оси Y
    final yInterval = (data.maxY - data.minY) / 5;
    for (int i = 0; i <= 5; i++) {
      final value = data.minY + i * yInterval;
      final y = _calculateYPosition(value, size.height);
      
      canvas.drawLine(
        Offset(45, y),
        Offset(55, y),
        paint,
      );

      textPainter.text = TextSpan(
        text: '${value.toStringAsFixed(0)}M',
        style: textStyle,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(10, y - 8));
    }
  }

  void _drawBoxPlot(Canvas canvas, Size size, BoxPlotDataSet dataSet, double x, 
                   Paint paint, Paint fillPaint, Paint outlierPaint) {
    final height = size.height - 70;

    // Вычисляем Y позиции
    final minY = _calculateYPosition(dataSet.min, height);
    final q1Y = _calculateYPosition(dataSet.q1, height);
    final medianY = _calculateYPosition(dataSet.median, height);
    final q3Y = _calculateYPosition(dataSet.q3, height);
    final maxY = _calculateYPosition(dataSet.max, height);

    // Рисуем усы (whiskers)
    canvas.drawLine(Offset(x, minY), Offset(x, maxY), paint);
    canvas.drawLine(Offset(x - whiskerWidth/2, minY), Offset(x + whiskerWidth/2, minY), paint);
    canvas.drawLine(Offset(x - whiskerWidth/2, maxY), Offset(x + whiskerWidth/2, maxY), paint);

    // Рисуем ящик
    final boxRect = Rect.fromLTRB(
      x - boxWidth/2, q3Y,
      x + boxWidth/2, q1Y
    );
    canvas.drawRect(boxRect, fillPaint);
    canvas.drawRect(boxRect, paint);

    // Рисуем медиану
    canvas.drawLine(
      Offset(x - boxWidth/2, medianY),
      Offset(x + boxWidth/2, medianY),
      paint..strokeWidth = 3
    );

    // Рисуем выбросы
    for (final outlier in dataSet.outliers) {
      final outlierY = _calculateYPosition(outlier, height);
      canvas.drawCircle(Offset(x, outlierY), 3, outlierPaint);
    }
  }

  void _drawYearLabel(Canvas canvas, double x, Size size, String year, 
                     TextPainter textPainter, TextStyle textStyle) {
    textPainter.text = TextSpan(
      text: year,
      style: textStyle,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x - textPainter.width/2, size.height - 35));
  }

  double _calculateXPosition(int index, int total, double width) {
    final padding = 80.0;
    final availableWidth = width - padding * 2;
    return padding + (availableWidth / (total - 1)) * index;
  }

  double _calculateYPosition(double value, double height) {
    final normalizedValue = (value - data.minY) / (data.maxY - data.minY);
    return 20 + (1 - normalizedValue) * (height - 70);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}