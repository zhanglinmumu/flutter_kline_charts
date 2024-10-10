import 'dart:ui';

import 'package:flutter/material.dart';

import '../bean/index.dart';
import '../charts/chart_style.dart';
import '../utils/number_util.dart';
import 'base_chart_renderer.dart';

class VolRenderer extends BaseChartRenderer<VolumeEntity> {
  late double mVolWidth;
  final ChartStyle chartStyle;
  final ChartColors chartColors;

  // final double scaleX;
  final double paddingTop = 15; //上高,vol柱高

  VolRenderer(Rect mainRect, double maxValue, double minValue, double topPadding, int fixedLength, this.chartStyle, this.chartColors, double scaleX)
      : super(
          chartRect: mainRect,
          maxValue: maxValue,
          minValue: minValue,
          topPadding: topPadding,
          fixedLength: fixedLength,
          gridColor: chartColors.gridColor,
          scaleX: scaleX,
        ) {
    mVolWidth = chartStyle.candleWidth;
  }

  @override
  void drawChart(VolumeEntity lastPoint, VolumeEntity curPoint, double lastX, double curX, Size size, Canvas canvas) {
    double r = mVolWidth / 2 * scaleX;
    double top = getVolY(curPoint.vol);
    double bottom = chartRect.bottom;
    if (curPoint.vol != 0) {
      var color = curPoint.close > curPoint.open ? this.chartColors.secUpColor : this.chartColors.secDnColor;
      canvas.drawRRect(
          RRect.fromLTRBXY(curX - r, top, curX + r, bottom, chartStyle.volRadius, 1),
          // RRect.fromLTRBR(curX - r, top, curX + r, bottom, Radius.circular(1)),
          chartPaint..color = color);
    }

    if (lastPoint.MA5Volume != 0) {
      drawLine(lastPoint.MA5Volume, curPoint.MA5Volume, canvas, lastX, curX, this.chartColors.vol5Color);
    }

    if (lastPoint.MA10Volume != 0) {
      drawLine(lastPoint.MA10Volume, curPoint.MA10Volume, canvas, lastX, curX, this.chartColors.vol10Color);
    }
  }

  double getVolY(double value) => (maxValue - value) * ((chartRect.height - paddingTop) / maxValue) + chartRect.top + paddingTop;

  @override
  void drawText(Canvas canvas, VolumeEntity data, double x) {
    TextSpan span = TextSpan(
      children: [
        TextSpan(text: "VOL:${NumberUtil.format(data.vol)}    ", style: getTextStyle(this.chartColors.volColor)),
        if ((data.MA5Volume ?? 0) > 0) TextSpan(text: "MA5:${NumberUtil.format(data.MA5Volume!)}    ", style: getTextStyle(this.chartColors.vol5Color)),
        if ((data.MA10Volume ?? 0) > 0) TextSpan(text: "MA10:${NumberUtil.format(data.MA10Volume!)}    ", style: getTextStyle(this.chartColors.vol10Color)),
      ],
    );
    TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, Offset(x, chartRect.top - topPadding));
  }

  @override
  void drawVerticalText(canvas, textStyle, int gridRows) {
    TextSpan span = TextSpan(text: "${NumberUtil.format(maxValue)}", style: textStyle);
    TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, Offset(chartRect.width - tp.width, chartRect.top - topPadding));
  }

  @override
  void drawGrid(Canvas canvas, int gridRows, int gridColumns) {
    canvas.drawLine(Offset(0, chartRect.bottom), Offset(chartRect.width, chartRect.bottom), gridPaint);
    double columnSpace = chartRect.width / gridColumns;
    for (int i = 0; i <= columnSpace; i++) {
      //vol垂直线
      canvas.drawLine(Offset(columnSpace * i, chartRect.top - topPadding), Offset(columnSpace * i, chartRect.bottom), gridPaint);
    }
  }

  @override
  void drawPoints(Canvas canvas, int gridRows, int pointColumns) {}
}
