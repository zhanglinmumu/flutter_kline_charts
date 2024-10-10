import 'dart:ui';

import 'package:flutter/material.dart';

import '../bean/index.dart';
import '../charts/chart_style.dart';
import '../utils/enums.dart';
import 'base_chart_renderer.dart';

enum VerticalTextAlignment { left, right }

//For TrendLine
double? trendLineMax;
double? trendLineScale;
double? trendLineContentRec;

class MainRenderer extends BaseChartRenderer<CandleEntity> {
  late double mCandleWidth;
  late double mCandleLineWidth;
  MainState state;
  bool isLine;
  bool showLineShader;
  bool showTopDiv;

  //绘制的内容区域
  late Rect _contentRect;
  final double _contentPadding = 5.0;
  List<int> maDayList;
  final ChartStyle chartStyle;
  final ChartColors chartColors;
  final double mLineStrokeWidth = 2.0;
  // double scaleX;
  late Paint mLinePaint;
  final VerticalTextAlignment verticalTextAlignment;
  double indexPadding = 0;

  MainRenderer(
      Rect mainRect, double maxValue, double minValue, double topPadding, this.state, this.isLine, int fixedLength, this.chartStyle, this.chartColors, double scaleX, this.verticalTextAlignment,
      [this.maDayList = const [5, 10, 20], this.indexPadding = 0, this.showLineShader = true, this.showTopDiv = true])
      : super(chartRect: mainRect, maxValue: maxValue, minValue: minValue, topPadding: topPadding, fixedLength: fixedLength, gridColor: chartColors.gridColor, scaleX: scaleX) {
    mCandleWidth = chartStyle.candleWidth;
    mCandleLineWidth = chartStyle.candleLineWidth;
    mLinePaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = mLineStrokeWidth
      ..color = this.chartColors.kLineColor;
    _contentRect = Rect.fromLTRB(chartRect.left, chartRect.top + _contentPadding, chartRect.right, chartRect.bottom - _contentPadding);
    if (maxValue == minValue) {
      maxValue *= 1.5;
      minValue /= 2;
    }
    scaleY = _contentRect.height / (maxValue - minValue);
  }

  @override
  void drawText(Canvas canvas, CandleEntity data, double x) {
    if (isLine == true) return;
    TextSpan? span;
    if (state == MainState.MA) {
      span = TextSpan(
        children: _createMATextSpan(data),
      );
    } else if (state == MainState.BOLL) {
      span = TextSpan(
        children: [
          if (data.up != 0) TextSpan(text: "BOLL:${format(data.mb)}    ", style: getTextStyle(chartColors.ma5Color)),
          if (data.mb != 0) TextSpan(text: "UB:${format(data.up)}    ", style: getTextStyle(chartColors.ma10Color)),
          if (data.dn != 0) TextSpan(text: "LB:${format(data.dn)}    ", style: getTextStyle(chartColors.ma30Color)),
        ],
      );
    }
    if (span == null) return;
    TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, Offset(x + 15, chartRect.top - topPadding + indexPadding));

