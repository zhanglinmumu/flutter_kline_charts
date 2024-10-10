import 'dart:math';

import '../bean/kline_entity.dart';


class DataUtil {
  static calculate(
    List<KlineEntity> dataList, {
    List<int> maDayList = const [5, 10, 20],
    int n = 20,
    k = 2,
    List<int> emaDayList = const [5, 10, 20, 60],
    int shortPeriod = 12,
    int longPeriod = 26,
    int signalPeriod = 9,
    int kdjN = 9,
    int kdjM1 = 3,
    int kdjM2 = 3,
    int rsiPeriod = 14,
    int wrPeriod = 14,
    int volMa1 = 5,
    int volMa2 = 10,
  }) {
    calcEMA(dataList, emaDayList);
    calcMA(dataList, maDayList);
    calcBOLL(dataList, n, k);
    calcVolumeMA(dataList, volMa1: volMa1, volMa2: volMa2);
    calcKDJ(dataList, kdjN: kdjN, kdjM1: kdjM1, kdjM2: kdjM2);
    calcMACD(dataList, shortPeriod: shortPeriod, longPeriod: longPeriod, signalPeriod: signalPeriod);
    calcRSI(dataList, rsiPeriod: rsiPeriod);
    calcWR(dataList, wrPeriod: wrPeriod);
    calcCCI(dataList);
  }

  static calcEMA(List<KlineEntity> dataList, List<int> maDayList) {
    for (int j = 0; j < maDayList.length; j++) {
      var maDay = maDayList[j];
      // for (int maDay in maDayList) {
      for (int i = 0; i < dataList.length; i++) {
        KlineEntity entity = dataList[i];
        entity.emaValueList ??= List.filled(maDayList.length, 0.0);
        if (i >= maDay - 1) {
          List<double> prices = dataList.sublist(i - maDay + 1, i + 1).map((e) => e.close).toList();
          double ema = calcSingleEMA(prices, maDay);
          entity.emaValueList?[j] = ema;
        } else {
          entity.emaValueList?[j] = 0.0; // 前几个周期的 EMA 值暂时设为0
        }
      }
    }
  }

  static double calcSingleEMA(List<double> prices, int maDay) {
    double alpha = 2 / (maDay + 1);
    double ema = prices.reduce((a, b) => a + b) / maDay;

    for (int i = maDay; i < prices.length; i++) {
      ema = alpha * prices[i] + (1 - alpha) * ema;
    }

    return ema;
  }

  static calcMA(List<KlineEntity> dataList, List<int> maDayList) {
    List<double> ma = List<double>.filled(maDayList.length, 0);

    if (dataList.isNotEmpty) {
      for (int i = 0; i < dataList.length; i++) {
        KlineEntity entity = dataList[i];
        final closePrice = entity.close;
        entity.maValueList = List<double>.filled(maDayList.length, 0);

        for (int j = 0; j < maDayList.length; j++) {
          ma[j] += closePrice;
          if (i == maDayList[j] - 1) {
            entity.maValueList?[j] = ma[j] / maDayList[j];
          } else if (i >= maDayList[j]) {
            ma[j] -= dataList[i - maDayList[j]].close;
            entity.maValueList?[j] = ma[j] / maDayList[j];
          } else {
            entity.maValueList?[j] = 0;
          }
        }
      }
    }
  }

  static void calcBOLL(List<KlineEntity> dataList, int n, int k) {
    _calcBOLLMA(n, dataList);
    for (int i = 0; i < dataList.length; i++) {
      KlineEntity entity = dataList[i];
      if (i >= n) {
        double md = 0;
        for (int j = i - n + 1; j <= i; j++) {
          double c = dataList[j].close;
          double m = entity.BOLLMA!;
          double value = c - m;
          md += value * value;
        }
        md = md / (n - 1);
        md = sqrt(md);
        entity.mb = entity.BOLLMA!;
        entity.up = entity.mb! + k * md;
        entity.dn = entity.mb! - k * md;
      }
    }
  }

  static void _calcBOLLMA(int day, List<KlineEntity> dataList) {
    double ma = 0;
    for (int i = 0; i < dataList.length; i++) {
      KlineEntity entity = dataList[i];
      ma += entity.close;
      if (i == day - 1) {
        entity.BOLLMA = ma / day;
      } else if (i >= day) {
        ma -= dataList[i - day].close;
        entity.BOLLMA = ma / day;
      } else {
        entity.BOLLMA = null;
      }
    }
  }

  static void calcMACD(List<KlineEntity> dataList, {int shortPeriod = 12, int longPeriod = 26, int signalPeriod = 9}) {
    double ema12 = 0;
    double ema26 = 0;
    double dif = 0;
    double dea = 0;
    double macd = 0;

    for (int i = 0; i < dataList.length; i++) {
      KlineEntity entity = dataList[i];
      final closePrice = entity.close;
      if (i == 0) {
        ema12 = closePrice;
        ema26 = closePrice;
      } else {
        // EMA（12） = 前一日EMA（12） X 11/13 + 今日收盘价 X 2/13
        ema12 = ema12 * (shortPeriod - 1) / (shortPeriod + 1) + closePrice * 2 / (shortPeriod + 1);
        // EMA（26） = 前一日EMA（26） X 25/27 + 今日收盘价 X 2/27
        ema26 = ema26 * (longPeriod - 1) / (longPeriod + 1) + closePrice * 2 / (longPeriod + 1);
      }
      // DIF = EMA（12） - EMA（26） 。
      // 今日DEA = （前一日DEA X 8/10 + 今日DIF X 2/10）
      // 用（DIF-DEA）*2即为MACD柱状图。
      dif = ema12 - ema26;
      dea = dea * (signalPeriod - 1) / (signalPeriod + 1) + dif * 2 / (signalPeriod + 1);
      macd = (dif - dea) * 2;
      entity.dif = dif;
      entity.dea = dea;
      entity.macd = macd;
    }
  }

