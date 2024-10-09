import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      body: Container(),
    );
  }

  ///k线数据源,继承KlineEntity(根据数据源自定义)
  var kData = <KLineData>[];

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
