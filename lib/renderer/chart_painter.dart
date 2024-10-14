import 'dart:async' show StreamSink;

import 'package:flutter/material.dart';
import '../bean/info_window_entity.dart';
import '../bean/kline_entity.dart';
import '../charts/chart_style.dart';
import '../utils/number_util.dart';

import '../utils/date_format_util.dart';
import 'base_chart_painter.dart';
import 'base_chart_renderer.dart';
import 'main_renderer.dart';
import 'secondary_renderer.dart';
import 'vol_renderer.dart';

class TrendLine {
  final Offset p1;
  final Offset p2;
  final double maxHeight;
  final double scale;

  TrendLine(this.p1, this.p2, this.maxHeight, this.scale);
}

double? trendLineX;

double getTrendLineX() {
  return trendLineX ?? 0;
}

class ChartPainter extends BaseChartPainter {
  final List<TrendLine> lines; //For TrendLine
  final bool isTrendLine; //For TrendLine
  bool isrecordingCord = false; //For TrendLine
  final double selectY; //For TrendLine
  static get maxScrollX => BaseChartPainter.maxScrollX;
  late BaseChartRenderer mMainRenderer;
  late List<BaseChartRenderer> mMainRenderers = [];
  BaseChartRenderer? mVolRenderer, mSecondaryRenderer;
  List<BaseChartRenderer> mSecondaryRenderers = [];
  StreamSink<InfoWindowEntity?>? sink;
  Color? upColor, dnColor;
  Color? ma5Color, ma10Color, ma30Color;
  Color? volColor;
  Color? macdColor, difColor, deaColor, jColor;
  int fixedLength;
  List<int> maDayList;
  final ChartColors chartColors;
  late Paint selectPointPaint, selectorBorderPaint, nowPricePaint;
  final ChartStyle chartStyle;
  final bool hideGrid;
  final bool showNowPrice;
  final VerticalTextAlignment verticalTextAlignment;
  bool showLineShader = true;
  bool showTopDiv = true;

  ChartPainter(
    this.chartStyle,
    this.chartColors, {
    required this.lines, //For TrendLine
    required this.isTrendLine, //For TrendLine
    required this.selectY, //For TrendLine
    required datas,
    required scaleX,
    required scrollX,
    required isLongPass,
    required selectX,
    required xFrontPadding,
    isOnTap,
    isTapShowInfoDialog,
    required this.verticalTextAlignment,
    mainState,
    mainStates,
    volHidden,
    secondaryState,
    secondaryStates,
    this.sink,
    bool isLine = false,
    this.showLineShader = true,
    this.showTopDiv = true,
    this.hideGrid = false,
    this.showNowPrice = true,
    this.fixedLength = 2,
    this.maDayList = const [5, 10, 20],
  }) : super(chartStyle,
            datas: datas,
            scaleX: scaleX,
            scrollX: scrollX,
            isLongPress: isLongPass,
            isOnTap: isOnTap,
            isTapShowInfoDialog: isTapShowInfoDialog,
            selectX: selectX,
            mainState: mainState,
            mainStates: mainStates,
            volHidden: volHidden,
            secondaryState: secondaryState,
            secondaryStates: secondaryStates,
            xFrontPadding: xFrontPadding,
            isLine: isLine) {
    selectPointPaint = Paint()
      ..isAntiAlias = true
      ..strokeWidth = 0.5
      ..color = this.chartColors.selectPriceFillColor;
    selectorBorderPaint = Paint()
      ..isAntiAlias = true
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke
      ..color = this.chartColors.selectBorderColor;
    nowPricePaint = Paint()
      ..strokeWidth = this.chartStyle.nowPriceLineWidth
      ..isAntiAlias = true;
  }

