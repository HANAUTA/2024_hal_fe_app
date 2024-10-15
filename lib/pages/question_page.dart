import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'result_page.dart';

class QuestionPage extends StatefulWidget {
  final String category;
  const QuestionPage(this.category, {super.key});

  @override
  _QuestionPageState createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  int _currentTabIndex = 0; // 現在のタブのインデックスを保持
  Database? _database; // データベースのインスタンス
  List<Map<String, dynamic>> quizDataList = [];
  int _randomIndex = 0; // ランダムな問題のインデックスを保持
  bool _isLoading = true;
  Map quizChoices = {};
  bool _isCorrect = false;
  String correctAnswer = "";
  int totalQuestionCount = 0;
  int correctAnswerCount = 0;
  double correctPercentage = 0.0;
  bool _isAnswered = true;
  int nextQuestionIndex = 0;
  List<int> randomList = [];
  int quizLength = 0;
  bool isNextExist = false;
  String categoryNum = "";
  PageController _pageController = PageController();
  ScrollController _scrollController = ScrollController(); // ScrollControllerを追加
  Map<String, String> categoryNumMap = {
    "テクノロジー系まとめ": "1",
    "基礎理論": "1001",
    "アルゴリズムとプログラミング": "1002",
    "コンピュータ構成要素": "1003",
    "システム構成要素": "1004",
    "ソフトウェア": "1005",
    "ハードウェア": "1006",
    "ヒューマンインターフェイス": "1007",
    "マルチメディア": "1008",
    "データベース": "1009",
    "ネットワーク": "1010",
    "セキュリティ": "1011",
    "システム開発技術": "1012",
    "ソフトウェア開発管理技術": "1013",

    "ストラテジ系まとめ": "3",
    "システム戦略": "3001",
    "システム企画": "3002",
    "経営戦略マネジメント": "3003",
    "技術戦略マネジメント": "3004",
    "ビジネスインダストリ": "3005",
    "企業活動": "3006",
    "法務": "3007",

    "マネジメント系まとめ": "2",
    "プロジェクトマネジメント": "2001",
    "サービスマネジメント": "2002",
    "システム監査": "2003",
  };



  @override
  void initState() {
    super.initState();
    if (widget.category == "allStage") {
      categoryNum = "_";
    }else {
      categoryNum = categoryNumMap[widget.category]!;
    }
    _initDbAndFetchData(); // DBの初期化とデータ取得を実行

  }

  @override
  void dispose() {
    _scrollController.dispose(); // ScrollControllerを破棄
    super.dispose();
  }


  Future<void> _initDbAndFetchData() async {
    setState(() {
      _isLoading = true; // データが読み込まれたらローディング状態を更新
    });
    _database = await initializeDb(); // ローカルデータベースの初期化
    await loadQuizData(); // ローカルDBからデータを読み込み
    await setRandomIndex(); // クイズデータを設定
    nextQuestion();
    setState(() {
      _isLoading = false; // データが読み込まれたらローディング状態を更新
    });
  }

