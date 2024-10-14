import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kline_charts/charts/map_ext.dart';
import 'package:gesture_x_detector/gesture_x_detector.dart';

import '../bean/info_window_entity.dart';
import '../bean/kline_entity.dart';
import '../bean/kline_entity.dart';
import '../bean/kline_entity.dart';
import 'chart_style.dart';
import '../renderer/chart_painter.dart';
import '../renderer/main_renderer.dart';
import 'chart_translations.dart';
import '../utils/date_format_util.dart';
import '../utils/enums.dart';


class KChartAnimationWidget extends StatefulWidget {
  final List<KlineEntity>? datas;
  final MainState mainState;
  final List<MainState> mainStates;
  final bool volHidden;
  final SecondaryState secondaryState;
  final List<SecondaryState> secondaryStates;
  final Function()? onSecondaryTap;
  final bool isLine;
  final bool isTapShowInfoDialog; //是否开启单击显示详情数据
  final bool hideGrid;
  @Deprecated('Use `translations` instead.')
  final bool isChinese;
  final bool showNowPrice;
  final bool showInfoDialog;
  final bool materialInfoDialog; // Material风格的信息弹窗
  final Map<String, ChartTranslations> translations;
  final List<String> timeFormat;

  //当屏幕滚动到尽头会调用，真为拉到屏幕右侧尽头，假为拉到屏幕左侧尽头
  final Function(bool)? onLoadMore;

  final int fixedLength;
  final List<int> maDayList;
  final int flingTime;
  final double flingRatio;
  final Curve flingCurve;
  final Function(bool)? isOnDrag;
  final ChartColors chartColors;
  final ChartStyle chartStyle;
  final VerticalTextAlignment verticalTextAlignment;
  final bool isTrendLine;
  final double xFrontPadding;
  final GestureTapDownCallback? onTapDown;

  final bool showLineShader;
  final bool showTopDiv;
  final void Function([bool val])? onShowInfo;

  KChartAnimationWidget(
    this.datas,
    this.chartStyle,
    this.chartColors, {
     this.isTrendLine=false,
    this.xFrontPadding = 65,
    this.mainState = MainState.MA,
    this.mainStates = const [],
    this.secondaryState = SecondaryState.MACD,
    this.secondaryStates = const [],
    this.onSecondaryTap,
    this.volHidden = false,
    this.isLine = false,
    this.showLineShader = true,
    this.showTopDiv = true,
    this.isTapShowInfoDialog = false,
    this.hideGrid = false,
    @Deprecated('Use `translations` instead.') this.isChinese = false,
    this.showNowPrice = true,
    this.showInfoDialog = true,
    this.materialInfoDialog = true,
    this.translations = kChartTranslations,
    this.timeFormat = TimeFormat.YEAR_MONTH_DAY,
    this.onLoadMore,
    this.fixedLength = 2,
    this.maDayList = const [5, 10, 20],
    this.flingTime = 600,
    this.flingRatio = 0.5,
    this.flingCurve = Curves.decelerate,
    this.isOnDrag,
    this.verticalTextAlignment = VerticalTextAlignment.left,
    this.onTapDown,
    this.onShowInfo,
  });

  @override
  _KChartAnimationWidgetState createState() => _KChartAnimationWidgetState();
}

class _KChartAnimationWidgetState extends State<KChartAnimationWidget> with TickerProviderStateMixin {
  double mScaleX = 1.0, mScrollX = 0.0, mSelectX = 0.0;
  StreamController<InfoWindowEntity?>? mInfoWindowStream;
  double mHeight = 0, mWidth = 0;
  AnimationController? _controller;
  Animation<double>? aniX;

  //For TrendLine
  List<TrendLine> lines = [];
  double? changeinXposition;
  double? changeinYposition;
  double mSelectY = 0.0;
  double mScaleY = 1.0;


  double getMinScrollX() {
    return mScaleX;
  }

  double _lastScale = 1.0;
  bool isScale = false, isDrag = false, isLongPress = false, isOnTap = false;

