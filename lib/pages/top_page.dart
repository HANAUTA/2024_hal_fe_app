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
    // 画面の高さと幅を取得
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 円グラフを表示
            SizedBox(
              height: screenHeight * 0.25, // 画面の高さの25%を使用
              child: PieChart(
                PieChartData(
                  sections: showingSections(),
                  borderData: FlBorderData(show: false), // 境界線を非表示
                  centerSpaceRadius: screenHeight * 0.05, // 画面高さに対してスペースを指定
                ),
              ),
            ),
            // カテゴリのリスト
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCategoryTile(screenWidth, screenHeight, "テクノロジー"),
                  _buildCategoryTile(screenWidth, screenHeight, "マネジメント"),
                  _buildCategoryTile(screenWidth, screenHeight, "ストラテジ"),
                  _buildCategoryTile(screenWidth, screenHeight, "全範囲から出題"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 引数でscreenWidthとscreenHeightを渡す
  Widget _buildCategoryTile(double screenWidth, double screenHeight, String category) {
    return FractionallySizedBox(
      widthFactor: 0.8, // 全体の80%の幅を指定
      child: Container(
        margin: EdgeInsets.symmetric(vertical: screenHeight * 0.01), // 外側の上下の余白を画面高さに基づいて指定
        decoration: BoxDecoration(
          border: Border.all(color: Colors.lightGreen, width: 2), // ボーダーの色と幅
          borderRadius: BorderRadius.circular(8), // 角を丸める
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
            vertical: screenHeight * 0.02, // パディングを画面高さに基づいて指定
            horizontal: screenWidth * 0.04, // 横方向のパディングを画面幅に基づいて指定
          ),
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
                fontSize: screenHeight * 0.03, // フォントサイズを画面高さに基づいて指定
                fontWeight: FontWeight.bold, // 太字にする
              ),
            ),
          ),
          trailing: const Icon(Icons.keyboard_arrow_right), // アイコンを追加
        ),
      ),
    );
  }

  List<PieChartSectionData> showingSections() {
    final correctAnswers = 70; // 正解の数
    final incorrectAnswers = 30; // 不正解の数

    return [
      PieChartSectionData(
        color: Colors.green,
        value: correctAnswers.toDouble(),
        title: '正解\n$correctAnswers%', // 緑の部分に「正解」と割合を表示
        radius: 40, // 円グラフのセクションのサイズを調整
      ),
      PieChartSectionData(
        color: Colors.red,
        value: incorrectAnswers.toDouble(),
        title: '不正解\n$incorrectAnswers%', // 赤の部分に「不正解」と割合を表示
        radius: 40, // 円グラフのセクションのサイズを調整
      ),
    ];
  }
}
