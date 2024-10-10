import 'dart:math';
import 'dart:ui';
import '../charts/chart_style.dart';
import '../utils/index.dart';
import 'index.dart';
import  '../bean/kline_entity.dart';
import 'package:flutter/material.dart' show Color, TextStyle, Rect, Canvas, Size, CustomPainter;
export 'package:flutter/material.dart' show Color, required, TextStyle, Rect, Canvas, Size, CustomPainter;

abstract class BaseChartPainter extends CustomPainter {
  static double maxScrollX = 0.0;
  List<KlineEntity>? datas;
  MainState mainState;
  List<MainState> mainStates;
  Map<MainState, double> mMainMaxMap = {};
  Map<MainState, double> mMainMinMap = {};

  SecondaryState secondaryState;
  List<SecondaryState> secondaryStates;
  List<Rect> mSecondaryRects = [];
  Map<SecondaryState, double> mSecondaryMaxMap = {};
  Map<SecondaryState, double> mSecondaryMinMap = {};

  bool volHidden;
  bool isTapShowInfoDialog;
  double scaleX = 1.0, scrollX = 0.0, selectX;
  bool isLongPress = false;
  bool isOnTap;
  bool isLine;

  //3块区域大小与位置
  late Rect mMainRect;
  Rect? mVolRect, mSecondaryRect;
  late double mDisplayHeight, mWidth;
  double mTopPadding = 30.0, mBottomPadding = 20.0, mChildPadding = 12.0, mDateHeight = 20, mBtnsHeight = 30;
  int mGridRows = 4, mGridColumns = 4, pointColumns = 14;
  int mStartIndex = 0, mStopIndex = 0;
  double mMainMaxValue = double.minPositive, mMainMinValue = double.maxFinite;
  double mVolMaxValue = double.minPositive, mVolMinValue = double.maxFinite;
  double mSecondaryMaxValue = double.minPositive, mSecondaryMinValue = double.maxFinite;
  double mTranslateX = double.minPositive;
  int mMainMaxIndex = 0, mMainMinIndex = 0;
  double mMainHighMaxValue = double.minPositive, mMainLowMinValue = double.maxFinite;
  int mItemCount = 0;
  double mDataLen = 0.0; //数据占屏幕总长度
  final ChartStyle chartStyle;
  late double mPointWidth;
  List<String> mFormats = [yyyy, '/', mm, '/', dd, ' ', HH, ':', nn]; //格式化时间
  double xFrontPadding;

  BaseChartPainter(
    this.chartStyle, {
    this.datas,
    required this.scaleX,
    required this.scrollX,
    required this.isLongPress,
    required this.selectX,
    required this.xFrontPadding,
    this.isOnTap = false,
    this.mainState = MainState.MA,
    this.mainStates = const [],
    this.volHidden = false,
    this.isTapShowInfoDialog = false,
    this.secondaryState = SecondaryState.MACD,
    this.secondaryStates = const [],
    this.isLine = false,
  }) {
    mItemCount = datas?.length ?? 0;
    mPointWidth = chartStyle.candleWidth + chartStyle.pointWidth / scaleX;
    mTopPadding = chartStyle.topPadding;
    mBottomPadding = chartStyle.bottomPadding;
    mChildPadding = chartStyle.childPadding;
    mGridRows = chartStyle.gridRows;
    mGridColumns = chartStyle.gridColumns;
    pointColumns = chartStyle.pointColumns;
    mDataLen = mItemCount * mPointWidth;
    mDateHeight = chartStyle.dateHeight;
    mBtnsHeight = chartStyle.btnsHeight;
    initFormats();
  }

  void initFormats() {
    if (chartStyle.dateTimeFormat != null) {
      mFormats = chartStyle.dateTimeFormat!;
      return;
    }

    if (mItemCount < 2) {
      mFormats = [yyyy, '/', mm, '/', dd, ' ', HH, ':', nn];
      return;
    }

    int firstTime = datas!.first.id?.toInt() ?? 0;
    int secondTime = datas![1].id?.toInt() ?? 0;
    int time = secondTime - firstTime;
    time ~/= 1000;
    //月线
    if (time >= 24 * 60 * 60 * 28) {
      mFormats = [yy, '/', mm];
    } else if (time >= 24 * 60 * 60) {
      mFormats = [yy, '/', mm, '/', dd];
    } else {
      mFormats = [mm, '/', dd, ' ', HH, ':', nn];
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Rect.fromLTRB(0, 0, size.width, size.height));
    mDisplayHeight = size.height - mTopPadding - mBottomPadding;
    mWidth = size.width;
    initRect(size);
    calculateValue();
    initChartRenderer();

    canvas.save();
    canvas.scale(1, 1);
    drawBg(canvas, size);
    drawGrid(canvas);
    if (datas != null && datas!.isNotEmpty) {
      drawChart(canvas, size);
      drawVerticalText(canvas);
      drawDate(canvas, size);

      drawText(canvas, datas!.last, 5);
      drawMaxAndMin(canvas);
      drawNowPrice(canvas);

      if (isLongPress == true || (isTapShowInfoDialog && isOnTap)) {
        drawCrossLineText(canvas, size);
      }
    }
    canvas.restore();
  }

