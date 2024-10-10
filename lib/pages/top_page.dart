import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestoreをインポート
import 'package:fe_project/pages/category_page.dart';

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
  int totalQuestions = 1;
  int correctAnswers = 20;
  bool isLoading = true; // ローディング状態の管理

  @override
  void initState() {
    super.initState();
    _initDbAndFetchData(); // DBの初期化とデータ取得を実行
  }

  Future<void> _initDbAndFetchData() async {
    _database = await initializeDb(); // ローカルデータベースの初期化
    await loadQuizData(); // ローカルDBからデータを読み込み
    setState(() {
      isLoading = false; // データが読み込まれたらローディング状態を更新
    });
  }

  Future<Database> initializeDb() async {
    final dbPath = await getDatabasesPath();
    print(dbPath);
    final path = join(dbPath, 'quiz_data.db'); // DBのパスを指定
    // 既存のデータベースがあれば削除
    final fileExists = await databaseExists(path);
    if (fileExists) {
      print('Deleting existing database...');
      await deleteDatabase(path); // データベースを削除
    }

    return openDatabase(
      path,
      onCreate: (db, version) {
        print('Creating table...');
        // テーブルの作成
        return db.execute(
          'CREATE TABLE quizData('
              'id INTEGER PRIMARY KEY, '
              'answer TEXT, '
              'comment TEXT, '
              'image TEXT, '
              'link TEXT, '
              'mistake1 TEXT, '
              'mistake2 TEXT, '
              'mistake3 TEXT, '
              'question TEXT, '
              'quiz_id INTEGER, '
              'series_document_id TEXT, '
              'series_name TEXT, '
              'stage_document_id TEXT, '
              'stage_name TEXT, '
              'judge INTEGER'
              ')',
        );
      },
      version: 1,
    );
  }

  Future<void> loadQuizData() async {
    // Firestoreからデータを取得
    final snapshot = await FirebaseFirestore.instance.collection('contents').doc('data').collection('quizzes').doc('data1').get();

    // データをSQLiteに保存
    for (var doc in snapshot.data()!['quizDataList']) {
      await _database!.insert('quizData', {
        'id': doc['id'], // Firestoreのデータを使用
        'answer': doc['answer'],
        'comment': doc['comment'],
        'image': doc['image_url'],
        'link': doc['link'],
        'mistake1': doc['mistake_list'][0],
        'mistake2': doc['mistake_list'][1],
        'mistake3': doc['mistake_list'][2],
        'question': doc['question'],
        'quiz_id': doc['quiz_id'],
        'series_document_id': doc['series_document_id'],
        'series_name': doc['series_name'],
        'stage_document_id': doc['stage_document_id'],
        'stage_name': doc['stage_name'],
        'judge': 0,
      });
    }

    // DBからクイズデータを取得
    final List<Map<String, dynamic>> maps = await _database!.query('quizData');
    setState(() {
      quizDataList = maps; // 取得したデータを設定
      totalQuestions = quizDataList.length; // クイズの総数を設定
    });
  }

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
                    _buildCategoryTile(screenWidth, screenHeight, "テクノロジー", 0, context, "technologyStage"),
                    _buildCategoryTile(screenWidth, screenHeight, "マネジメント", 1, context, "managementStage"),
                    _buildCategoryTile(screenWidth, screenHeight, "ストラテジ", 2, context, "strategyStage"),
                    _buildCategoryTile(screenWidth, screenHeight, "全範囲から出題", 3, context, "allStage"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTile(double screenWidth, double screenHeight, String category, int index, BuildContext context, String categoryName) {
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
            builder: (context) => CategoryPage(categoryName), // カテゴリページに遷移
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
