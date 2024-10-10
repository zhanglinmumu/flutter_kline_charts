import 'dart:ui';

import 'package:flutter/material.dart';

import '../bean/index.dart';
import '../charts/chart_style.dart';
import '../utils/enums.dart';
import 'base_chart_renderer.dart';

class SecondaryRenderer extends BaseChartRenderer<MACDEntity> {
  late double mMACDWidth;
  SecondaryState state;
  final ChartStyle chartStyle;
  final ChartColors chartColors;

  SecondaryRenderer(Rect mainRect, double maxValue, double minValue, double topPadding, this.state, int fixedLength, this.chartStyle, this.chartColors, double scaleX)
      : super(
          chartRect: mainRect,
          maxValue: maxValue,
          minValue: minValue,
          topPadding: topPadding,
          fixedLength: fixedLength,
          gridColor: chartColors.gridColor,
          scaleX: scaleX,
        ) {
    mMACDWidth = chartStyle.candleWidth;
  }

  @override
  void drawChart(MACDEntity lastPoint, MACDEntity curPoint, double lastX, double curX, Size size, Canvas canvas) {
    switch (state) {
      case SecondaryState.MACD:
        drawMACD(curPoint, canvas, curX, lastPoint, lastX);
        break;
      case SecondaryState.KDJ:
        drawLine(lastPoint.k, curPoint.k, canvas, lastX, curX, chartColors.kColor);
        drawLine(lastPoint.d, curPoint.d, canvas, lastX, curX, chartColors.dColor);
        drawLine(lastPoint.j, curPoint.j, canvas, lastX, curX, chartColors.jColor);
        break;
      case SecondaryState.RSI:
        drawLine(lastPoint.rsi, curPoint.rsi, canvas, lastX, curX, chartColors.rsiColor);
        break;
      case SecondaryState.WR:
        drawLine(lastPoint.r, curPoint.r, canvas, lastX, curX, chartColors.rsiColor);
        break;
      case SecondaryState.CCI:
        drawLine(lastPoint.cci, curPoint.cci, canvas, lastX, curX, chartColors.rsiColor);
        break;
      default:
        break;
    }
  }

  void drawMACD(MACDEntity curPoint, Canvas canvas, double curX, MACDEntity lastPoint, double lastX) {
    final macd = curPoint.macd ?? 0;
    double macdY = getY(macd);
    double r = mMACDWidth / 2 * scaleX;
    double zeroy = getY(0);
    if (macd > 0) {
      if (curPoint.macd!.abs() > lastPoint.macd!.abs()) {
        chartPaint.style = PaintingStyle.stroke;
        // chartPaint.strokeWidth = 0.5 / scaleX;
        canvas.drawLine(
            Offset(curX - r, macdY),
            Offset(curX - r, zeroy),
            chartPaint
              ..color = chartColors.secUpColor
              ..strokeWidth = 0.5);
        canvas.drawLine(
            Offset(curX + r, macdY),
            Offset(curX + r, zeroy),
            chartPaint
              ..color = chartColors.secUpColor
              ..strokeWidth = 0.5);
        canvas.drawLine(
            Offset(curX - r, macdY),
            Offset(curX + r, macdY),
            chartPaint
              ..color = chartColors.secUpColor
              ..strokeWidth = 0.5);
        canvas.drawLine(
            Offset(curX + r, zeroy),
            Offset(curX - r, zeroy),
            chartPaint
              ..color = chartColors.secUpColor
              ..strokeWidth = 0.5);
      } else {
        chartPaint.style = PaintingStyle.fill;
        canvas.drawRect(Rect.fromLTRB(curX - r, macdY, curX + r, zeroy), chartPaint..color = chartColors.secUpColor);
        // canvas.drawRRect(RRect.fromLTRBXY(curX - r, macdY, curX + r, zeroy, 1 / scaleX, 1), chartPaint..color = chartColors.secUpColor);
      }
    } else {
      // canvas.drawRect(Rect.fromLTRB(curX - r, zeroy, curX + r, macdY), chartPaint..color = chartColors.secDnColor);
      canvas.drawRRect(RRect.fromLTRBXY(curX - r, zeroy, curX + r, macdY, 0.5, 0.5), chartPaint..color = chartColors.secDnColor);
    }
    if (lastPoint.dif != 0) {
      drawLine(lastPoint.dif, curPoint.dif, canvas, lastX, curX, chartColors.difColor);
    }
    if (lastPoint.dea != 0) {
      drawLine(lastPoint.dea, curPoint.dea, canvas, lastX, curX, chartColors.deaColor);
    }
  }

