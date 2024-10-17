import 'package:fe_project/pages/settings_page.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestoreをインポート
import 'package:fe_project/pages/category_page.dart';

import 'question_page.dart';

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
  int wrongAnswers = 0;
  bool isLoading = true; // ローディング状態の管理
  bool _isFirstLaunch = true; // 初回起動のフラグ
  List<Map<String, dynamic>> maps = [];
  double progress = 0; // 進捗率
  final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;

  @override
  void initState() {
    super.initState();
    _initDbAndFetchData(); // DBの初期化とデータ取得を実行
  }

  Future<void> _initDbAndFetchData() async {
    _database = await initializeDb(); // ローカルデータベースの初期化
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: Duration.zero,
    ));

    await remoteConfig.setDefaults(<String, dynamic>{
      "db_version": 0,
    });

    await remoteConfig.fetchAndActivate();
    int remoteDbVersion = remoteConfig.getInt("db_version");
    print("remote DBバージョン: $remoteDbVersion");

    // ローカルdbからバージョンを取得
    final appConfig = await _database!.query('appConfig');
    Object? localDbVersion = appConfig[0]['db_version'];
    print("ローカルDBバージョン: $localDbVersion");

    // remote configのバージョンと違ったらfirebaseから取得
    if (_isFirstLaunch && remoteDbVersion != localDbVersion) {
      await loadQuizData(remoteDbVersion); // ローカルDBにデータを読み込み
      _isFirstLaunch = false; // フラグを更新
    }

    // DBからクイズデータを取得
    maps = await _database!.query('quizData');
    setState(() {
      quizDataList = maps; // 取得したデータを設定
      totalQuestions = quizDataList.length; // クイズの総数を設定
      isLoading = false; // データが読み込まれたらローディング状態を更新
    });
    setProgress();
  }

  Future<Database> initializeDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'quiz_data.db'); // DBのパスを指定

    //db削除
    // if (_isFirstLaunch) {
    // await deleteDatabase(path);
    // }

    return openDatabase(
      path,
      onCreate: (db, version) async {
        // quizDataテーブルの作成
        await db.execute(
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
        // appConfigテーブルの作成
        await db.execute(
          'CREATE TABLE appConfig('
          'id INTEGER PRIMARY KEY, '
          'db_version INTEGER'
          ')',
        );
        await db.insert('appConfig', {'id': 1, 'db_version': 0});
      },
      version: 1,
    );
  }

  Future<void> loadQuizData(int remoteDbVersion) async {
    print("データをロードします");
    // ローカルDBのバージョンを設定
    await _database!.update('appConfig', {'db_version': remoteDbVersion});

    // Firestoreからデータを取得
    final snapshot = await FirebaseFirestore.instance
        .collection('contents')
        .doc('data')
        .collection('quizzes')
        .doc('data1')
        .get();

    // Firestoreから取得したデータのリストを保持
    List<Map<String, dynamic>> firestoreDataList =
        List.from(snapshot.data()!['quizDataList']);

    // データをSQLiteに保存
    for (var doc in firestoreDataList) {
      // すでにデータが存在するかを確認
      final existingData = await _database!
          .query('quizData', where: 'id = ?', whereArgs: [doc['quiz_id']]);

      if (existingData.isEmpty) {
        // 存在しない場合は新規挿入
        await _database!.insert('quizData', {
          'id': doc['quiz_id'], // Firestoreのデータを使用
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
          'judge': 0, // 初期値
        });
      }
    }

    // DBからクイズデータを取得
    maps = await _database!.query('quizData');
    setState(() {
      quizDataList = maps; // 取得したデータを設定
      totalQuestions = quizDataList.length; // クイズの総数を設定
    });
  }

  Future<void> setProgress() async {
    // _database = await initializeDb(); // ローカルデータベースの初期化
    // 進捗を計算（judgeが2の問題数）
    setState(() {
      correctAnswers = quizDataList.where((quiz) => quiz['judge'] == 2).length;
      wrongAnswers = quizDataList.where((quiz) => quiz['judge'] == 1).length;
      progress =
          totalQuestions > 0 ? correctAnswers / totalQuestions : 0; // 進捗を計算
    });
    print(correctAnswers);
    print(wrongAnswers);
    print(progress);
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
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // 設定ページへの遷移
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(), // 設定ページに遷移
                ),
              );
            },
          ),
        ],
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
                      padding:
                          EdgeInsets.symmetric(vertical: screenHeight * 0.05),
                      child: Column(
                        children: [
                          Text(
                            '正解数 $correctAnswers / $totalQuestions 問中',
                            style: TextStyle(
                              fontSize:
                                  screenHeight * 0.03, // フォントサイズを画面高さに基づいて指定
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
                                    border: Border.all(
                                        color: Colors.black, width: 0),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                // アニメーション付きのバー
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  // アニメーションの時間
                                  width: screenWidth * 0.8 * progress,
                                  // 進捗率に基づいてバーの幅を調整
                                  height: screenHeight * 0.03,
                                  decoration: BoxDecoration(
                                    border: Border.all(width: 0),
                                    borderRadius: BorderRadius.circular(5),
                                    color: const Color(0xFF30E3CA),
                                  ),
                                ),
                                // パーセンテージをバーの中に表示
                                Center(
                                  child: Text(
                                    '${(progress * 100).toInt()}%', // パーセンテージを表示
                                    style: TextStyle(
                                      color: Colors.black, // テキストカラー
                                    ),
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
                    // カテゴリのリスト
                    Expanded(
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
                            if (wrongAnswers > 0)
                              _buildCategoryTile(
                                  screenWidth, screenHeight, "間違えた問題から出題 ($wrongAnswers問)", 3, context, "wrongStage"),
                          ],
                        ),
                      ),
                    ),

                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCategoryTile(double screenWidth, double screenHeight,
      String category, int index, BuildContext context, String categoryName) {
    return GestureDetector(
      onTapDown: (_) {
        // タップしたらスワイプのアニメーションを開始
        setState(() {
          _isTappedList[index] = true;
        });
      },
      onTapUp: (_) async {
        // タップが離れたらスワイプを解除
        setState(() {
          _isTappedList[index] = false;
        });

        // "全範囲から出題"が押された場合のみQuestionPageに遷移
        if (categoryName == "allStage" || categoryName == "wrongStage") {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  QuestionPage(categoryName), // QuestionPageに遷移
            ),
          );
        } else {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoryPage(categoryName), // カテゴリページに遷移
            ),
          );
        }
        _initDbAndFetchData();
      },
      onTapCancel: () {
        // タップがキャンセルされたらスワイプを解除
        setState(() {
          _isTappedList[index] = false;
        });
      },
      child: Container(
        margin: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.1, vertical: screenHeight * 0.02),
        // マージンを設定
        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.03),
        // パディングを設定
        decoration: BoxDecoration(
          border: Border.all(
            color: Color(0xFF11999E), // 枠線の色を設定
            width: 2,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            category,
            style: TextStyle(
              fontSize: screenHeight * 0.025, // フォントサイズを画面高さに基づいて指定
            ),
          ),
        ),
      ),
    );
  }
}