  @override
  void initChartRenderer() {
    // if (datas != null && datas!.isNotEmpty) {
    //   var t = datas![0];
    //   fixedLength = NumberUtil.getMaxDecimalLength(t.open, t.close, t.high, t.low);
    // }
    mMainRenderer = MainRenderer(
      mMainRect,
      mMainMaxValue,
      mMainMinValue,
      mTopPadding,
      mainState,
      isLine,
      fixedLength,
      this.chartStyle,
      this.chartColors,
      this.scaleX,
      verticalTextAlignment,
      maDayList,
      0,
      showLineShader,
    );
    if (mainStates.isNotEmpty) {
      mMainRenderers = mainStates
          .mapIndexed((e, index) => MainRenderer(
                mMainRect,
                mMainMaxValue,
                mMainMinValue,
                mTopPadding,
                e,
                isLine,
                fixedLength,
                this.chartStyle,
                this.chartColors,
                this.scaleX,
                verticalTextAlignment,
                maDayList,
                index * 16, //多个文本间距
                showLineShader, //是否显示折线渐变底
                showTopDiv, //是否显示ma下面的线
              ))
          .toList();
    }
    if (mVolRect != null) {
      mVolRenderer = VolRenderer(
          mVolRect!,
          mVolMaxValue,
          mVolMinValue,
          mChildPadding,
          fixedLength,
          this.chartStyle,
          this.chartColors,
          this.scaleX);
    }
    if (mSecondaryRect != null) {
      mSecondaryRenderer = SecondaryRenderer(
          mSecondaryRect!,
          mSecondaryMaxValue,
          mSecondaryMinValue,
          mChildPadding,
          secondaryState,
          fixedLength,
          chartStyle,
          chartColors,
          scaleX);
    }
    if (mSecondaryRects.isNotEmpty) {
      mSecondaryRenderers = secondaryStates
          .mapIndexed((e, index) => SecondaryRenderer(
              mSecondaryRects[index],
              mSecondaryMaxMap[e] ?? double.minPositive,
              mSecondaryMinMap[e] ?? double.maxFinite,
              mChildPadding,
              e,
              fixedLength,
              chartStyle,
              chartColors,
              scaleX))
          .toList();
    }
  }

  @override
  void drawBg(Canvas canvas, Size size) {
    Paint mBgPaint = Paint();
    Gradient mBgGradient = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: chartColors.bgColor,
    );
    Rect mainRect =
        Rect.fromLTRB(0, 0, mMainRect.width, mMainRect.height + mTopPadding);
    canvas.drawRect(
        mainRect, mBgPaint..shader = mBgGradient.createShader(mainRect));

    if (mVolRect != null) {
      Rect volRect = Rect.fromLTRB(
          0, mVolRect!.top - mChildPadding, mVolRect!.width, mVolRect!.bottom);
      canvas.drawRect(
          volRect, mBgPaint..shader = mBgGradient.createShader(volRect));
    }

