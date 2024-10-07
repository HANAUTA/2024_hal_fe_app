import 'package:fe_project/pages/category_page.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          // 円グラフを表示
          SizedBox(
            height: 200, // グラフの高さを指定
            child: PieChart(
              PieChartData(
                sections: showingSections(),
                borderData: FlBorderData(show: false), // 境界線を非表示
                centerSpaceRadius: 40, // 中心のスペースを指定
              ),
            ),
          ),
          // カテゴリのリスト
          Expanded(
            child: ListView(
              children: [
                _buildCategoryTile("テクノロジー"),
                _buildCategoryTile("マネジメント"),
                _buildCategoryTile("ストラテジ"),
                _buildCategoryTile("全範囲から出題"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(String category) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16), // 外側の余白
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2), // ボーダーの色と幅
        borderRadius: BorderRadius.circular(8), // 角を丸める
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16), // パディングを追加
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CategoryPage(),
            ),
          );
        },
        title: Center(
          child: Text(
            category,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24, // フォントサイズを大きく
              fontWeight: FontWeight.bold, // 太字にする
            ),
          ),
        ),
        trailing: const Icon(Icons.keyboard_arrow_right), // アイコンを追加
      ),
    );
  }

  List<PieChartSectionData> showingSections() {
    final correctAnswers = 70; // 正解の数
    final incorrectAnswers = 30; // 不正解の数!!あとで変更必要!!

    return [
      PieChartSectionData(
        color: Colors.green,
        value: correctAnswers.toDouble(),
        title: '正解\n$correctAnswers%', // 緑の部分に「正解」と割合を表示
        radius: 50,
      ),
      PieChartSectionData(
        color: Colors.red,
        value: incorrectAnswers.toDouble(),
        title: '不正解\n$incorrectAnswers%', // 赤の部分に「不正解」と割合を表示
        radius: 50,
      ),
    ];
  }
}