  @override
  void drawText(Canvas canvas, MACDEntity data, double x) {
    List<TextSpan>? children;
    switch (state) {
      case SecondaryState.MACD:
        children = [
          TextSpan(text: "MACD(12,26,9)    ", style: getTextStyle(chartColors.defaultTextColor)),
          if (data.macd != 0) TextSpan(text: "MACD:${format(data.macd)}    ", style: getTextStyle(chartColors.macdColor)),
          if (data.dif != 0) TextSpan(text: "DIF:${format(data.dif)}    ", style: getTextStyle(chartColors.difColor)),
          if (data.dea != 0) TextSpan(text: "DEA:${format(data.dea)}    ", style: getTextStyle(chartColors.deaColor)),
        ];
        break;
      case SecondaryState.KDJ:
        children = [
          TextSpan(text: "KDJ(9,1,3)    ", style: getTextStyle(chartColors.defaultTextColor)),
          if (data.macd != 0) TextSpan(text: "K:${format(data.k)}    ", style: getTextStyle(chartColors.kColor)),
          if (data.dif != 0) TextSpan(text: "D:${format(data.d)}    ", style: getTextStyle(chartColors.dColor)),
          if (data.dea != 0) TextSpan(text: "J:${format(data.j)}    ", style: getTextStyle(chartColors.jColor)),
        ];
        break;
      case SecondaryState.RSI:
        children = [
          TextSpan(text: "RSI(14):${format(data.rsi)}    ", style: getTextStyle(this.chartColors.rsiColor)),
        ];
        break;
      case SecondaryState.WR:
        children = [
          TextSpan(text: "WR(14):${format(data.r)}    ", style: getTextStyle(this.chartColors.rsiColor)),
        ];
        break;
      case SecondaryState.CCI:
        children = [
          TextSpan(text: "CCI(14):${format(data.cci)}    ", style: getTextStyle(this.chartColors.rsiColor)),
        ];
        break;
      default:
        break;
    }
    TextPainter tp = TextPainter(text: TextSpan(children: children ?? []), textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, Offset(x, chartRect.top - topPadding));

    var lpt = Paint()
      // ..color = Colors.red
      ..color = Color(0xFF6C717F).withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, chartRect.top - topPadding), Offset(chartRect.width, chartRect.top - topPadding), lpt);
  }

  @override
  void drawVerticalText(canvas, textStyle, int gridRows) {
    TextPainter maxTp = TextPainter(text: TextSpan(text: "${format(maxValue)}", style: textStyle), textDirection: TextDirection.ltr);
    maxTp.layout();
    TextPainter minTp = TextPainter(text: TextSpan(text: "${format(minValue)}", style: textStyle), textDirection: TextDirection.ltr);
    minTp.layout();

    maxTp.paint(canvas, Offset(chartRect.width - maxTp.width, chartRect.top - topPadding));
    minTp.paint(canvas, Offset(chartRect.width - minTp.width, chartRect.bottom - minTp.height));
  }

  @override
  void drawGrid(Canvas canvas, int gridRows, int gridColumns) {
    // canvas.drawLine(Offset(0, chartRect.top), Offset(chartRect.width, chartRect.top), gridPaint);
    // canvas.drawLine(Offset(0, chartRect.bottom), Offset(chartRect.width, chartRect.bottom), gridPaint);
    double columnSpace = chartRect.width / gridColumns;
    for (int i = 0; i <= columnSpace; i++) {
      //mSecondaryRect垂直线
      canvas.drawLine(Offset(columnSpace * i, chartRect.top - topPadding), Offset(columnSpace * i, chartRect.bottom), gridPaint);
    }
  }

  @override
  void drawPoints(Canvas canvas, int gridRows, int pointColumns) {}
}