    if (mSecondaryRect != null) {
      Rect secondaryRect = Rect.fromLTRB(0, mSecondaryRect!.top - mChildPadding,
          mSecondaryRect!.width, mSecondaryRect!.bottom);
      canvas.drawRect(secondaryRect,
          mBgPaint..shader = mBgGradient.createShader(secondaryRect));
    }
    Rect dateRect =
        Rect.fromLTRB(0, size.height - mBottomPadding, size.width, size.height);
    canvas.drawRect(
        dateRect, mBgPaint..shader = mBgGradient.createShader(dateRect));
  }

  @override
  void drawGrid(canvas) {
    if (!hideGrid) {
      mMainRenderer.drawGrid(canvas, mGridRows, mGridColumns);
      mVolRenderer?.drawGrid(canvas, mGridRows, mGridColumns);
      // mSecondaryRenderer?.drawGrid(canvas, mGridRows, mGridColumns);
      for (var e in mSecondaryRenderers) {
        e.drawGrid(canvas, mGridRows, mGridColumns);
      }
    } else {
      mMainRenderer.drawPoints(canvas, mGridRows, pointColumns);
      for (var e in mMainRenderers) {
        e.drawPoints(canvas, mGridRows, pointColumns);
      }
      mVolRenderer?.drawPoints(canvas, mGridRows, pointColumns);
      mSecondaryRenderer?.drawPoints(canvas, mGridRows, pointColumns);
      // mSecondaryRenderers.map((e) => e.drawPoints(canvas, mGridRows, pointColumns));
      for (var e in mSecondaryRenderers) {
        e.drawPoints(canvas, mGridRows, pointColumns);
      }
    }
  }

  @override
  void drawChart(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(mMainRect);
    canvas.translate(mTranslateX * scaleX, 0.0);
    canvas.scale(1, 1.0);

    for (int i = mStartIndex; datas != null && i <= mStopIndex; i++) {
      KlineEntity? curPoint = datas?[i];
      if (curPoint == null) continue;
      KlineEntity lastPoint = i == 0 ? curPoint : datas![i - 1];
      double curX = getX(i);
      double lastX = i == 0 ? curX : getX(i - 1);
      mMainRenderer.drawChart(
          lastPoint, curPoint, lastX * scaleX, curX * scaleX, size, canvas);
      for (var e in mMainRenderers) {
        e.drawChart(
            lastPoint, curPoint, lastX * scaleX, curX * scaleX, size, canvas);
      }
    }
    canvas.restore();
    //
    canvas.save();

    canvas.translate(mTranslateX * scaleX, 0.0);
    canvas.scale(1, 1.0);
    for (int i = mStartIndex; datas != null && i <= mStopIndex; i++) {
      KlineEntity? curPoint = datas?[i];
      if (curPoint == null) continue;
      KlineEntity lastPoint = i == 0 ? curPoint : datas![i - 1];
      double curX = getX(i);
      double lastX = i == 0 ? curX : getX(i - 1);

      // mMainRenderer.drawChart(lastPoint, curPoint, lastX, curX, size, canvas);
      // for (var e in mMainRenderers) {
      //   e.drawChart(lastPoint, curPoint, lastX, curX, size, canvas);
      // }

      mVolRenderer?.drawChart(
          lastPoint, curPoint, lastX * scaleX, curX * scaleX, size, canvas);
      mSecondaryRenderer?.drawChart(
          lastPoint, curPoint, lastX * scaleX, curX * scaleX, size, canvas);
      // mSecondaryRenderers.map((e) => e.drawChart(lastPoint, curPoint, lastX, curX, size, canvas));
      for (var e in mSecondaryRenderers) {
        e.drawChart(
            lastPoint, curPoint, lastX * scaleX, curX * scaleX, size, canvas);
      }
    }

    if ((isLongPress == true || (isTapShowInfoDialog && isOnTap)) &&
        isTrendLine == false) {
      drawCrossLine(canvas, size);
    }
    if (isTrendLine == true) drawTrendLines(canvas, size);
    canvas.restore();
  }

  @override
  void drawVerticalText(canvas) {
    var textStyle = getTextStyle(this.chartColors.defaultTextColor);
    // if (!hideGrid) {
    mMainRenderer.drawVerticalText(canvas, textStyle, mGridRows);
    for (var e in mMainRenderers) {
      e.drawVerticalText(canvas, textStyle, mGridRows);
    }
    // }
    mVolRenderer?.drawVerticalText(canvas, textStyle, mGridRows);
    mSecondaryRenderer?.drawVerticalText(canvas, textStyle, mGridRows);
    for (var e in mSecondaryRenderers) {
      e.drawVerticalText(canvas, textStyle, mGridRows);
    }
  }

  @override
  void drawDate(Canvas canvas, Size size) {
    if (datas == null) return;

    double columnSpace = size.width / mGridColumns;
    double startX = getX(mStartIndex) - mPointWidth / 2;
    double stopX = getX(mStopIndex) + mPointWidth / 2;
    double x = 0.0;
    double y = 0.0;
    double h = 0.0;
    for (var i = 0; i <= mGridColumns; ++i) {
      double translateX = xToTranslateX(columnSpace * i);

      if (translateX >= startX && translateX <= stopX) {
        int index = indexOfTranslateX(translateX);

        if (datas?[index] == null) continue;
        TextPainter tp = getTextPainter(getDate(datas![index].id), null);
        y = mMainRect.height +
            mTopPadding; //size.height - (mBottomPadding - tp.height) / 2 - tp.height;
        x = columnSpace * i - tp.width / 2;
        // Prevent date text out of canvas
        if (x < 0) x = 0;
        if (x > size.width - tp.width) x = size.width - tp.width;
        tp.paint(canvas, Offset(x, y + (mDateHeight - tp.height) / 2));
        h = mDateHeight; //tp.height + 6;
      }
    }
    var lpt = Paint()
      ..color = chartColors.gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), lpt);
    canvas.drawLine(
        Offset(0, y + mDateHeight), Offset(size.width, y + mDateHeight), lpt);
  }

  @override
  void drawCrossLineText(Canvas canvas, Size size) {
    var index = calculateSelectedX(selectX);
    KlineEntity point = getItem(index);

    TextPainter tp = getTextPainter(point.close, chartColors.crossTextColor);
    double textHeight = tp.height;
    double textWidth = tp.width;

    double w1 = 5;
    double w2 = 3;
    double r = textHeight / 2 + w2;
    double y = getMainY(point.close);
    double x;
    bool isLeft = false;
    RRect rect;
    if (translateXtoX(getX(index)) < mWidth / 2) {
      isLeft = false;
      x = 1;

      rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y - r, textWidth + 2 * w1, r * 2),
          Radius.circular(3));
      canvas.drawRRect(rect, selectPointPaint);
      tp.paint(canvas, Offset(x + w1, y - textHeight / 2));
    } else {
      isLeft = true;
      x = mWidth - textWidth - 1 - 2 * w1 - w2;

      rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y - r, textWidth + 2 * w1, r * 2),
          Radius.circular(3));
      canvas.drawRRect(rect, selectPointPaint);
      tp.paint(canvas, Offset(x + w1 + w2, y - textHeight / 2));
    }

    TextPainter dateTp =
        getTextPainter(getDate(point.id?.toInt()), chartColors.crossTextColor);
    textWidth = dateTp.width;
    r = textHeight / 2;
    x = translateXtoX(getX(index));
    y = mMainRect.height + mTopPadding; //size.height - mBottomPadding;

    if (x < textWidth + 2 * w1) {
      x = 1 + textWidth / 2 + w1;
    } else if (mWidth - x < textWidth + 2 * w1) {
      x = mWidth - 1 - textWidth / 2 - w1;
    }
    double baseLine = textHeight / 2;
    canvas.drawRect(
        Rect.fromLTRB(x - textWidth / 2 - w1, y, x + textWidth / 2 + w1,
            y + baseLine + r),
        selectPointPaint);
    canvas.drawRect(
        Rect.fromLTRB(x - textWidth / 2 - w1, y, x + textWidth / 2 + w1,
            y + baseLine + r),
        selectorBorderPaint);

    dateTp.paint(canvas, Offset(x - textWidth / 2, y));
    //长按显示这条数据详情
    sink?.add(InfoWindowEntity(point, isLeft: isLeft));
  }

  @override
  void drawText(Canvas canvas, KlineEntity data, double x) {
    //长按显示按中的数据
    if (isLongPress || (isTapShowInfoDialog && isOnTap)) {
      var index = calculateSelectedX(selectX);
      data = getItem(index);
    }
    //松开显示最后一条数据
    mMainRenderer.drawText(canvas, data, x);
    for (var e in mMainRenderers) {
      e.drawText(canvas, data, x);
    }
    mVolRenderer?.drawText(canvas, data, x);
    mSecondaryRenderer?.drawText(canvas, data, x);
    // mSecondaryRenderers.map((e) => e.drawText(canvas, data, x));
    for (var e in mSecondaryRenderers) {
      e.drawText(canvas, data, x);
    }
  }

  @override
  void drawMaxAndMin(Canvas canvas) {
    if (isLine == true) return;
    //绘制最大值和最小值
    double x = translateXtoX(getX(mMainMinIndex));
    double y = getMainY(mMainLowMinValue);
    if (x < mWidth / 2) {
      //画右边
      TextPainter tp = getTextPainter(
          "── " + mMainLowMinValue.toStringAsFixed(fixedLength),
          chartColors.minColor);
      tp.paint(canvas, Offset(x, y - tp.height / 2));
    } else {
      TextPainter tp = getTextPainter(
          mMainLowMinValue.toStringAsFixed(fixedLength) + " ──",
          chartColors.minColor);
      tp.paint(canvas, Offset(x - tp.width, y - tp.height / 2));
    }
    x = translateXtoX(getX(mMainMaxIndex));
    y = getMainY(mMainHighMaxValue);
    if (x < mWidth / 2) {
      //画右边
      TextPainter tp = getTextPainter(
          "── " + mMainHighMaxValue.toStringAsFixed(fixedLength),
          chartColors.maxColor);
      tp.paint(canvas, Offset(x, y - tp.height / 2));
    } else {
      TextPainter tp = getTextPainter(
          mMainHighMaxValue.toStringAsFixed(fixedLength) + " ──",
          chartColors.maxColor);
      tp.paint(canvas, Offset(x - tp.width, y - tp.height / 2));
    }
  }

  @override
  void drawNowPrice(Canvas canvas) {
    if (!this.showNowPrice) {
      return;
    }

    if (datas == null) {
      return;
    }

    double value = datas!.last.close;
    double y = getMainY(value);

    //视图展示区域边界值绘制
    if (y > getMainY(mMainLowMinValue)) {
      y = getMainY(mMainLowMinValue);
    }

    if (y < getMainY(mMainHighMaxValue)) {
      y = getMainY(mMainHighMaxValue);
    }

    nowPricePaint
      ..color = this
          .chartColors
          .nowDashColor; //value >= datas!.last.open ? this.chartColors.nowPriceUpColor : this.chartColors.nowPriceDnColor;
    //先画横线

    final max = -mTranslateX + mWidth / scaleX;
    final space =
        this.chartStyle.nowPriceLineSpan + this.chartStyle.nowPriceLineLength;

    //再画背景和文本
    TextPainter tp = getTextPainter(
        value.toStringAsFixed(fixedLength), this.chartColors.nowPriceTextColor,
        fontWeight: FontWeight.bold);

    double offsetX;
    switch (verticalTextAlignment) {
      case VerticalTextAlignment.left:
        offsetX = 0;
        break;
      case VerticalTextAlignment.right:
        offsetX = mWidth - tp.width - 0 - 0;
        break;
    }
    //剪掉文本宽度
    double startX =
        verticalTextAlignment == VerticalTextAlignment.right ? 0 : tp.width;
    if (scrollX < xFrontPadding - tp.width)
      startX = mWidth - xFrontPadding + scrollX - mPointWidth * scaleX;

    while (startX < mWidth - tp.width) {
      canvas.drawLine(
          Offset(startX, y),
          Offset(startX + this.chartStyle.nowPriceLineLength, y),
          nowPricePaint..strokeWidth = 0.5);
      startX += space;
    }

    double top = y - tp.height / 2;
    // nowPricePaint.color = value >= datas!.last.open ? this.chartColors.nowPriceUpColor : this.chartColors.nowPriceDnColor;
    // canvas.drawRect(Rect.fromLTRB(offsetX, top, offsetX + tp.width, top + tp.height), nowPricePaint);
    var bgPaint = nowPricePaint
      ..color = chartColors.nowPriceBgColor
      ..style = PaintingStyle.fill;
    var bgPaddingV = 3.0;
    var bgPaddingH = 4.0;
    canvas.drawRRect(
        RRect.fromLTRBR(
            offsetX - bgPaddingH,
            top - bgPaddingV,
            offsetX + tp.width + bgPaddingH,
            top + tp.height + bgPaddingV,
            Radius.circular(4)),
        bgPaint);
    canvas.drawRRect(
        RRect.fromLTRBR(
            offsetX - bgPaddingH,
            top - bgPaddingV,
            offsetX + tp.width + bgPaddingH,
            top + tp.height + bgPaddingV,
            Radius.circular(4)),
        bgPaint
          ..style = PaintingStyle.stroke
          ..color = chartColors.nowPriceBordColor);
    tp.paint(canvas, Offset(offsetX, top));
  }

