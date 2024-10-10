import 'date_format_util.dart';

enum MainState { MA, EMA, BOLL, NONE }

enum SecondaryState { MACD, KDJ, RSI, WR, CCI, NONE }

class TimeFormat {
  static const List<String> YEAR_MONTH_DAY = [yyyy, '-', mm, '-', dd];
  static const List<String> YEAR_MONTH_DAY_WITH_HOUR = [yyyy, '-', mm, '-', dd, ' ', HH, ':', nn];
}
