

import 'KLineData.dart';
import 'kline_entity.dart';

class KLineData extends KlineEntity implements IKlineModel, IKlineMaModel {
  @override
  double? ma5;
  @override
  double? ma10;
  @override
  double? ma20;
  @override
  double? ma30;

  KLineData(KlineEntity e) : super.fromJson(e.toJson());

  @override
  String? get dateString => time;
  @override
  num get volume => vol!;

  @override
  DateTime get date => DateTime.parse(time!);

  @override
  bool get isBull => open! <= close!;
}
