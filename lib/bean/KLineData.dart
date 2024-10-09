abstract class IKlineModel {
  num? get close;
  String? get dateString;
  num? get high;
  num? get low;
  num? get open;
  num? get vol;
  DateTime get date;
}

abstract class IKlineMaModel {
  double? ma5;
  double? ma10;
  double? ma20;
  // double? ma30;
}
