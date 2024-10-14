import 'package:flutter/widgets.dart';

import 'chart_translations.dart';


extension ChartTranslationsMap on Map<String, ChartTranslations> {
  ChartTranslations of(BuildContext context) {
    // final locale = Localizations.localeOf(context);
    // final languageTag = '${locale.languageCode}_${locale.countryCode}';

    // return this[languageTag] ?? ChartTranslations();
    return ChartTranslations(
      date: '时间',
      open: '开盘',
      close: '收盘',
      high: '最高',
      low: '最低',
      changeAmount: '涨跌额',
      change: '涨跌幅',
      amount: '成交量',
    );
  }
}