  Future<Database> initializeDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'quiz_data.db'); // DBのパスを指定

    return openDatabase(
      path,
      version: 1,
    );
  }

  Future<void> loadQuizData() async {
    // DBからクイズデータを取得
    final List<Map<String, dynamic>> maps = await _database!.query('quizData', where: 'series_document_id LIKE ?', whereArgs: ['$categoryNum%']);
    setState(() {
      quizDataList = maps; // 取得したデータを設定
      if (quizDataList.isNotEmpty) {
        print('Loaded ${quizDataList.length} quizzes.');
      } else {
        print('No quiz data found.');
      }
    });
  }

  Future<void> setRandomIndex() async {
    quizLength = quizDataList.length;
    if (quizLength > 0) {
      // 0からquizLengthの範囲のlistを作成
        randomList = List.generate(quizLength, (index) => index);
        randomList.shuffle();
    }
  }

  Future<void>nextQuestion() async {
    if (nextQuestionIndex < quizLength) {
      setState(() {
      _currentTabIndex = 0; // 問題タブに切り替え
      _randomIndex = randomList[nextQuestionIndex];
      nextQuestionIndex++;
      isNextExist = true;
    });
    } else {
      // CATEGORYページに戻る
      setState(() {
        isNextExist = false;
      });

    }
    if (_isAnswered) {
      setState(() {
        _isAnswered = false;
      });
    } else {
      setState(() {
        totalQuestionCount++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width; // 画面の幅を取得
    final buttonSize = screenWidth * 0.15; // ボタンのサイズを画面幅の15%に設定
    final quizData = quizDataList.isNotEmpty ? quizDataList[_randomIndex] : {}; // ランダムに選ばれたクイズデータ

    if (quizData.length != 0){
      quizChoices = {
        quizData['mistake1'].substring(0, 1): quizData['mistake1'].substring(2),
        quizData['mistake2'].substring(0, 1): quizData['mistake2'].substring(2),
        quizData['mistake3'].substring(0, 1): quizData['mistake3'].substring(2),
        quizData['answer'].substring(0, 1): quizData['answer'].substring(2),
      };
      correctAnswer = quizData['answer'][0];
    }

    // 問題文の長さをチェックするための変数
    final isQuestionLong = (quizData['question']?.length ?? 0) > 100; // 適当な長さで判定
    // 問題文の最大高さを指定
    final questionHeight = isQuestionLong ? 200.0 : null;

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
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // 2回ポップしてホームに戻る
            },
          ),
        ],
        title: Text(widget.category),
      ),

      body: Container(
        color: const Color(0xFFE4F9F5),
          child: _isLoading
              ? Center(
            child: CircularProgressIndicator(), // ローディングインジケーターを表示
          )
        : Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Score and percentage row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Text("正解数3 / 4問中"),
                  Text("正解数$correctAnswerCount / $totalQuestionCount問中"),
                  Text("正答率$correctPercentage%"),
                ],
              ),
              const SizedBox(height: 10),
              // Header with two tabs (問題 and 解説)

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentTabIndex = 0; // "問題"タブがタップされたとき
                        });
                        _pageController.jumpToPage(0); // PageViewを0ページ目に変更
                      },
                      child: Container(
                        color: _currentTabIndex == 0 ? Colors.pink[200] : Colors.grey[300],
                        padding: const EdgeInsets.all(8),
                        child: const Center(child: Text("問題")),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentTabIndex = 1;// "解説"タブがタップされたとき
                          _scrollController.animateTo( // スクロール位置をトップに戻す
                              0.0,
                              duration: Duration(milliseconds: 300),
                          curve: Curves.easeOut,);
                        });
                        _pageController.jumpToPage(1); // PageViewを1ページ目に変更
                      },
                      child: Container(
                        color: _currentTabIndex == 1 ? Colors.pink[200] : Colors.grey[300],
                        padding: const EdgeInsets.all(8),
                        child: const Center(child: Text("解説")),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Question or Explanation content based on the selected tab

              if (_currentTabIndex == 0 && quizData.isNotEmpty) ...[

                Container(
                  constraints: BoxConstraints(
                    maxHeight: 180, // 最大高さを指定
                  ),
                  child: isQuestionLong
                      ? SingleChildScrollView(
                    controller: _scrollController, // スクロールコントローラーを追加
                    child: Text(
                      quizData['question'] ?? "問題が見つかりませんでした。",
                      style: const TextStyle(fontSize: 16),
                    ),
                  )
                      : Text(
                    quizData['question'] ?? "問題が見つかりませんでした。",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 20),
                // Scrollable area for question options
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController, // スクロールコントローラーを追加
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildOptionWithBorder("ア", quizChoices['ア'] ?? "選択肢が見つかりませんでした。"),
                        const SizedBox(height: 10),
                        buildOptionWithBorder("イ", quizChoices['イ'] ?? "選択肢が見つかりませんでした。"),
                        const SizedBox(height: 10),
                        buildOptionWithBorder("ウ", quizChoices['ウ'] ?? "選択肢が見つかりませんでした。"),
                        const SizedBox(height: 10),
                        buildOptionWithBorder("エ", quizChoices['エ'] ?? "答えが見つかりませんでした。"),
                      ],
                    ),
                  ),
                ),
              ] else if (_currentTabIndex == 1 && quizData.isNotEmpty) ...[
                // 解説タブが選択されたときの内容（スクロール可能に）
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController, // スクロールコントローラーを追加
                    child: Column(
                      children: [
                        Center( // 中央に寄せる
                          child: _isCorrect
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center, // 横方向に中央揃え
                                  children: [
                                    Icon(Icons.radio_button_unchecked, color: Colors.green, size: 100), // 不正解の場合は赤いクローズアイコンを表示
                                    const SizedBox(width: 8),
                                    Column(
                                      children: [
                                        const Text("", style: TextStyle(fontSize: 5),), // 空のテキストを追加
                                        const Text("正解: ", style: TextStyle(fontSize: 30), textAlign: TextAlign.center),
                                      ],
                                      ),
                                    Text(correctAnswer, style: TextStyle(fontSize: 40)),
                                  ],
                                )
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.center, // 横方向に中央揃え
                            children: [
                              Icon(Icons.close, color: Colors.red, size: 100), // 不正解の場合は赤いクローズアイコンを表示
                              const SizedBox(width: 8),
                              Column(
                                children: [
                                  const Text("", style: TextStyle(fontSize: 5),), // 空のテキストを追加
                                  const Text("正解: ", style: TextStyle(fontSize: 30), textAlign: TextAlign.center),
                                ],
                              ),
                              Text(correctAnswer, style: TextStyle(fontSize: 40)),
                            ],
                          ),
                        ),

                        Container(
                          margin: const EdgeInsets.all(8.0), // 周りにマージンを追加
                          padding: const EdgeInsets.all(16.0), // 内側にパディングを追加
                          decoration: BoxDecoration(
                            color: Colors.grey[200], // 背景色を淡いグレーに変更
                            borderRadius: BorderRadius.circular(10), // 角を丸くする
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                quizData['comment'] ?? "解説が見つかりませんでした。",
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 15.0), // commentとlinkの間にスペースを追加
                              if (quizData['link'] != null && quizData['link'].isNotEmpty)
                                Align(
                                  alignment: Alignment.centerRight, // 右寄せにする
                                  child:
                                    Text(
                                    "${quizData['link']}", // リンクを表示
                                    style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black, // リンクテキストの色
                                  ),
                                ),
                                ),
                            ],
                          ),
                        ),

                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      // Fixed BottomAppBar
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFFE4F9F5),
        child: SizedBox(
          height: 56, // ボトムバーの高さを指定
          child: _currentTabIndex == 1 // 解説タブの場合
              ? GestureDetector(
            onTap: () async {
              await nextQuestion();
              if (isNextExist) {
                setState(() {
                  _currentTabIndex = 0; // 問題タブに切り替え
                });
              } else {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                    builder: (context) => const ResultPage(),
              ),
              );
              }
            },
            child: Container(
              color: const Color(0xFFE4F9F5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Expanded(
                    child: Center(
                      child: Text('次の問題へ', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_right, size: 30),
                    onPressed: () async {

                      await nextQuestion();
                      if (isNextExist) {
                        setState(() {
                          _currentTabIndex = 0; // 問題タブに切り替え
                        });
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
            ),
          )
              : Row(
            children: [
              const Spacer(flex: 1), // デバイスサイズに応じた余白を追加
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    _checkAnswer("ア");
                  },
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                  ),
                  child: const Text("ア", style: TextStyle(fontSize: 16)),
                ),
              ),
              const Spacer(flex: 1),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    _checkAnswer("イ");
                  },
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                  ),
                  child: const Text("イ", style: TextStyle(fontSize: 16)),
                ),
              ),
              const Spacer(flex: 1),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    _checkAnswer("ウ");
                  },
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                  ),
                  child: const Text("ウ", style: TextStyle(fontSize: 16)),
                ),
              ),
              const Spacer(flex: 1),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    _checkAnswer("エ");
                  },
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                  ),
                  child: const Text("エ", style: TextStyle(fontSize: 16)),
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildOptionWithBorder(String label, String text) {
    return Container(
      decoration: BoxDecoration(
        //下線部にのみborder
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 1),
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  void _checkAnswer(String selectedChoice) async {
    int judgeValue = 0; // 判定値を保持

    if (selectedChoice == correctAnswer) {
      // 正解の処理
      judgeValue = 2;
      _isCorrect = true;
      correctAnswerCount++;
    } else {
      // 不正解の処理
      judgeValue = 1;
      _isCorrect = false;
    }
    //スクロール状態をリセット
    _scrollController.animateTo(
      0.0,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    setState(() {
      _currentTabIndex = 1; // 解説タブに切り替え
      totalQuestionCount++;
      _isAnswered = true;
    });

    // 正答率を計算
    correctPercentage = (correctAnswerCount / totalQuestionCount) * 100;
    // 小数点第一位まで
    correctPercentage = (correctPercentage * 10).round() / 10;
    // データベースのjudgeフィールドを更新
    await _database!.update(
      'quizData',
      {'judge': judgeValue}, // judgeフィールドを更新
      where: 'id = ?', // 条件
      whereArgs: [quizDataList[_randomIndex]['id']], // 条件に渡す引数
    );
  }
}
