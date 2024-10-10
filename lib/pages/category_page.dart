import 'package:fe_project/pages/question_page.dart';
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


  // `categoryName`をクラスのメンバーとして定義
  String? categoryName;
  List<dynamic> erroList = [];
  Map<String, List<dynamic>> seriesMap = {
    "テクノロジー系まとめ": [],
    "基礎理論": [],
    "アルゴリズムとプログラミング": [],
    "コンピュータ構成要素": [],
    "システム構成要素": [],
    "ソフトウェア": [],
    "ハードウェア": [],
    "ヒューマンインターフェイス": [],
    "マルチメディア": [],
    "データベース": [],
    "ネットワーク": [],
    "セキュリティ": [],
    "システム開発技術": [],
    "ソフトウェア開発管理技術": [],

    "ストラテジ系まとめ": [],
    "システム戦略": [],
    "システム企画": [],
    "経営戦略マネジメント": [],
    "技術戦略マネジメント": [],
    "ビジネスインダストリ": [],
    "企業活動": [],
    "法務": [],

    "マネジメント系まとめ": [],
    "プロジェクトマネジメント": [],
    "サービスマネジメント": [],
    "システム監査": [],
  }; // series_nameごとのリストを保存するマップ

  // カテゴリー名のマップを定義
  final Map<String, List<String>> categoryMap = {
    "テクノロジー系": [
      "テクノロジー系まとめ",
      "基礎理論",
      "アルゴリズムとプログラミング",
      "コンピュータ構成要素",
      "システム構成要素",
      "ソフトウェア",
      "ハードウェア",
      "ヒューマンインターフェイス",
      "マルチメディア",
      "データベース",
      "ネットワーク",
      "セキュリティ",
      "システム開発技術",
      "ソフトウェア開発管理技術"
    ],
    "ストラテジ系": [
      "ストラテジ系まとめ",
      "システム戦略",
      "システム企画",
      "経営戦略マネジメント",
      "技術戦略マネジメント",
      "ビジネスインダストリ",
      "企業活動",
      "法務"
    ],
    "マネジメント系": [
      "マネジメント系まとめ",
      "プロジェクトマネジメント",
      "サービスマネジメント",
      "システム監査",
    ],
  };

  bool _isLoading = false; // ローディングフラグ

  // ローカルデータベースを初期化し、クイズデータを取得
  Future<void> _initDbAndFetchData() async {
    setState(() {
      _isLoading = true; // データ取得開始時にローディングを開始
    });
    _database = await initializeDb(); // ローカルデータベースの初期化
    await loadQuizData(); // ローカルDBからデータを読み込み
    setState(() {
      _isLoading = false; // データ取得終了時にローディングを終了
    });
  }

  // ローカルDBの初期化
  Future<Database> initializeDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'quiz_data.db'); // DBのパスを指定

    // データベースを開き、テーブルを作成（存在しない場合）
    return openDatabase(
      path,
      version: 1,
    );
  }

  // ローカルDBからクイズデータを取得
  Future<void> loadQuizData() async {
    // カテゴリーに応じてクエリを変更
    final List<Map<String, dynamic>> maps;
    if (widget.categoryId == 'technologyStage') {
      // series_document_idの1文字目が'1'のものを取得
      maps = await _database!.query(
        'quizData',
        where: 'series_document_id LIKE ?',
        whereArgs: ['1%'], // '1'で始まるレコードを取得
      );
    } else if(widget.categoryId == 'managementStage') {
      // series_document_idの1文字目が'2'のものを取得
      maps = await _database!.query(
        'quizData',
        where: 'series_document_id LIKE ?',
        whereArgs: ['2%'], // '2'で始まるレコードを取得
      );
    } else if(widget.categoryId == 'strategyStage') {
      // series_document_idの1文字目が'3'のものを取得
      maps = await _database!.query(
        'quizData',
        where: 'series_document_id LIKE ?',
        whereArgs: ['3%'], // '3'で始まるレコードを取得
      );
    } else {
      maps = await _database!.query('quizData');
    }

    setState(() {
      quizDataList = maps; // 取得したデータを設定
      if (quizDataList.isNotEmpty) {
        print('Loaded ${quizDataList.length} quizzes.');
      } else {
        print('No quiz data found.');
      }

      // クイズデータをシリーズごとに分類
      classifyQuizDataBySeries();
    });
  }


  // クイズデータを `series_name` ごとに分類
  void classifyQuizDataBySeries() {
    Map<String, List<dynamic>> tempSeriesMap = {...seriesMap}; // 初期値をコピーして保持
    List<dynamic> tempErroList = [];
    for (var quizData in quizDataList) {
      String seriesName = quizData['series_name'];

      // series_nameが既に存在するかを確認し、リストに追加
      if (tempSeriesMap.containsKey(seriesName)) {
        tempSeriesMap[seriesName]!.add(quizData);
        if (quizData["series_document_id"][0] == "1") {
          tempSeriesMap["テクノロジー系まとめ"]!.add(quizData);
        } else if (quizData["series_document_id"][0] == "3") {
          tempSeriesMap["ストラテジ系まとめ"]!.add(quizData);
        } else if (quizData["series_document_id"][0] == "2") {
          tempSeriesMap["マネジメント系まとめ"]!.add(quizData);
        }
      } else {
        tempErroList.add(quizData);
      }

      setState(() {
        seriesMap = tempSeriesMap; // series_nameごとのリストをセット
        erroList = tempErroList;
      });
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

    final int correctAnswers = 5; // 正解数
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator()); // ローディング中はインジケーターを表示
    }

    // カテゴリーごとに総問題数を計算
    int totalQuestions = 0;
    if (categoryName == "テクノロジー系") {
      totalQuestions = seriesMap["テクノロジー系まとめ"]!.length; // 総問題数
      print(seriesMap["テクノロジー系まとめ"]!.length);
    } else if (categoryName == "ストラテジ系") {
      totalQuestions = seriesMap["ストラテジ系まとめ"]!.length; // 総問題数
    } else if (categoryName == "マネジメント系") {
      totalQuestions = seriesMap["マネジメント系まとめ"]!.length; // 総問題数
    }
    print(erroList.length);
    print(erroList);

    double progress = totalQuestions > 0 ? correctAnswers / totalQuestions : 0; // 進捗を計算
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
      body: Container(
        color: const Color(0xFFE4F9F5), // SafeAreaの背景色を設定
        child: Column(
          children: [
            // 正解数と進捗バーを表示
            Padding(
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.05),
              child: Column(
                children: [
                  Text(
                    '正解数 $correctAnswers / $totalQuestions 問中',
                    style: TextStyle(
                      fontSize: screenHeight * 0.03,
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
            // カテゴリーリスト
            if (categoryName != null) // categoryNameがnullでないときに表示
              Expanded(
                child: ListView.builder(
                  itemCount: categoryMap[categoryName]?.length ?? 0,
                  itemBuilder: (context, index) {
                    String category = categoryMap[categoryName]![index];
                    int itemCount = seriesMap[category]?.length ?? 0;

                    return Container(
                      height: 75.0,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFFFFFFFF), // 下線の色を設定
                            width: 1.0, // 下線の幅を設定
                          ),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const QuestionPage(), // 次のページに遷移
                            ),
                          );
                        },
                        title: Text(category),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$itemCount 問'), // 各ジャンルの数を表示
                            const SizedBox(width: 8), // アイコンとの間隔
                            const Icon(Icons.keyboard_arrow_right), // 右矢印アイコン
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              const Center(child: CircularProgressIndicator()), // データがないときは読み込み中を表示
          ],
        ),
      ),
    );
  }

}