  void initChartRenderer();

  //画背景
  void drawBg(Canvas canvas, Size size);

  //画网格
  void drawGrid(canvas);

  //画图表
  void drawChart(Canvas canvas, Size size);

  //画右边值
  void drawVerticalText(canvas);

  //画时间
  void drawDate(Canvas canvas, Size size);

  //画值
  void drawText(Canvas canvas, KlineEntity data, double x);

  //画最大最小值
  void drawMaxAndMin(Canvas canvas);

  //画当前价格
  void drawNowPrice(Canvas canvas);

  //画交叉线
  void drawCrossLine(Canvas canvas, Size size);

  //交叉线值
  void drawCrossLineText(Canvas canvas, Size size);

  void initRect(Size size) {
    double volHeight = volHidden != true ? chartStyle.vheight ?? mDisplayHeight * 0.1 : 0;
    double secondaryHeight = secondaryState != SecondaryState.NONE ? chartStyle.vheight ?? mDisplayHeight * 0.1 : 0;

    double mainHeight = mDisplayHeight;
    double _secondaryHeight = chartStyle.vheight ?? mDisplayHeight * 0.1;
    mainHeight -= chartStyle.bottomPadding;
    mainHeight -= volHeight;
    mainHeight -= secondaryStates.isNotEmpty ? _secondaryHeight * secondaryStates.length : secondaryHeight;

    mMainRect = Rect.fromLTRB(0, mTopPadding, mWidth, mTopPadding + mainHeight - mDateHeight);

    if (volHidden != true) {
      mVolRect = Rect.fromLTRB(0, mMainRect.bottom + mChildPadding + mDateHeight + mBtnsHeight, mWidth, mMainRect.bottom + volHeight + mDateHeight + mBtnsHeight);
    }

    //secondaryState == SecondaryState.NONE隐藏副视图
    if (secondaryState != SecondaryState.NONE) {
      mSecondaryRect = Rect.fromLTRB(0, mMainRect.bottom + volHeight + mChildPadding + mDateHeight + mBtnsHeight, mWidth, mMainRect.bottom + volHeight + mDateHeight + mBtnsHeight + secondaryHeight);
    }
    if (secondaryStates.isNotEmpty) {
      mSecondaryRects = secondaryStates
          .mapIndexed((e, i) => Rect.fromLTRB(0, mMainRect.bottom + volHeight + mDateHeight + mBtnsHeight + mChildPadding + i * _secondaryHeight, mWidth,
              mMainRect.bottom + volHeight + mDateHeight + mBtnsHeight + (i + 1) * _secondaryHeight))
          .toList();
    }
  }

  calculateValue() {
    if (datas == null) return;
    if (datas!.isEmpty) return;
    maxScrollX = getMinTranslateX().abs();
    setTranslateXFromScrollX(scrollX);
    mStartIndex = indexOfTranslateX(xToTranslateX(0));
    mStopIndex = indexOfTranslateX(xToTranslateX(mWidth));
    for (int i = mStartIndex; i <= mStopIndex; i++) {
      var item = datas![i];
      getMainMaxMinValue(item, i);
      getMainMaxMinMap(item, i);
      getVolMaxMinValue(item);
      getSecondaryMaxMinValue(item);
      getSecondaryMaxMinMap(item);
    }
  }

