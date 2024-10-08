import 'package:fe_project/pages/category_page.dart';
import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final int correctAnswers = 250; // 正解数
  final int totalQuestions = 500; // 総問題数
  List<bool> _isTappedList = List.generate(4, (index) => false); // リスト要素の状態を管理

  @override
  Widget build(BuildContext context) {
    // 画面の高さと幅を取得
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    double progress = correctAnswers / totalQuestions; // 進捗を計算

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Container(
          color: const Color(0xFFE4F9F5), // SafeAreaの背景色を設定
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // 縦方向に中央揃え
            children: [
              // 正解数と進捗バーを表示
              Padding(
                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.05),
                child: Column(
                  children: [
                    Text(
                      '正解数 $correctAnswers / $totalQuestions 問中',
                      style: TextStyle(
                        fontSize: screenHeight * 0.03, // フォントサイズを画面高さに基づいて指定
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    SizedBox(
                      width: screenWidth * 0.8, // バーの幅
                      height: screenHeight * 0.03, // バーの高さ
                      child: Stack(
                        children: [
                          Container(
                            width: screenWidth * 0.8,
                            height: screenHeight * 0.03,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black, width: 0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: progress, // 進捗率に基づいてバーの幅を調整
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(width: 0),
                                borderRadius: BorderRadius.circular(10),
                                color: const Color(0xFF30E3CA),
                              ),
                              // 正解の進捗部分の色
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    // 50%と100%のラベル表示
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Spacer(),
                          Text('50%'),
                          Spacer(),
                          Text('100%'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // カテゴリのリスト
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCategoryTile(screenWidth, screenHeight, "テクノロジー", 0),
                    _buildCategoryTile(screenWidth, screenHeight, "マネジメント", 1),
                    _buildCategoryTile(screenWidth, screenHeight, "ストラテジ", 2),
                    _buildCategoryTile(screenWidth, screenHeight, "全範囲から出題", 3),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTile(double screenWidth, double screenHeight, String category, int index) {
    return GestureDetector(
      onTapDown: (_) {
        // タップしたらスケールを1.05倍に拡大
        setState(() {
          _isTappedList[index] = true;
        });
      },
      onTapUp: (_) {
        // タップを離したら元のスケールに戻す
        setState(() {
          _isTappedList[index] = false;
        });
        // ページ遷移
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CategoryPage(), // カテゴリページに遷移
          ),
        );
      },
      onTapCancel: () {
        // タップがキャンセルされたら元のスケールに戻す
        setState(() {
          _isTappedList[index] = false;
        });
      },
      child: AnimatedScale(
        scale: _isTappedList[index] ? 1.05 : 1.0, // タップ時に1.05倍、通常時は1.0
        duration: const Duration(milliseconds: 200), // スケールのアニメーション時間
        child: FractionallySizedBox(
          widthFactor: 0.8, // 全体の80%の幅を指定
          child: Container(
            margin: EdgeInsets.symmetric(vertical: screenHeight * 0.01), // 上下の余白
            decoration: BoxDecoration(
              color: Colors.white, // 背景色を白に設定
              border: Border.all(color: const Color(0xFF11999E), width: 2), // ボーダーの色と幅
              borderRadius: BorderRadius.circular(20), // 角を丸める
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(
                vertical: screenHeight * 0.02, // パディングを画面高さに基づいて指定
                horizontal: screenWidth * 0.04, // 横方向のパディングを画面幅に基づいて指定
              ),
              title: Center(
                child: Text(
                  category,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenHeight * 0.03, // フォントサイズを画面高さに基づいて指定
                  ),
                ),
              ),
              trailing: const Icon(Icons.keyboard_arrow_right), // アイコンを追加
            ),
          ),
        ),
      ),
    );
  }
}
