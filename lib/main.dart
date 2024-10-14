import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_kline_charts/view/k_chart_page.dart';

import 'bean/kline_data.dart';
import 'bean/kline_entity.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kine Charts',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("k线图"),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 500,
              child: Center(
                child: KChartsPage(
                  kData,
                  height:300.0+ 200.0 * proportion,
                ),
              ),
            ),
            Row(
              children: [
                const Text("  K线高度"),
                Expanded(
                  child: Slider(
                      value: proportion,
                      onChanged: (v) {
                        proportion = v;
                        updateUI();
                      }),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  ///k线数据源,继承KlineEntity(根据数据源自定义)
  var kData = <KLineData>[];

  ///k线高度控制器比例
  var proportion = 1.0;




  void updateUI() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    rootBundle.loadString('assets/kline_data.json').then((result) {
      List<KlineEntity> list = [...(json.decode(result)["data"] ?? []).map((o) => KlineEntity.fromJson(o))];
      kData = list.map((e) => KLineData(e)).toList();
      updateUI();
    });
  }
}
