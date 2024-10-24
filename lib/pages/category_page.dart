import 'package:fe_project/constants/category_data.dart';
import 'package:fe_project/pages/question_page.dart';
import 'package:fe_project/services/database/quiz_data.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class CategoryPage extends StatefulWidget {
  final String categoryId;

  const CategoryPage(this.categoryId, {super.key});

  @override
  _CategoryPageState createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  Database? _database; // データベースのインスタンス
  List<Map<String, dynamic>> quizDataList = [];
  double correctProgress = 0.0; // 正解進捗率
  double wrongProgress = 0.0; // 正解進捗率
  int correctAnswersCount = 5; // 正解数
  int wrongAnswersCount = 5; // 不正解数
  int totalAnswersCount = 0; // 総回答数
  int totalQuestionsCount = 0; // 総問題数
  int itemCount = 0; // カテゴリーごとの問題数
  int correctCount = 0; // カテゴリーごとの正解数
  var quizDataInstance = QuizData(); // クイズデータのインスタンス

  // `categoryName`をクラスのメンバーとして定義
  String? categoryName;
  List<dynamic> erroList = [];
  Map<String, String> categoryNumMap = CategoryData.categoryNumMap;

  Map<String, int> seriesCount = {
    "テクノロジー系まとめ": 0,
    "基礎理論": 0,
    "アルゴリズムとプログラミング": 0,
    "コンピュータ構成要素": 0,
    "システム構成要素": 0,
    "ソフトウェア": 0,
    "ハードウェア": 0,
    "ヒューマンインターフェイス": 0,
    "マルチメディア": 0,
    "データベース": 0,
    "ネットワーク": 0,
    "セキュリティ": 0,
    "システム開発技術": 0,
    "ソフトウェア開発管理技術": 0,
    "ストラテジ系まとめ": 0,
    "システム戦略": 0,
    "システム企画": 0,
    "経営戦略マネジメント": 0,
    "技術戦略マネジメント": 0,
    "ビジネスインダストリ": 0,
    "企業活動": 0,
    "法務": 0,
    "マネジメント系まとめ": 0,
    "プロジェクトマネジメント": 0,
    "サービスマネジメント": 0,
    "システム監査": 0,
  };

  Map<String, int> seriesCorrectCount = {
    "テクノロジー系まとめ": 0,
    "基礎理論": 0,
    "アルゴリズムとプログラミング": 0,
    "コンピュータ構成要素": 0,
    "システム構成要素": 0,
    "ソフトウェア": 0,
    "ハードウェア": 0,
    "ヒューマンインターフェイス": 0,
    "マルチメディア": 0,
    "データベース": 0,
    "ネットワーク": 0,
    "セキュリティ": 0,
    "システム開発技術": 0,
    "ソフトウェア開発管理技術": 0,
    "ストラテジ系まとめ": 0,
    "システム戦略": 0,
    "システム企画": 0,
    "経営戦略マネジメント": 0,
    "技術戦略マネジメント": 0,
    "ビジネスインダストリ": 0,
    "企業活動": 0,
    "法務": 0,
    "マネジメント系まとめ": 0,
    "プロジェクトマネジメント": 0,
    "サービスマネジメント": 0,
    "システム監査": 0,
  };

  // カテゴリー名のマップを定義
  final Map<String, List<String>> categoryMap = CategoryData.categoryMap;

  bool _isLoading = true; // ローディングフラグ

  // ローカルデータベースを初期化し、クイズデータを取得
  Future<void> _initDbAndFetchData() async {
    setState(() {
      _isLoading = true; // データ取得開始時にローディングを開始
    });
    // データベースを初期化
    await quizDataInstance.initDb();
    
    await loadQuizData(); // ローカルDBからデータを読み込み
    setProgress();
    setState(() {
      _isLoading = false; // データ取得終了時にローディングを終了
    });
  }
  

  // ローカルDBからクイズデータを取得
  Future<void> loadQuizData() async {
    // カテゴリーに応じてクエリを変更
    final List<Map<String, dynamic>> maps;
    maps = await quizDataInstance.getTargetQuizData(targetCategory: widget.categoryId);

    setState(() {
      quizDataList = maps; // 取得したデータを設定
      if (quizDataList.isNotEmpty) {
        print('Loaded ${quizDataList.length} quizzes.');
      } else {
        print('No quiz data found.');
      }

      // クイズデータをシリーズごとに分類
      countQuiz();
    });
  }

  // クイズデータを `series_name` ごとに分類
  Future<void> countQuiz() async {
    // カテゴリーと対応するマップの定義
    Map<String, String> categoryKeyMap = {
      'technologyStage': 'テクノロジー系',
      'managementStage': 'マネジメント系',
      'strategyStage': 'ストラテジ系',
    };

    // categoryId に基づいてシリーズを取得
    String? categoryKey = categoryKeyMap[widget.categoryId];
    if (categoryKey != null) {
      List<String> seriesList = categoryMap[categoryKey]!;

      for (String series in seriesList) {
        if (series.contains("間違えた")) {
          continue;
        }

        String seriesNum = categoryNumMap[series]!;

        int count = quizDataList
            .where((quiz) => quiz['series_document_id'].startsWith(seriesNum))
            .length;
        seriesCount[series] = count;
      }
    }
  }

  // データを設定
  Future<void> setCategoryData() async {
    const Map<String, String> categoryNameMap = {
      "technologyStage": "テクノロジー系",
      "managementStage": "マネジメント系",
      "strategyStage": "ストラテジ系",
    };

    // widget.categoryIdを使用してカテゴリ名を取得
    setState(() {
      categoryName = categoryNameMap[widget.categoryId]; // クラスの状態に保存
    });
  }

  Future<void> setProgress() async {
    List<String> seriesList = [];
    Map<String, String> categoryKeyMap = {
      'technologyStage': 'テクノロジー系',
      'managementStage': 'マネジメント系',
      'strategyStage': 'ストラテジ系',
    };

    // categoryId に基づいてシリーズを取得
    String? categoryKey = categoryKeyMap[widget.categoryId];
    // 進捗を計算（judgeが2の問題数）
    setState(() {
      if (categoryKey != null) {
        seriesList = categoryMap[categoryKey]!;
        for (String series in seriesList) {

          int correctCount = quizDataList
              .where(
                  (quiz) => quiz['series_name'] == series && quiz['judge'] == 2)
              .length;
          seriesCorrectCount[series] = correctCount;
        }
      }

      correctAnswersCount = quizDataList.where((quiz) => quiz['judge'] == 2).length;
      wrongAnswersCount = quizDataList.where((quiz) => quiz['judge'] == 1).length;
      seriesCorrectCount[seriesList[0]] = correctAnswersCount;
      correctProgress =
          totalQuestionsCount > 0 ? correctAnswersCount / totalQuestionsCount : 0; // 進捗を計算
      wrongProgress =
          totalQuestionsCount > 0 ? wrongAnswersCount / totalQuestionsCount : 0; // 進捗を計算
      totalAnswersCount = correctAnswersCount + wrongAnswersCount;
    });
  // print(correctProgress);
  // print(wrongProgress);
  }

  @override
  void initState() {
    super.initState();
    _initDbAndFetchData(); // DBの初期化とデータ取得を実行
    setCategoryData();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // カテゴリーごとに総問題数を計算
    if (categoryName == "テクノロジー系") {
      totalQuestionsCount = seriesCount["テクノロジー系まとめ"]!; // 総問題数
    } else if (categoryName == "ストラテジ系") {
      totalQuestionsCount = seriesCount["ストラテジ系まとめ"]!; // 総問題数
    } else if (categoryName == "マネジメント系") {
      totalQuestionsCount = seriesCount["マネジメント系まとめ"]!; // 総問題数
    }

    setProgress();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(categoryName ?? ''), // カテゴリ名を表示
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: const Color(0xFFFAF8F1), // SafeAreaの背景色を設定
              child: Column(
                children: [
                  // 正解数と進捗バーを表示
                  Padding(
                    padding:
                    EdgeInsets.symmetric(vertical: screenHeight * 0.05),
                    child: Column(
                      children: [
                        Text(
                          '学習数 $totalAnswersCount / $totalQuestionsCount 問中',
                          style: TextStyle(
                            fontSize:
                            screenHeight * 0.03, // フォントサイズを画面高さに基づいて指定
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text("正解: ${(correctProgress * 100).toInt()}%  不正解: ${(wrongProgress * 100).toInt()}%",
                            style: TextStyle(
                              fontSize: screenHeight * 0.025,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center),
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
                                  border: Border.all(
                                      color: Colors.black, width: 0),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              // アニメーション付きのバー
                              Container(
                                // アニメーションの時間
                                width: screenWidth * 0.8,
                                // 進捗率に基づいてバーの幅を調整
                                height: screenHeight * 0.03,
                                decoration: BoxDecoration(
                                  border: Border.all(width: 0),
                                  color: const Color(0xFFFFFF),
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                // アニメーションの時間
                                width: screenWidth * 0.8 * (correctProgress + wrongProgress),
                                // 進捗率に基づいてバーの幅を調整
                                height: screenHeight * 0.03,
                                decoration: BoxDecoration(
                                  border: Border.all(width: 0),
                                  color: const Color(0xFFFF6969),
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                // アニメーションの時間
                                width: screenWidth * 0.8 * correctProgress,
                                // 進捗率に基づいてバーの幅を調整
                                height: screenHeight * 0.03,
                                decoration: BoxDecoration(
                                  border: Border.all(width: 0),
                                  color: const Color(0xFF11999E),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
// 50%と100%のラベルは削除、必要に応じて保持可能
                      ],
                    ),
                  ),
                  // カテゴリーリスト
                  if (categoryName != null) // categoryNameがnullでないときに表示
                    Expanded(
                      child: Scrollbar(
                        thickness: 8,
                        thumbVisibility: true,
                        child: ListView.builder(
                          itemCount: categoryMap[categoryName]?.length ?? 0,
                          itemBuilder: (context, index) {
                            String category = categoryMap[categoryName]![index];
                            bool isWrongAnswer = category.contains("間違えた問題");
                            bool isAll = category.contains("まとめ");


                            if (!isWrongAnswer) {
                              itemCount = seriesCount[category] ?? 0;
                              correctCount = seriesCorrectCount[category] ?? 0;
                            }
                            if(!(wrongAnswersCount == 0 && isWrongAnswer)) {
                              return Container(
                              height: 75.0,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: isAll
                                        ? Color(0xFF11999E) // 青
                                        : isWrongAnswer
                                        ? Color(0xFFFF6969) // 赤
                                        : Color(0xFFFFFFFF), // 白
                                    width: 2.0, // 下線の幅を設定
                                  ),
                                ),

                              ),
                              child: Center(
                                child: ListTile(
                                  contentPadding:
                                      const EdgeInsets.symmetric(horizontal: 16.0),
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            QuestionPage(category), // 次のページに遷移
                                      ),
                                    );
                                    _initDbAndFetchData();
                                  },
                                  title: Text(category),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!isWrongAnswer)
                                        Text('($correctCount/$itemCount) 問'), // 各ジャンルの数を表示

                                      if (isWrongAnswer)
                                        Text('($wrongAnswersCount) 問'), // 間違えた問題の数を表示

                                      const SizedBox(width: 8), // アイコンとの間隔
                                      const Icon(
                                          Icons.keyboard_arrow_right), // 右矢印アイコン
                                    ],
                                  ),
                                ),
                              ),
                            );
                            } else {
                              return Container();
                            }
                          },
                        ),
                      ),
                    )
                  else
                    const Center(child: CircularProgressIndicator()),
                  // データがないときは読み込み中を表示
                ],
              ),
            ),
    );
  }
}
