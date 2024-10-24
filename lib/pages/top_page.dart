import 'package:fe_project/pages/settings_page.dart';
import 'package:fe_project/services/database/quiz_data.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestoreをインポート
import 'package:fe_project/pages/category_page.dart';
import 'question_page.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<bool> _isTappedList = List.generate(4, (index) => false); // リスト要素の状態を管理
  Database? _database; // データベースのインスタンス
  List<Map<String, dynamic>> quizDataList = []; // ローカルDBから取得したクイズデータ
  int totalQuestionsCount = 1;
  int correctAnswersCount = 20;
  int wrongAnswersCount = 0;
  int totalAnswersCount = 0;
  double correctProgress = 0; // 正解進捗率
  double wrongProgress = 0; // 不正解進捗率
  bool isLoading = true; // ローディング状態の管理
  bool _isFirstLaunch = true; // 初回起動のフラグ
  var quizDataInstance = QuizData();

  @override
  void initState() {
    super.initState();
    _initQuizData(); // DBの初期化とデータ取得を実行
  }

  Future<void> _initQuizData() async {
    await quizDataInstance.initDb();
    List<Map<String, dynamic>> maps = await quizDataInstance.getAllQuizData(isFirstLaunch: _isFirstLaunch);
    _isFirstLaunch = false;

    setState(() {
      quizDataList = maps; // 取得したデータを設定
      totalQuestionsCount = maps.length; // クイズの総数を設定
      isLoading = false; // データが読み込まれたらローディング状態を更新
    });
    setProgress();
  }

  Future<void> setProgress() async {
    Map<String, dynamic> progressData = await quizDataInstance.getProgress(quizDataList: quizDataList);
    // 進捗を計算（judgeが2の問題数）
    setState(() {
      correctAnswersCount = progressData['correctAnswersCount'];
      wrongAnswersCount = progressData['wrongAnswersCount'];
      correctProgress = progressData['correctProgress'];
      wrongProgress = progressData['wrongProgress'];
      totalAnswersCount = progressData['totalAnswersCount'];
    });
  }

  @override
  Widget build(BuildContext context) {
    // 画面の高さと幅を取得
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // 画面が小さい場合の最低限のサイズを設定
    final double adjustedScreenHeight = screenHeight < 600 ? 600 : screenHeight;
    final double adjustedScreenWidth = screenWidth < 300 ? 300 : screenWidth;

    return Scaffold(
      backgroundColor: const Color(0xFFE4F9F5),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),

            onPressed: () async {
              // 設定ページへの遷移
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(), // 設定ページに遷移
                ),
              );
              _initQuizData();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          color: const Color(0xFFFAF8F1), // SafeAreaの背景色を設定
          child: isLoading
              ? Center(
            child: CircularProgressIndicator(), // ローディングインジケーターを表示
          )
              : Column(
            mainAxisAlignment: MainAxisAlignment.center, // 縦方向に中央揃え
            children: [
              // 正解数と進捗バーを表示
              Padding(
                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.05),
                child: Column(
                  children: [
                    Text(
                      '学習数 $totalAnswersCount / $totalQuestionsCount 問中',
                      style: TextStyle(
                        fontSize: screenHeight * 0.03, // フォントサイズを画面高さに基づいて指定
                        color: Color(0xFF674822), // 色を少しソフトに
                        fontWeight: FontWeight.bold, // フォントを少し太く
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.01), // 少しスペースを追加
                    Text(
                      "正解: ${(correctProgress * 100).toInt()}%  不正解: ${(wrongProgress * 100).toInt()}%",
                      style: TextStyle(
                        fontSize: screenHeight * 0.025,
                        color: Colors.black54, // テキストの色を少し薄く
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.03), // 高さを調整
                    SizedBox(
                      width: screenWidth * 0.85, // バーの幅を少し広げる
                      height: screenHeight * 0.035, // バーの高さを少し高く
                      child: Stack(
                        children: [
                          Container(
                            width: screenWidth * 0.85,
                            height: screenHeight * 0.035,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8), // 角を丸める
                              border: Border.all(
                                color: Colors.grey.shade300, // 薄いグレーの枠線
                                width: 1,
                              ),
                            ),
                          ),
                          // 背景の白いバー
                          Container(
                            width: screenWidth * 0.85,
                            height: screenHeight * 0.035,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: const Color(0xFFF0F0F0), // 薄いグレーの背景
                            ),
                          ),
                          // 不正解の赤いバー
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            width: screenWidth * 0.85 * (correctProgress + wrongProgress),
                            height: screenHeight * 0.035,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: const Color(0xFFC58940),
                            ),
                          ),
                          // 正解の緑色のバー
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            width: screenWidth * 0.85 * correctProgress,
                            height: screenHeight * 0.035,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26, // バーに影を追加
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                              color: const Color(0xFFE5BA73),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                  ],
                ),
              ),

              // カテゴリのリスト
              Expanded(
                child: Scrollbar(
                  thickness: 8,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCategoryTile(
                            screenWidth, screenHeight, "テクノロジー系", 0, context, "technologyStage"),
                        _buildCategoryTile(
                            screenWidth, screenHeight, "マネジメント系", 1, context, "managementStage"),
                        _buildCategoryTile(
                            screenWidth, screenHeight, "ストラテジ系", 2, context, "strategyStage"),
                        _buildCategoryTile(
                            screenWidth, screenHeight, "全範囲から出題", 3, context, "allStage"),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTile(
      double screenWidth,
      double screenHeight,
      String displayCategoryName,
      int index,
      BuildContext context,
      String categoryName) {

    return AnimationConfiguration.staggeredList(
      position: index,
      duration: const Duration(milliseconds: 375),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: GestureDetector(
            onTapDown: (_) {
              setState(() {
                _isTappedList[index] = true;
              });
            },
            onTapUp: (_) async {
              setState(() {
                _isTappedList[index] = false;
              });

              // 遷移処理
              if (categoryName == "allStage" || categoryName == "wrongStage") {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuestionPage(categoryName),
                  ),
                );
              } else {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryPage(categoryName),
                  ),
                );
              }
              _initQuizData();
            },
            onTapCancel: () {
              setState(() {
                _isTappedList[index] = false;
              });
            },
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.1, vertical: screenHeight * 0.02),
              child: Material(
                elevation: 3, // 影を追加
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.03),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        offset: Offset(0, 4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      displayCategoryName,
                      style: TextStyle(
                        fontSize: screenHeight * 0.025,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF674822),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