  static void calcVolumeMA(List<KlineEntity> dataList, {int volMa1 = 5, int volMa2 = 10}) {
    double volumeMa5 = 0;
    double volumeMa10 = 0;

    for (int i = 0; i < dataList.length; i++) {
      KlineEntity entry = dataList[i];

      volumeMa5 += entry.vol;
      volumeMa10 += entry.vol;

      if (i == volMa1 - 1) {
        entry.MA5Volume = (volumeMa5 / volMa1);
      } else if (i > volMa1 - 1) {
        volumeMa5 -= dataList[i - volMa1].vol;
        entry.MA5Volume = volumeMa5 / volMa1;
      } else {
        entry.MA5Volume = 0;
      }

      if (i == volMa2 - 1) {
        entry.MA10Volume = volumeMa10 / volMa2;
      } else if (i > volMa2 - 1) {
        volumeMa10 -= dataList[i - volMa2].vol;
        entry.MA10Volume = volumeMa10 / volMa2;
      } else {
        entry.MA10Volume = 0;
      }
    }
  }

  static void calcRSI(List<KlineEntity> dataList, {int rsiPeriod = 14}) {
    double? rsi;
    double rsiABSEma = 0;
    double rsiMaxEma = 0;
    for (int i = 0; i < dataList.length; i++) {
      KlineEntity entity = dataList[i];
      final double closePrice = entity.close;
      if (i == 0) {
        rsi = 0;
        rsiABSEma = 0;
        rsiMaxEma = 0;
      } else {
        double rMax = max(0, closePrice - dataList[i - 1].close.toDouble());
        double rAbs = (closePrice - dataList[i - 1].close.toDouble()).abs();

        rsiMaxEma = (rMax + (rsiPeriod - 1) * rsiMaxEma) / rsiPeriod;
        rsiABSEma = (rAbs + (rsiPeriod - 1) * rsiABSEma) / rsiPeriod;
        rsi = (rsiMaxEma / rsiABSEma) * 100;
      }
      if (i < (rsiPeriod - 1)) rsi = null;
      if (rsi != null && rsi.isNaN) rsi = null;
      entity.rsi = rsi;
    }
  }

  static void calcKDJ(List<KlineEntity> dataList, {int kdjN = 9, int kdjM1 = 3, int kdjM2 = 3}) {
    var preK = 50.0;
    var preD = 50.0;
    final tmp = dataList.first;
    tmp.k = preK;
    tmp.d = preD;
    tmp.j = 50.0;
    for (int i = 1; i < dataList.length; i++) {
      final entity = dataList[i];
      final n = max(0, i - kdjN + 1);
      var low = entity.low;
      var high = entity.high;
      for (int j = n; j < i; j++) {
        final t = dataList[j];
        if (t.low < low) {
          low = t.low;
        }
        if (t.high > high) {
          high = t.high;
        }
      }
      final cur = entity.close;
      var rsv = (cur - low) * 100.0 / (high - low);
      rsv = rsv.isNaN ? 0 : rsv;
      final k = ((kdjM1 - 1) * preK + rsv) / kdjM1;
      final d = ((kdjM2 - 1) * preD + k) / kdjM2;
      final j = 3 * k - 2 * d;
      preK = k;
      preD = d;
      entity.k = k;
      entity.d = d;
      entity.j = j;
    }
  }

  static void calcWR(List<KlineEntity> dataList, {int wrPeriod = 14}) {
    double r;
    for (int i = 0; i < dataList.length; i++) {
      KlineEntity entity = dataList[i];
      int startIndex = i - wrPeriod;
      if (startIndex < 0) {
        startIndex = 0;
      }
      double max14 = double.minPositive;
      double min14 = double.maxFinite;
      for (int index = startIndex; index <= i; index++) {
        max14 = max(max14, dataList[index].high);
        min14 = min(min14, dataList[index].low);
      }
      if (i < (wrPeriod - 1)) {
        entity.r = -10;
      } else {
        r = -100 * (max14 - dataList[i].close) / (max14 - min14);
        if (r.isNaN) {
          entity.r = null;
        } else {
          entity.r = r;
        }
      }
    }
  }

  static void calcCCI(List<KlineEntity> dataList) {
    final size = dataList.length;
    final count = 14;
    for (int i = 0; i < size; i++) {
      final kline = dataList[i];
      final tp = (kline.high + kline.low + kline.close) / 3;
      final start = max(0, i - count + 1);
      var amount = 0.0;
      var len = 0;
      for (int n = start; n <= i; n++) {
        amount += (dataList[n].high + dataList[n].low + dataList[n].close) / 3;
        len++;
      }
      final ma = amount / len;
      amount = 0.0;
      for (int n = start; n <= i; n++) {
        amount += (ma - (dataList[n].high + dataList[n].low + dataList[n].close) / 3).abs();
      }
      final md = amount / len;
      kline.cci = ((tp - ma) / 0.015 / md);
      if (kline.cci!.isNaN) {
        kline.cci = 0.0;
      }
    }
  }
}
