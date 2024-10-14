import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kline_charts/charts/map_ext.dart';
import 'package:gesture_x_detector/gesture_x_detector.dart';

import '../bean/info_window_entity.dart';
import '../bean/kline_entity.dart';
import '../bean/kline_entity.dart';
import '../bean/kline_entity.dart';
import '../charts/chart_style.dart';
import '../charts/k_chart_animation_widget.dart';
import '../renderer/chart_painter.dart';
import '../renderer/main_renderer.dart';
import '../charts/chart_translations.dart';
import '../utils/date_format_util.dart';
import '../utils/enums.dart';

class KChartsPage extends StatefulWidget {
  final List<KlineEntity>? datas;
  final double? height;
  final ChartStyle? chartStyle;
  final ChartColors? chartColors;


  const KChartsPage(
    this.datas, {
    super.key,
    this.height = 300,
        this.chartStyle,
        this.chartColors,
  });

  @override
  _KChartsPageState createState() => _KChartsPageState();
}

class _KChartsPageState extends State<KChartsPage> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: double.infinity,
      child: KChartAnimationWidget(
        widget.datas ?? [],
        widget.chartStyle??ChartStyle(),
        widget.chartColors??ChartColors()

      ),
    );
  }
}
