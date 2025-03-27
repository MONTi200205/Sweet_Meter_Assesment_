import 'package:flutter/material.dart';
import 'dart:math' as math;

class SugarChart extends StatelessWidget {
  final List<Map<String, dynamic>> dailyData;
  final double chartHeight;
  final double chartWidth;
  final bool isLandscape;

  const SugarChart({
    Key? key,
    required this.dailyData,
    required this.chartHeight,
    required this.chartWidth,
    this.isLandscape = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (dailyData.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Container(
      height: chartHeight,
      width: chartWidth,
      child: CustomPaint(
        size: Size(chartWidth, chartHeight),
        painter: SugarChartPainter(
          data: dailyData,
          isLandscape: isLandscape,
        ),
      ),
    );
  }
}

class SugarChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final bool isLandscape;

  SugarChartPainter({
    required this.data,
    this.isLandscape = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double padding = size.width * 0.05;
    final double chartWidth = size.width - (padding * 2);
    final double chartHeight = size.height - (padding * 2);

    // Find max value for scaling
    double maxValue = 0;
    for (var item in data) {
      final value = item['totalSugar'] as double;
      if (value > maxValue) maxValue = value;
    }

    // If all values are 0, set a default max
    if (maxValue == 0) maxValue = 10;

    // Add 20% margin to max for better visualization
    maxValue = maxValue * 1.2;

    // Calculate horizontal spacing between data points
    final barWidth = chartWidth / (data.length * 2);
    final double spacing = chartWidth / data.length;

    // Draw y-axis (vertical)
    final yAxisPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(padding, padding),
      Offset(padding, size.height - padding),
      yAxisPaint,
    );

    // Draw x-axis (horizontal)
    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      yAxisPaint,
    );

    // Draw horizontal gridlines
    final gridLinePaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 0.5;

    final numGridLines = 4;
    for (int i = 1; i <= numGridLines; i++) {
      final y = size.height - padding - ((chartHeight / numGridLines) * i);
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        gridLinePaint,
      );

      // Draw y-axis labels
      final textValue = (maxValue / numGridLines) * i;
      final textPainter = TextPainter(
        text: TextSpan(
          text: textValue.toStringAsFixed(1),
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: isLandscape ? 10 : 8,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(padding - textPainter.width - 5, y - (textPainter.height / 2)),
      );
    }

    // Draw data bars with gradient
    final gradientPaint = Paint();

    for (int i = 0; i < data.length; i++) {
      final value = data[i]['totalSugar'] as double;
      final normalizedHeight = (value / maxValue) * chartHeight;

      final rect = Rect.fromLTWH(
        padding + (spacing * i) + (spacing - barWidth) / 2,
        size.height - padding - normalizedHeight,
        barWidth,
        normalizedHeight,
      );

      // Create a gradient for each bar
      gradientPaint.shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Colors.purple.withOpacity(0.7),
          Colors.pink.withOpacity(0.9),
        ],
        stops: [0.0, 1.0],
      ).createShader(rect);

      // Draw the bar
      final roundedRect = RRect.fromRectAndRadius(rect, Radius.circular(barWidth / 2));
      canvas.drawRRect(roundedRect, gradientPaint);

      // Draw a bar stroke
      final barStrokePaint = Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      canvas.drawRRect(roundedRect, barStrokePaint);

      // Draw data point labels (x-axis)
      final textPainter = TextPainter(
        text: TextSpan(
          text: data[i]['displayDate'],
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: isLandscape ? 10 : 8,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          padding + (spacing * i) + (spacing - textPainter.width) / 2,
          size.height - padding + 5,
        ),
      );

      // Draw value on top of the bar if it fits
      if (normalizedHeight > 20) {
        final valueTextPainter = TextPainter(
          text: TextSpan(
            text: value.toStringAsFixed(1),
            style: TextStyle(
              color: Colors.white,
              fontSize: isLandscape ? 10 : 8,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );
        valueTextPainter.layout();
        valueTextPainter.paint(
          canvas,
          Offset(
            padding + (spacing * i) + (spacing - valueTextPainter.width) / 2,
            size.height - padding - normalizedHeight - valueTextPainter.height - 2,
          ),
        );
      }
    }

    // Draw connecting line
    if (data.length > 1) {
      final linePaint = Paint()
        ..color = Colors.white.withOpacity(0.6)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      final path = Path();

      for (int i = 0; i < data.length; i++) {
        final value = data[i]['totalSugar'] as double;
        final normalizedHeight = (value / maxValue) * chartHeight;

        final x = padding + (spacing * i) + (spacing / 2);
        final y = size.height - padding - normalizedHeight;

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(path, linePaint);

      // Draw data points
      final pointPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      for (int i = 0; i < data.length; i++) {
        final value = data[i]['totalSugar'] as double;
        final normalizedHeight = (value / maxValue) * chartHeight;

        final x = padding + (spacing * i) + (spacing / 2);
        final y = size.height - padding - normalizedHeight;

        // Draw point
        canvas.drawCircle(Offset(x, y), 3, pointPaint);

        // Draw point border
        final borderPaint = Paint()
          ..color = Colors.purple
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

        canvas.drawCircle(Offset(x, y), 3, borderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

// A widget that shows a preview of the chart to make layout design easier
class SugarChartPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final mockData = [
      {'date': '2023-01-01', 'displayDate': '01/01', 'totalSugar': 25.5},
      {'date': '2023-01-02', 'displayDate': '02/01', 'totalSugar': 30.2},
      {'date': '2023-01-03', 'displayDate': '03/01', 'totalSugar': 18.7},
      {'date': '2023-01-04', 'displayDate': '04/01', 'totalSugar': 33.1},
      {'date': '2023-01-05', 'displayDate': '05/01', 'totalSugar': 27.9},
      {'date': '2023-01-06', 'displayDate': '06/01', 'totalSugar': 15.3},
      {'date': '2023-01-07', 'displayDate': '07/01', 'totalSugar': 22.6},
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Chart Preview')),
      body: Center(
        child: Container(
          height: 250,
          padding: EdgeInsets.all(16),
          child: SugarChart(
            dailyData: mockData,
            chartHeight: 250,
            chartWidth: 400,
          ),
        ),
      ),
    );
  }
}