    var lpt = Paint()
    // ..color = Colors.red
      ..color = Color(0xFF6C717F).withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    if (showTopDiv) canvas.drawLine(Offset(0, 16 + indexPadding), Offset(chartRect.width, 16 + indexPadding), lpt);
  }

  List<InlineSpan> _createMATextSpan(CandleEntity data) {
    List<InlineSpan> result = [];
    for (int i = 0; i < (data.maValueList?.length ?? 0); i++) {
      if (data.maValueList?[i] != 0) {
        var item = TextSpan(text: "MA${maDayList[i]}:${format(data.maValueList![i])}    ", style: getTextStyle(this.chartColors.getMAColor(i)));
        result.add(item);
      }
    }
    return result;
  }

  @override
  void drawChart(CandleEntity lastPoint, CandleEntity curPoint, double lastX, double curX, Size size, Canvas canvas) {
    if (isLine) {
      drawPolyline(lastPoint.close, curPoint.close, canvas, lastX, curX);
    } else {
      drawCandle(curPoint, canvas, curX);
      if (state == MainState.MA) {
        drawMaLine(lastPoint, curPoint, canvas, lastX, curX);
      } else if (state == MainState.BOLL) {
        drawBollLine(lastPoint, curPoint, canvas, lastX, curX);
      }
    }
  }

  Shader? mLineFillShader;
  Path? mLinePath, mLineFillPath;
  Paint mLineFillPaint = Paint()
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  //画折线图
  drawPolyline(double lastPrice, double curPrice, Canvas canvas, double lastX, double curX) {
//    drawLine(lastPrice + 100, curPrice + 100, canvas, lastX, curX, ChartColors.kLineColor);
    mLinePath ??= Path();

//    if (lastX == curX) {
//      mLinePath.moveTo(lastX, getY(lastPrice));
//    } else {
////      mLinePath.lineTo(curX, getY(curPrice));
//      mLinePath.cubicTo(
//          (lastX + curX) / 2, getY(lastPrice), (lastX + curX) / 2, getY(curPrice), curX, getY(curPrice));
//    }
    if (lastX == curX) lastX = 0; //起点位置填充
    mLinePath!.moveTo(lastX, getY(lastPrice));
    mLinePath!.cubicTo((lastX + curX) / 2, getY(lastPrice), (lastX + curX) / 2, getY(curPrice), curX, getY(curPrice));

    //画阴影
    mLineFillShader ??= LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      tileMode: TileMode.clamp,
      colors: [chartColors.lineFillColor, chartColors.lineFillInsideColor],
    ).createShader(Rect.fromLTRB(chartRect.left, chartRect.top, chartRect.right, chartRect.bottom));
    mLineFillPaint.shader = mLineFillShader;

    mLineFillPath ??= Path();

    mLineFillPath!.moveTo(lastX, chartRect.height + chartRect.top);
    if (showLineShader) {
      mLineFillPath!.lineTo(lastX, getY(lastPrice));
      mLineFillPath!.cubicTo((lastX + curX) / 2, getY(lastPrice), (lastX + curX) / 2, getY(curPrice), curX, getY(curPrice));
      mLineFillPath!.lineTo(curX, chartRect.height + chartRect.top);
    } else {
      mLineFillPaint.style = PaintingStyle.stroke;
      mLineFillPaint.strokeWidth = 1 / scaleX;
      mLineFillPaint.shader = null;
    }
    mLineFillPath!.close();

    canvas.drawPath(mLineFillPath!, mLineFillPaint);
    mLineFillPath!.reset();

    canvas.drawPath(mLinePath!, mLinePaint..strokeWidth = ((showLineShader ? 1 : mLineStrokeWidth))); // / scaleX).clamp(0.1, 2.0));
    mLinePath!.reset();
  }

  void drawMaLine(CandleEntity lastPoint, CandleEntity curPoint, Canvas canvas, double lastX, double curX) {
    for (int i = 0; i < (curPoint.maValueList?.length ?? 0); i++) {
      if (i == 3) {
        break;
      }
      if (lastPoint.maValueList?[i] != 0) {
        drawLine(lastPoint.maValueList?[i], curPoint.maValueList?[i], canvas, lastX, curX, chartColors.getMAColor(i));
      }
    }
  }

  void drawBollLine(CandleEntity lastPoint, CandleEntity curPoint, Canvas canvas, double lastX, double curX) {
    if (lastPoint.up != 0) {
      drawLine(lastPoint.up, curPoint.up, canvas, lastX, curX, chartColors.ma10Color);
    }
    if (lastPoint.mb != 0) {
      drawLine(lastPoint.mb, curPoint.mb, canvas, lastX, curX, chartColors.ma5Color);
    }
    if (lastPoint.dn != 0) {
      drawLine(lastPoint.dn, curPoint.dn, canvas, lastX, curX, chartColors.ma30Color);
    }
  }

  void drawCandle(CandleEntity curPoint, Canvas canvas, double curX) {
    var high = getY(curPoint.high);
    var low = getY(curPoint.low);
    var open = getY(curPoint.open);
    var close = getY(curPoint.close);
    double r = mCandleWidth / 2 * scaleX;
    double lineR = mCandleLineWidth / 2;
    if (open >= close) {
      // 实体高度>= CandleLineWidth
      if (open - close < mCandleLineWidth) {
        open = close + mCandleLineWidth;
      }
      chartPaint.style = chartStyle.klineStyle;
      chartPaint.color = chartColors.upColor;
      chartPaint.strokeWidth = 1;

      // canvas.drawRRect(RRect.fromLTRBR(curX - r, close, curX + r, open, Radius.circular(chartStyle.candleRadius / scaleX)), chartPaint);
      canvas.drawRRect(RRect.fromLTRBXY(curX - r, close, curX + r, open, chartStyle.candleRadius, 1), chartPaint);
      // canvas.drawRect(Rect.fromLTRB(curX - r, close, curX + r, open), chartPaint);
      chartPaint.style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTRB(curX - lineR, high, curX + lineR, close), chartPaint);
      canvas.drawRect(Rect.fromLTRB(curX - lineR, open, curX + lineR, low), chartPaint);
    } else if (close > open) {
      // 实体高度>= CandleLineWidth
      if (close - open < mCandleLineWidth) {
        open = close - mCandleLineWidth;
      }
      chartPaint.style = PaintingStyle.fill;
      chartPaint.color = chartColors.dnColor;
      canvas.drawRRect(RRect.fromLTRBXY(curX - r, open, curX + r, close, chartStyle.candleRadius, 1), chartPaint);
      // canvas.drawRRect(RRect.fromLTRBR(curX - r, open, curX + r, close, Radius.circular(chartStyle.candleRadius / scaleX)), chartPaint);
      // canvas.drawRect(Rect.fromLTRB(curX - r, open, curX + r, close), chartPaint);
      chartPaint.style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTRB(curX - lineR, high, curX + lineR, open), chartPaint);
      canvas.drawRect(Rect.fromLTRB(curX - lineR, close, curX + lineR, low), chartPaint);
    }
  }

  @override
  void drawVerticalText(canvas, textStyle, int gridRows) {
    double rowSpace = chartRect.height / gridRows;
    for (var i = 0; i <= gridRows; ++i) {
      double value = (gridRows - i) * rowSpace / scaleY + minValue;
      TextSpan span = TextSpan(text: format(value), style: getTextStyle(chartColors.defaultTextColor));
      TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
      tp.layout();

      double offsetX;
      switch (verticalTextAlignment) {
        case VerticalTextAlignment.left:
          offsetX = 0;
          break;
        case VerticalTextAlignment.right:
          offsetX = chartRect.width - tp.width - 0;
          break;
      }

      // if (i == 0) {
      // tp.paint(canvas, Offset(offsetX, -indexPadding));
      // } else {
      tp.paint(canvas, Offset(offsetX, rowSpace * i - tp.height + topPadding));
      // }
    }
  }

  @override
  void drawGrid(Canvas canvas, int gridRows, int gridColumns) {
//    final int gridRows = 4, gridColumns = 4;
    double rowSpace = chartRect.height / gridRows;
    for (int i = 0; i <= gridRows; i++) {
      canvas.drawLine(Offset(0, rowSpace * i + topPadding), Offset(chartRect.width, rowSpace * i + topPadding), gridPaint);
    }
    double columnSpace = chartRect.width / gridColumns;
    for (int i = 0; i <= columnSpace; i++) {
      canvas.drawLine(Offset(columnSpace * i, topPadding / 3), Offset(columnSpace * i, chartRect.bottom), gridPaint);
    }
  }

  @override
  void drawPoints(Canvas canvas, int gridRows, int pointColumns) {
    double rowSpace = chartRect.height / gridRows;
    double columnSpace = chartRect.width / pointColumns;
    List<Offset> points = [];
    for (int i = 0; i <= gridRows; i++) {
      for (int j = 0; j <= columnSpace; j++) {
        points.add(Offset(columnSpace * j, rowSpace * i + topPadding));
      }
    }
    canvas.drawPoints(PointMode.points, points, gridPaint);
  }

  @override
  double getY(double y) {
    //For TrendLine
    updateTrendLineData();
    return (maxValue - y) * scaleY + _contentRect.top;
  }

  void updateTrendLineData() {
    trendLineMax = maxValue;
    trendLineScale = scaleY;
    trendLineContentRec = _contentRect.top;
  }
}
