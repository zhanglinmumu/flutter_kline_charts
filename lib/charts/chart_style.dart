import 'package:flutter/material.dart' show BlurStyle, BoxShadow, Color, Colors, Offset, PaintingStyle;

class ChartColors {
  List<Color> bgColor = [Colors.transparent, Colors.transparent];
  // List<Color> bgColor = [Color(0xff18191d), Color(0xff18191d)];

  Color kLineColor = Color(0xFF717EF0);
  Color lineFillColor = Color(0xFF717EF0).withOpacity(0.2);
  Color lineFillInsideColor = Color(0xFF717EF0).withOpacity(0);

  List<Color> maColors = [
    Color(0xFFDAC087),
    Color(0xFF18C98A),
    Color(0xFFA71B60),
    Color(0xFFD081DB),
    Color(0xFF7473FF),
    Color(0xFFf47344),
    Color(0xFF447300),
  ];

  Color ma5Color = Color(0xFFDAC087);
  Color ma10Color = Color(0xFF18C98A);
  Color ma30Color = Color(0xFFD081DB);
  Color ma60Color = Color(0xFF7473FF);

  Color upColor = Color(0xFF18C98A);
  Color dnColor = Color(0xFFFE6965);

  Color volColor = Color(0xFF18C98A);
  Color vol5Color = Color(0xFF7473FF);
  Color vol10Color = Color(0xFFFFCD4D);
  Color get secUpColor => upColor.withOpacity(0.45); //= Color(0xffFEB4B2);
  Color get secDnColor => dnColor.withOpacity(0.45); //= Color(0xff8BE4C4);

  Color macdColor = Color(0xff4729AE);
  Color difColor = Color(0xFFFFCD4D);
  Color deaColor = Color(0xFF7473FF);

  Color kColor = Color(0xFFFFCD4D);
  Color dColor = Color(0xFF18C98A);
  Color jColor = Color(0xFF7473FF);
  Color rsiColor = Color(0xFFFFCD4D);

  Color defaultTextColor = Color(0xFF6C717F);

  Color nowPriceUpColor = Color(0xFF7473FF).withOpacity(0.1); // Color(0xFF18C98A);
  Color nowPriceDnColor = Color(0xFF7473FF).withOpacity(0.1); // Color(0xFFFE6965);
  Color nowPriceBgColor = Color(0xFF111111); // Color(0xFFFE6965);
  Color nowPriceBordColor = Color(0xFF7473FF); // Color(0xFFFE6965);
  Color nowDashColor = Color(0xFF7473FF);
  Color nowPriceTextColor = Color(0xFF7473FF);

  //深度颜色
  Color depthBuyColor = Color(0xFF18C98A);
  Color depthSellColor = Color(0xFFFE6965);

  //选中后显示值边框颜色
  Color selectBorderColor = Color(0x006C7A86).withOpacity(0);

  //选中后显示值背景的填充颜色
  Color selectFillColor = Color(0xFF2D3440);
  Color selectPriceFillColor = Color(0xFFFFFFFF);

  //分割线颜色
  Color gridColor = Color(0xFF181818);

  Color infoWindowNormalColor = Color(0xffffffff);
  Color infoWindowTitleColor = Color(0xffffffff);
  Color infoWindowUpColor = Color(0xFF18C98A);
  Color infoWindowDnColor = Color(0xFFFE6965);

  Color hCrossColor = Color(0xFF6C717F);
  Color vCrossColor = Color(0xFF6C717F);
  Color crossTextColor = Color(0xFF111111);

  //当前显示内最大和最小值的颜色
  Color maxColor = Color(0xffffffff);
  Color minColor = Color(0xffffffff);

  Color dotColor = const Color(0xFF3D3D3D);
  Color dotBgColor = const Color(0xFFD8D8D8);
  Color dotBorderColor = Colors.transparent;

  List<BoxShadow>? infoBoxShadow;

  Color dividerColor = const Color(0xFF6C717F).withOpacity(0.06);

  Color getMAColor(int index) {
    return maColors[index];
    // switch (index % 3) {
    //   case 1:
    //     return ma10Color;
    //   case 2:
    //     return ma30Color;
    //   default:
    //     return ma5Color;
    // }
  }

  Color getEMAColor(int index) {
    return maColors[index];
    // switch (index % 4) {
    //   case 1:
    //     return ma10Color;
    //   case 2:
    //     return ma30Color;
    //   case 3:
    //     return ma60Color;
    //   default:
    //     return ma5Color;
    // }
  }

  ChartColors();
  ChartColors.light() {
    defaultTextColor = const Color(0xFF888E9C);
    selectFillColor = const Color(0xFFF7F7F7);
    maxColor = const Color(0xFF9CA3A7);
    minColor = const Color(0xFF9CA3A7);
    infoWindowNormalColor = const Color(0xFF111111);
    infoWindowTitleColor = const Color(0xFF111111);
    selectPriceFillColor = const Color(0xFF3D3D3D);
    crossTextColor = const Color(0xFFFFFFFF);
    // gridColor = const Color(0xFFFF0000);
    gridColor = const Color(0xffE8E8EA);
    nowPriceBgColor = Colors.white;

    // nowPriceUpColor = const Color(0xFFFFFFFF);
    // nowPriceDnColor = const Color(0xFFFFFFFF);
    infoBoxShadow = [
      BoxShadow(offset: const Offset(0, 2), blurRadius: 4, color: const Color(0xff000000).withOpacity(0.12), blurStyle: BlurStyle.outer),
    ];
  }
  ChartColors copyWith({
    Color? upColor,
    Color? dnColor,
    Color? nowPriceTextColor,
    Color? nowDashColor,
    List<Color>? bgColor,
  }) {
    this.bgColor = bgColor ?? this.bgColor;
    this.upColor = upColor ?? this.upColor;
    this.dnColor = dnColor ?? this.dnColor;
    // nowPriceUpColor = this.upColor;
    // nowPriceDnColor = this.dnColor;
    this.nowDashColor = nowDashColor ?? this.nowDashColor;
    this.nowPriceTextColor = nowPriceTextColor ?? this.nowPriceTextColor;

    return this;
  }
}

class ChartStyle {
  double topPadding = 0.0;

  double bottomPadding = 10.0; //日期上移

  double childPadding = 12.0;

  //点与点的距离
  double pointWidth = 1.0;

  //蜡烛宽度
  double candleWidth = 6;
  //蜡烛圆角
  double candleRadius = 1;
  double volRadius = 0.5;

  //蜡烛中间线的宽度,上下影线
  double candleLineWidth = 1;

  //vol柱子宽度
  // double volWidth = 8.5;

  //macd柱子宽度
  // double macdWidth = 8.5;

  //垂直交叉线宽度
  double vCrossWidth = 0.5;

  //水平交叉线宽度
  double hCrossWidth = 0.5;

  //现在价格的线条长度
  double nowPriceLineLength = 4;

  //现在价格的线条间隔
  double nowPriceLineSpan = 2;

  //现在价格的线条粗细
  double nowPriceLineWidth = 1;
  //副图高度
  double? vheight = 25;

  int gridRows = 4;

  int gridColumns = 4;

  int pointColumns = 14;

  //下方時間客製化
  List<String>? dateTimeFormat;
//选中原点圆
  double dotRadius = 4;
  double dotBorderWidth = 1;
  double dotBgRadius = 8;

  ///k线空心实心
  PaintingStyle klineStyle = PaintingStyle.fill;

  ///时间组高度
  double dateHeight = 20;

  ///指标按钮组高度
  double btnsHeight = 30;
}
