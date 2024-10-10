

import 'k_entity.dart';

class KlineEntity extends KEntity {
  KlineEntity({
      num? amount, 
      num? close, 
      String? time, 
      num? high, 
      num? id, 
      num? idx, 
      num? low, 
      num? open, 
      num? vol,}){
    _amount = amount;
    _close = close;
    _time = time;
    _high = high;
    _id = id;
    _idx = idx;
    _low = low;
    _open = open;
    _vol = vol;
}

  KlineEntity.fromJson(dynamic json) {
    _amount = json['amount'];
    _close = json['close'];
    _time = json['time'];
    _high = json['high'];
    _id = json['id'];
    _idx = json['idx'];
    _low = json['low'];
    _open = json['open'];
    _vol = json['vol'];
  }
  num? _amount;
  num? _close;
  String? _time;
  num? _high;
  num? _id;
  num? _idx;
  num? _low;
  num? _open;
  num? _vol;
KlineEntity copyWith({  num? amount,
  num? close,
  String? time,
  num? high,
  num? id,
  num? idx,
  num? low,
  num? open,
  num? vol,
}) => KlineEntity(  amount: amount ?? _amount,
  close: close ?? _close,
  time: time ?? _time,
  high: high ?? _high,
  id: id ?? _id,
  idx: idx ?? _idx,
  low: low ?? _low,
  open: open ?? _open,
  vol: vol ?? _vol,
);
  num? get amount => _amount;
  double get close => _close?.toDouble()??0.0;
  String? get time => _time;
  double get high => _high?.toDouble()??0.0;
  num? get id => _id;
  num? get idx => _idx;
  double get low => _low?.toDouble()??0.0;
  double get open => _open?.toDouble()??0.0;
  double get vol => _vol?.toDouble()??0.0;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['amount'] = _amount;
    map['close'] = _close;
    map['time'] = _time;
    map['high'] = _high;
    map['id'] = _id;
    map['idx'] = _idx;
    map['low'] = _low;
    map['open'] = _open;
    map['vol'] = _vol;
    return map;
  }

}