  void getMainMaxMinValue(KlineEntity item, int i) {
    double maxPrice, minPrice;
    // if (mainState == MainState.BOLL) {
    maxPrice = max(item.up ?? item.high, item.high);
    minPrice = min(item.dn ?? item.low, item.low);
    // } else if (mainState == MainState.MA) {
    //   maxPrice = max(item.high, _findMaxMA(item.maValueList ?? [0]));
    //   minPrice = min(item.low, _findMinMA(item.maValueList ?? [0]));
    // } else {
    //   maxPrice = item.high;
    //   minPrice = item.low;
    // }
    mMainMaxValue = max(mMainMaxValue, maxPrice);
    mMainMinValue = min(mMainMinValue, minPrice);

    if (mMainHighMaxValue < item.high) {
      mMainHighMaxValue = item.high;
      mMainMaxIndex = i;
    }
    if (mMainLowMinValue > item.low) {
      mMainLowMinValue = item.low;
      mMainMinIndex = i;
    }

    if (isLine == true) {
      mMainMaxValue = max(mMainMaxValue, item.close);
      mMainMinValue = min(mMainMinValue, item.close);
    }
  }

  void getMainMaxMinMap(KlineEntity item, int i) {
    for (var e in mainStates) {
      double maxPrice, minPrice;
      if (e == MainState.MA) {
        maxPrice = max(item.high, _findMaxMA(item.maValueList ?? [0]));
        minPrice = min(item.low, _findMinMA(item.maValueList ?? [0]));
      } else if (e == MainState.BOLL) {
        maxPrice = max(item.up ?? 0, item.high);
        minPrice = min(item.dn ?? 0, item.low);
      } else {
        maxPrice = item.high;
        minPrice = item.low;
      }
      mMainMaxMap[e] = max(mMainMaxMap[e] ?? double.minPositive, maxPrice);
      mMainMinMap[e] = min(mMainMinMap[e] ?? double.maxFinite, minPrice);

      if (mMainHighMaxValue < item.high) {
        mMainHighMaxValue = item.high;
        mMainMaxIndex = i;
      }
      if (mMainLowMinValue > item.low) {
        mMainLowMinValue = item.low;
        mMainMinIndex = i;
      }

      if (isLine == true) {
        mMainMaxMap[e] = max(mMainMaxMap[e] ?? double.minPositive, item.close);
        mMainMinMap[e] = min(mMainMinMap[e] ?? double.maxFinite, item.close);
      }
    }
  }

  double _findMaxMA(List<double> a) {
    double result = double.minPositive;
    for (double i in a) {
      result = max(result, i);
    }
    return result;
  }

  double _findMinMA(List<double> a) {
    double result = double.maxFinite;
    for (double i in a) {
      result = min(result, i == 0 ? double.maxFinite : i);
    }
    return result;
  }

  void getVolMaxMinValue(KlineEntity item) {
    mVolMaxValue = max(mVolMaxValue, max(item.vol, max(item.MA5Volume ?? 0, item.MA10Volume ?? 0)));
    mVolMinValue = min(mVolMinValue, min(item.vol, min(item.MA5Volume ?? 0, item.MA10Volume ?? 0)));
  }

  void getSecondaryMaxMinValue(KlineEntity item) {
    if (secondaryState == SecondaryState.MACD) {
      if (item.macd != null) {
        mSecondaryMaxValue = max(mSecondaryMaxValue, max(item.macd!, max(item.dif!, item.dea!)));
        mSecondaryMinValue = min(mSecondaryMinValue, min(item.macd!, min(item.dif!, item.dea!)));
      }
    } else if (secondaryState == SecondaryState.KDJ) {
      if (item.d != null) {
        mSecondaryMaxValue = max(mSecondaryMaxValue, max(item.k!, max(item.d!, item.j!)));
        mSecondaryMinValue = min(mSecondaryMinValue, min(item.k!, min(item.d!, item.j!)));
      }
    } else if (secondaryState == SecondaryState.RSI) {
      if (item.rsi != null) {
        mSecondaryMaxValue = max(mSecondaryMaxValue, item.rsi!);
        mSecondaryMinValue = min(mSecondaryMinValue, item.rsi!);
      }
    } else if (secondaryState == SecondaryState.WR) {
      mSecondaryMaxValue = 0;
      mSecondaryMinValue = -100;
    } else if (secondaryState == SecondaryState.CCI) {
      if (item.cci != null) {
        mSecondaryMaxValue = max(mSecondaryMaxValue, item.cci!);
        mSecondaryMinValue = min(mSecondaryMinValue, item.cci!);
      }
    } else {
      mSecondaryMaxValue = 0;
      mSecondaryMinValue = 0;
    }
  }