  @override
  void initState() {
    super.initState();
    mInfoWindowStream = StreamController<InfoWindowEntity?>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    mInfoWindowStream?.close();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.datas != null && widget.datas!.isEmpty) {
      mScrollX = mSelectX = 0.0;
      mScaleX = 1.0;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        mHeight = constraints.maxHeight;
        mWidth = constraints.maxWidth;

        return GestureDetector(
          onTapDown: widget.onTapDown,
          //屏蔽上下滑动
          // child: notworkBuild(
          //缩放，左右滑动
          child: horizontalBuild(
            child: longPressBuild(
              child: scaleBuild(
                //长按
                child: stackBuild(),
              ),
            ),
          ),
          // ),
        );
      },
    );
  }

  //屏蔽外部
  Widget notworkBuild({required Widget child}) {
    return GestureDetector(
      onVerticalDragCancel: () {},
      child: child,
    );
  }

  Widget scaleBuild({required Widget child}) {
    return XGestureDetector(
      behavior: HitTestBehavior.translucent,
      onScaleStart: (_) {
        isScale = true;
        notifyChanged();
      },
      onScaleUpdate: (details) {
        if (isLongPress) return;
        mScaleX = (_lastScale * details.scale).clamp(3 / 6, 5);
        notifyChanged();
      },
      onScaleEnd: () {
        isScale = false;
        _lastScale = mScaleX;
        notifyChanged();
      },
      child: child,
    );
  }

  Widget horizontalBuild({required Widget child}) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      dragStartBehavior: DragStartBehavior.start,
      onHorizontalDragDown: (details) {
        isOnTap = false;
        // _stopAnimation();
        _onDragChanged(true);
      },
      onHorizontalDragUpdate: (details) {
        if (isScale || isLongPress) return;
        mScrollX = ((details.primaryDelta ?? 0) / mScaleX + mScrollX).clamp(0.0, ChartPainter.maxScrollX).toDouble();
        notifyChanged();
      },
      onHorizontalDragEnd: (DragEndDetails details) {
        var velocity = details.velocity.pixelsPerSecond.dx;
        _onFling(velocity);
      },
      onHorizontalDragCancel: () => _onDragChanged(false),
      child: child,
    );
  }

  Widget longPressBuild({required Widget child}) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPressStart: (details) {
        isOnTap = false;
        isLongPress = true;
        widget.onShowInfo?.call(true);
        if ((mSelectX != details.localPosition.dx || mSelectY != details.globalPosition.dy) && !widget.isTrendLine) {
          mSelectX = details.localPosition.dx;
          notifyChanged();
        }
        //For TrendLine
        if (widget.isTrendLine && changeinXposition == null) {
          mSelectX = changeinXposition = details.localPosition.dx;
          mSelectY = changeinYposition = details.globalPosition.dy;
          notifyChanged();
        }
        //For TrendLine
        if (widget.isTrendLine && changeinXposition != null) {
          changeinXposition = details.localPosition.dx;
          changeinYposition = details.globalPosition.dy;
          notifyChanged();
        }
      },
      onLongPressMoveUpdate: (details) {
        if ((mSelectX != details.localPosition.dx || mSelectY != details.globalPosition.dy) && !widget.isTrendLine) {
          mSelectX = details.localPosition.dx;
          mSelectY = details.localPosition.dy;
          notifyChanged();
        }
        if (widget.isTrendLine) {
          mSelectX = mSelectX + (details.localPosition.dx - changeinXposition!);
          changeinXposition = details.localPosition.dx;
          mSelectY = mSelectY + (details.globalPosition.dy - changeinYposition!);
          changeinYposition = details.globalPosition.dy;
          notifyChanged();
        }
      },
      onLongPressEnd: (details) {
        isOnTap = true;
        isLongPress = false;
        notifyChanged();
      },
      child: child,
    );
  }

  Widget stackBuild() {
    return Stack(
      children: <Widget>[
        buildKlineView(mScaleX, mScrollX),
        _buildInfoDialog()
      ],
    );
  }

  Widget buildKlineView(double mscaleX, double mscrollX) {
    return CustomPaint(
      size: Size(double.infinity, double.infinity),
      painter: ChartPainter(
        widget.chartStyle,
        widget.chartColors,
        lines: lines, //For TrendLine
        xFrontPadding: widget.xFrontPadding,
        isTrendLine: widget.isTrendLine, //For TrendLine
        selectY: mSelectY, //For TrendLine
        datas: widget.datas,
        scaleX: mscaleX,
        scrollX: mscrollX,
        selectX: mSelectX,
        isLongPass: isLongPress,
        isOnTap: isOnTap,
        isTapShowInfoDialog: widget.isTapShowInfoDialog,
        mainState: widget.mainState,
        mainStates: widget.mainStates,
        volHidden: widget.volHidden,
        secondaryState: widget.secondaryState,
        secondaryStates: widget.secondaryStates,
        isLine: widget.isLine,
        hideGrid: widget.hideGrid,
        showNowPrice: widget.showNowPrice,
        sink: mInfoWindowStream?.sink,
        fixedLength: widget.fixedLength,
        maDayList: widget.maDayList,
        verticalTextAlignment: widget.verticalTextAlignment,
        showLineShader: widget.showLineShader,
        showTopDiv: widget.showTopDiv,
      ),
    );
  }

  void _stopAnimation({bool needNotify = true}) {
    if (_controller != null && _controller!.isAnimating) {
      _controller!.stop();
      _onDragChanged(false);
      if (needNotify) {
        notifyChanged();
      }
    }
  }

  void _onDragChanged(bool isOnDrag) {
    isDrag = isOnDrag;
    if (widget.isOnDrag != null) {
      widget.isOnDrag!(isDrag);
    }
  }

  void _onFling(double x) {
    _controller = AnimationController(duration: Duration(milliseconds: widget.flingTime), vsync: this);
    aniX = null;
    aniX = Tween<double>(begin: mScrollX, end: x * widget.flingRatio + mScrollX).animate(CurvedAnimation(parent: _controller!.view, curve: widget.flingCurve));
    aniX!.addListener(() {
      mScrollX = aniX!.value;
      if (mScrollX <= 0) {
        mScrollX = 0;
        if (widget.onLoadMore != null) {
          widget.onLoadMore!(true);
        }
        _stopAnimation();
      } else if (mScrollX >= ChartPainter.maxScrollX) {
        mScrollX = ChartPainter.maxScrollX;
        if (widget.onLoadMore != null) {
          widget.onLoadMore!(false);
        }
        _stopAnimation();
      }
      notifyChanged();
    });
    aniX!.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        _onDragChanged(false);
        notifyChanged();
      }
    });
    _controller!.forward();
  }

  void notifyChanged() => setState(() {});

  late List<String> infos;

  Widget _buildInfoDialog() {
    return StreamBuilder<InfoWindowEntity?>(
        stream: mInfoWindowStream?.stream,
        builder: (context, snapshot) {
          if (!widget.showInfoDialog ||
              (!isLongPress && !isOnTap) ||
              !snapshot.hasData ||
              snapshot.data?.kLineEntity == null) return Container();
          KlineEntity entity = snapshot.data!.kLineEntity;
          double upDown =  entity.close - entity.open;
          double upDownPercent =  (upDown / entity.open) * 100;
          infos = [
            getDate(entity.id),
            entity.open.toStringAsFixed(widget.fixedLength),
            entity.close.toStringAsFixed(widget.fixedLength),
            entity.high.toStringAsFixed(widget.fixedLength),
            entity.low.toStringAsFixed(widget.fixedLength),
            "${upDown > 0 ? "+" : ""}${upDown.toStringAsFixed(widget.fixedLength)}",
            "${upDownPercent > 0 ? "+" : ''}${upDownPercent.toStringAsFixed(2)}%",
            if (entity.vol != null) entity.vol.toStringAsFixed(widget.fixedLength)
          ];
          final dialogPadding = 4.0;
          final dialogWidth = mWidth / 3;
          return Container(
            margin: EdgeInsets.only(left: snapshot.data!.isLeft ? dialogPadding : mWidth - dialogWidth - dialogPadding, top: 25),
            width: dialogWidth,
            // height: 184,
            decoration: BoxDecoration(
              color: widget.chartColors.selectFillColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: widget.chartColors.infoBoxShadow,
              border: Border.all(color: widget.chartColors.selectBorderColor, width: 0.5),
            ),
            child: ListView.builder(
              padding: EdgeInsets.all(dialogPadding),
              itemCount: infos.length,
              itemExtent: 18.0,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final translations = widget.translations.of(context);

                return _buildItem(
                  infos[index],
                  translations.byIndex(index),
                );
              },
            ),
          );
        });
  }

  Widget _buildItem(String info, String infoName) {
    Color color = widget.chartColors.infoWindowNormalColor;
    if (info.startsWith("+"))
      color = widget.chartColors.infoWindowUpColor;
    else if (info.startsWith("-")) color = widget.chartColors.infoWindowDnColor;
    final infoWidget = Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(child: Text("$infoName", style: TextStyle(color: widget.chartColors.infoWindowTitleColor, fontSize: 10.0), maxLines: 1)),
        Text(info, style: TextStyle(color: color, fontSize: info.length < 15 ? 10.0 : 9)),
      ],
    );
    return widget.materialInfoDialog ? Material(color: Colors.transparent, child: infoWidget) : infoWidget;
  }

  String getDate(int? date) => dateFormat(DateTime.fromMillisecondsSinceEpoch(date ?? DateTime.now().millisecondsSinceEpoch), widget.timeFormat);
}