//For TrendLine
  void drawTrendLines(Canvas canvas, Size size) {
    var index = calculateSelectedX(selectX);
    Paint paintY = Paint()
      ..color = Colors.orange
      ..strokeWidth = 1
      ..isAntiAlias = true;
    double x = getX(index);
    trendLineX = x;

    double y = selectY;
    // getMainY(point.close);

    // k线图竖线
    canvas.drawLine(Offset(x, mTopPadding),
        Offset(x, size.height - mBottomPadding), paintY);
    Paint paintX = Paint()
      ..color = Colors.orangeAccent
      ..strokeWidth = 1
      ..isAntiAlias = true;
    Paint paint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(-mTranslateX, y),
        Offset(-mTranslateX + mWidth / scaleX, y), paintX);
    if (scaleX >= 1) {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(x, y), height: 15.0 * scaleX, width: 15.0),
          paint);
    } else {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(x, y), height: 10.0, width: 10.0 / scaleX),
          paint);
    }
    if (lines.length >= 1) {
      lines.forEach((element) {
        var y1 = -((element.p1.dy - 35) / element.scale) + element.maxHeight;
        var y2 = -((element.p2.dy - 35) / element.scale) + element.maxHeight;
        var a = (trendLineMax! - y1) * trendLineScale! + trendLineContentRec!;
        var b = (trendLineMax! - y2) * trendLineScale! + trendLineContentRec!;
        var p1 = Offset(element.p1.dx, a);
        var p2 = Offset(element.p2.dx, b);
        canvas.drawLine(
            p1,
            element.p2 == Offset(-1, -1) ? Offset(x, y) : p2,
            Paint()
              ..color = Colors.yellow
              ..strokeWidth = 2);
      });
    }
  }

  ///画交叉线
  void drawCrossLine(Canvas canvas, Size size) {
    var index = calculateSelectedX(selectX);
    KlineEntity point = getItem(index);
    Paint paintY = Paint()
      ..color = this.chartColors.vCrossColor
      ..strokeWidth = this.chartStyle.vCrossWidth
      ..isAntiAlias = true;
    double x = getX(index) * scaleX;
    double y = getMainY(point.close);
    // k线图竖线
    // canvas.drawLine(Offset(x, mTopPadding), Offset(x, size.height - mBottomPadding), paintY);
    drawDashLine(
      canvas,
      Offset(x, mTopPadding),
      Offset(x, mMainRect.height + mTopPadding),
      color: this.chartColors.vCrossColor,
      axis: Axis.vertical,
      dw: 2,
      space: 4,
      strokeWidth: 0.5,
    );
    Paint paintX = Paint()
      ..color = this.chartColors.hCrossColor
      ..strokeWidth = this.chartStyle.hCrossWidth
      ..isAntiAlias = true;
    // k线图横线
    // canvas.drawLine(Offset(-mTranslateX, y), Offset(-mTranslateX + mWidth / scaleX, y), paintX);
    drawDashLine(
      canvas,
      Offset(-mTranslateX * scaleX, y),
      Offset(-mTranslateX * scaleX + mWidth, y),
      color: this.chartColors.hCrossColor,
      dw: 2,
      space: 4,
      strokeWidth: 0.5,
    );
    if (scaleX >= 1) {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(x, y), height: 2.0 * scaleX, width: 2.0),
          paintX);
    } else {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(x, y), height: 2.0, width: 2.0 / scaleX),
          paintX);
    }
    // k线原点
    drawSelectedDot(canvas, Offset(x, y));
  }

  void drawDashLine(
    Canvas canvas,
    Offset d0,
    Offset d1, {
    Color color = Colors.white24,
    double dw = 2,
    double space = 2,
    Paint? paint,
    double strokeWidth = 1,
    Axis axis = Axis.horizontal,
  }) {
    paint = paint ?? Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    // ..isAntiAlias = true;
    Path path = Path();
    Path dashPath = Path();
    dashPath.moveTo(d0.dx, d0.dy);
    if (axis == Axis.horizontal) {
      dashPath.lineTo(d0.dx + dw, d0.dy);

      double distance = 0;
      while (distance < d1.dx - d0.dx) {
        path.addPath(dashPath, Offset(distance, 0));
        distance += dw + space;
      }
    } else {
      dashPath.lineTo(d0.dx, d0.dy + dw);

      double distance = 0;
      while (distance < d1.dy - d0.dy) {
        path.addPath(dashPath, Offset(0, distance));
        distance += dw + space;
      }
    }

    canvas.drawPath(path, paint);
  }

  void drawSelectedDot(Canvas canvas, Offset offset) {
    var center = offset;
    var radius = this.chartStyle.dotRadius;
    var bgRadius = this.chartStyle.dotBgRadius;
    final bgPaint = Paint()
      ..color = this.chartColors.dotBgColor
      ..style = PaintingStyle.fill;

    canvas.drawOval(
        Rect.fromCenter(center: center, width: bgRadius, height: bgRadius),
        bgPaint);

    final borderPaint = Paint()
      ..color = this.chartColors.dotBorderColor
      // ..strokeWidth = this.chartStyle.dotBorderWidth
      ..style = PaintingStyle.fill;
    var borderRadius = radius + chartStyle.dotBorderWidth;
    canvas.drawOval(
        Rect.fromCenter(
            center: center, width: borderRadius, height: borderRadius),
        borderPaint);

    final paint = Paint()
      ..color = this.chartColors.dotColor
      ..style = PaintingStyle.fill;

    canvas.drawOval(
        Rect.fromCenter(center: center, width: radius, height: radius), paint);
  }

  void drawSelectedDot0(Canvas canvas, Offset offset) {
    var center = offset;
    var radius = this.chartStyle.dotRadius;
    var bgRadius = this.chartStyle.dotBgRadius;
    final bgPaint = Paint()
      ..color = this.chartColors.dotBgColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, bgRadius, bgPaint);
    final paint = Paint()
      ..color = this.chartColors.dotColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paint);

    final borderPaint = Paint()
      ..color = this.chartColors.dotBorderColor
      ..strokeWidth = this.chartStyle.dotBorderWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, borderPaint);
  }

  TextPainter getTextPainter(text, color, {FontWeight? fontWeight}) {
    if (color == null) {
      color = this.chartColors.defaultTextColor;
    }

    TextSpan span = TextSpan(
        text: "$text",
        style: getTextStyle(color, fontSize: 10, fontWeight: fontWeight));

    TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    return tp;
  }

  String getDate(int? date) => dateFormat(
      DateTime.fromMillisecondsSinceEpoch(
          date ?? DateTime.now().millisecondsSinceEpoch),
      mFormats);

  double getMainY(double y) => mMainRenderer.getY(y);

  /// 点是否在SecondaryRect中
  bool isInSecondaryRect(Offset point) {
    return mSecondaryRect?.contains(point) ?? false;
  }

  /// 点是否在MainRect中
  bool isInMainRect(Offset point) {
    return mMainRect.contains(point);
  }
}