  void getSecondaryMaxMinMap(KlineEntity item) {
    for (var e in secondaryStates) {
      if (e == SecondaryState.MACD) {
        if (item.macd != null) {
          mSecondaryMaxMap[e] = max(mSecondaryMaxMap[e] ?? double.minPositive, max(item.macd!, max(item.dif!, item.dea!)));
          mSecondaryMinMap[e] = min(mSecondaryMinMap[e] ?? double.maxFinite, min(item.macd!, min(item.dif!, item.dea!)));
        }
      } else if (e == SecondaryState.KDJ) {
        if (item.d != null) {
          mSecondaryMaxMap[e] = max(mSecondaryMaxMap[e] ?? double.minPositive, max(item.k!, max(item.d!, item.j!)));
          mSecondaryMinMap[e] = min(mSecondaryMinMap[e] ?? double.maxFinite, min(item.k!, min(item.d!, item.j!)));
        }
      } else if (e == SecondaryState.RSI) {
        if (item.rsi != null) {
          mSecondaryMaxMap[e] = max(mSecondaryMaxMap[e] ?? double.minPositive, item.rsi!);
          mSecondaryMinMap[e] = min(mSecondaryMinMap[e] ?? double.maxFinite, item.rsi!);
        }
      } else if (e == SecondaryState.WR) {
        mSecondaryMaxMap[e] = 0;
        mSecondaryMinMap[e] = -100;
      } else if (e == SecondaryState.CCI) {
        if (item.cci != null) {
          mSecondaryMaxMap[e] = max(mSecondaryMaxMap[e] ?? double.minPositive, item.cci!);
          mSecondaryMinMap[e] = min(mSecondaryMinMap[e] ?? double.maxFinite, item.cci!);
        }
      } else {
        mSecondaryMaxMap[e] = double.minPositive;
        mSecondaryMinMap[e] = double.maxFinite;
      }
    }
  }

  double xToTranslateX(double x) => -mTranslateX + x / scaleX;

  int indexOfTranslateX(double translateX) => _indexOfTranslateX(translateX, 0, mItemCount - 1);

  ///二分查找当前值的index
  int _indexOfTranslateX(double translateX, int start, int end) {
    if (end == start || end == -1) {
      return start;
    }
    if (end - start == 1) {
      double startValue = getX(start);
      double endValue = getX(end);
      return (translateX - startValue).abs() < (translateX - endValue).abs() ? start : end;
    }
    int mid = start + (end - start) ~/ 2;
    double midValue = getX(mid);
    if (translateX < midValue) {
      return _indexOfTranslateX(translateX, start, mid);
    } else if (translateX > midValue) {
      return _indexOfTranslateX(translateX, mid, end);
    } else {
      return mid;
    }
  }

  ///根据索引索取x坐标
  ///+ mPointWidth / 2防止第一根和最后一根k线显示不���
  ///@param position 索引值
  double getX(int position) => position * mPointWidth + mPointWidth / 2;

  KlineEntity getItem(int position) {
    return datas![position];
    // if (datas != null) {
    //   return datas[position];
    // } else {
    //   return null;
    // }
  }

  ///scrollX 转换为 TranslateX
  void setTranslateXFromScrollX(double scrollX) => mTranslateX = scrollX + getMinTranslateX();

  ///获取平移的最小值
  double getMinTranslateX() {
    var x = -mDataLen + mWidth / scaleX - mPointWidth / 2 - xFrontPadding / scaleX;
    return x >= 0 ? 0.0 : x;
  }

  ///计算长按后x的值，转换为index
  int calculateSelectedX(double selectX) {
    int mSelectedIndex = indexOfTranslateX(xToTranslateX(selectX));
    if (mSelectedIndex < mStartIndex) {
      mSelectedIndex = mStartIndex;
    }
    if (mSelectedIndex > mStopIndex) {
      mSelectedIndex = mStopIndex;
    }
    return mSelectedIndex;
  }

  ///translateX转化为view中的x
  double translateXtoX(double translateX) => (translateX + mTranslateX) * scaleX;

  TextStyle getTextStyle(Color color, {double? fontSize = 10.0, FontWeight? fontWeight}) {
    return TextStyle(fontSize: fontSize, color: color, fontWeight: fontWeight);
  }

  @override
  bool shouldRepaint(BaseChartPainter oldDelegate) {
    return true;
//    return oldDelegate.datas != datas ||
//        oldDelegate.datas?.length != datas?.length ||
//        oldDelegate.scaleX != scaleX ||
//        oldDelegate.scrollX != scrollX ||
//        oldDelegate.isLongPress != isLongPress ||
//        oldDelegate.selectX != selectX ||
//        oldDelegate.isLine != isLine ||
//        oldDelegate.mainState != mainState ||
//        oldDelegate.secondaryState != secondaryState;
  }
}
