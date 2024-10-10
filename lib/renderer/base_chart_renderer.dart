import 'package:flutter/material.dart';


abstract class BaseChartRenderer<T> {
  double maxValue, minValue;
  late double scaleY;
  double scaleX;
  double topPadding;
  Rect chartRect;
  int fixedLength;
  Paint chartPaint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.high
    ..strokeWidth = 1.0
    ..color = Colors.red;
  Paint gridPaint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.high
    ..strokeWidth = 0.5
    ..color = Color(0xffE8E8EA);

  BaseChartRenderer({
    required this.chartRect,
    required this.maxValue,
    required this.minValue,
    required this.topPadding,
    required this.fixedLength,
    required Color gridColor,
    required this.scaleX,
  }) {
    if (maxValue == minValue) {
      maxValue *= 1.5;
      minValue /= 2;
    }
    scaleY = (chartRect.height - 10) / (maxValue - minValue);
    gridPaint.color = gridColor;
    // print("maxValue=====" + maxValue.toString() + "====minValue===" + minValue.toString() + "==scaleY==" + scaleY.toString());
  }

  double getY(double y) => (maxValue - y) * scaleY + chartRect.top;

  String format(double? n) {
    if (n == null || n.isNaN) {
      return "0.00";
    } else {
      return n.toStringAsFixed(fixedLength);
    }
  }

  void drawGrid(Canvas canvas, int gridRows, int gridColumns);
  void drawPoints(Canvas canvas, int gridRows, int pointColumns);

  void drawText(Canvas canvas, T data, double x);

  void drawVerticalText(canvas, textStyle, int gridRows);

  void drawChart(T lastPoint, T curPoint, double lastX, double curX, Size size, Canvas canvas);

  void drawLine(double? lastPrice, double? curPrice, Canvas canvas, double lastX, double curX, Color color, [double strokeWidth = 1.0]) {
    if (lastPrice == null || curPrice == null) {
      return;
    }
    //("lasePrice==" + lastPrice.toString() + "==curPrice==" + curPrice.toString());
    double lastY = getY(lastPrice);
    double curY = getY(curPrice);
    //print("lastX-----==" + lastX.toString() + "==lastY==" + lastY.toString() + "==curX==" + curX.toString() + "==curY==" + curY.toString());
    canvas.drawLine(
        Offset(lastX, lastY),
        Offset(curX, curY),
        chartPaint
          ..color = color
          ..strokeWidth = strokeWidth);
  }

  TextStyle getTextStyle(Color color, {double? fontSize = 10}) {
    return TextStyle(fontSize: fontSize, color: color);
  }
}
