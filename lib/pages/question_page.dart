import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'result_page.dart';

class QuestionPage extends StatefulWidget {
  final String category;
  QuestionPage(this.category, {super.key});

  @override
  _QuestionPageState createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;
  int _currentTabIndex = 0;
  Database? _database;
  List<Map<String, dynamic>> quizDataList = [];
  int _randomIndex = 0;
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
  String titleText = "";
  ScrollController _scrollController = ScrollController();

  // AudioPlayerのインスタンスを作成
  final audioPlayer = AudioPlayer();

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


  bool isQuestionLong = false;

  @override
  void initState() {
    super.initState();
    if (widget.category == "allStage") {
      categoryNum = "_";
    } else if(widget.category == "wrongStage") {
      categoryNum = "";
    } else {
      categoryNum = categoryNumMap[widget.category]!;
    }
    _initDbAndFetchData(); // DBの初期化とデータ取得を実行
    setTabController();
    _pageController = PageController();
    // Tabが切り替わったときにPageViewも更新する
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _pageController.jumpToPage(_tabController.index);
      }
    });
    if (widget.category == "allStage") {
      titleText = "全範囲";
    } else if (widget.category == "wrongStage") {
      titleText = "間違えた問題";
    } else {
      titleText = widget.category;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose(); // ScrollControllerを破棄
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> setTabController() async {
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      int nowIndex = _tabController.index;
      setState(() {
        _currentTabIndex = nowIndex;
      });
    });
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
    final List<Map<String, dynamic>> maps;
    // DBからクイズデータを取得
    if (widget.category == "wrongStage") {
      // judgeが1のデータを取得
      maps = await _database!.query('quizData', where: 'judge = 1');
    } else {
      maps = await _database!.query('quizData',
        where: 'series_document_id LIKE ?', whereArgs: ['$categoryNum%']);
    }
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

  void nextQuestion() {
    print(nextQuestionIndex);
    if (nextQuestionIndex + 1 < quizLength) {
      print("next OK");
      isNextExist = true;
    } else {
      // CATEGORYページに戻る
      print('next NG');
      isNextExist = false;
    }
    _randomIndex = randomList[nextQuestionIndex];
    _isCorrect = false;
    nextQuestionIndex++;
    if (_isAnswered) {
      _isAnswered = false;
    } else {
      totalQuestionCount++;
    }
    isQuestionLong =
        (quizDataList[_randomIndex]['question']?.length ?? 0) > 100; // 適当な長さで判定
    _tabController.animateTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width; // 画面の幅を取得
    final buttonSize = screenWidth * 0.15; // ボタンのサイズを画面幅の15%に設定
    final quizData = quizDataList.isNotEmpty
        ? quizDataList[_randomIndex]
        : {}; // ランダムに選ばれたクイズデータ

    if (quizData.length != 0) {
      quizChoices = {
        quizData['mistake1'].substring(0, 1): quizData['mistake1'].substring(2),
        quizData['mistake2'].substring(0, 1): quizData['mistake2'].substring(2),
        quizData['mistake3'].substring(0, 1): quizData['mistake3'].substring(2),
        quizData['answer'].substring(0, 1): quizData['answer'].substring(2),
      };
      correctAnswer = quizData['answer'][0];
    }

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
              // ホームに戻る
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
        title: Text(titleText),
      ),

      body: Container(
          color: const Color(0xFFE4F9F5),
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : DefaultTabController(
                  length: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                "正解数$correctAnswerCount / $totalQuestionCount問中"),
                            Text("正答率$correctPercentage%"),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TabBar(
                          controller: _tabController,
                          tabs: [
                            Tab(child: const Center(child: Text("問題"))),
                            Tab(child: const Center(child: Text("解説"))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          // ここを追加
                          child: PageView(
                            controller: _pageController,
                            onPageChanged: (index) {
                              setState(() {
                                _tabController.index = index;
                              });
                            },
                            children: [
                              _buildQuestionTab(quizData, isQuestionLong),
                              _buildExplanationTab(quizData, isQuestionLong),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
      // Fixed BottomAppBar
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildBottomNavigationBar(context) {
    switch (_currentTabIndex) {
      case 1:
        return BottomAppBar(
          color: const Color(0xFFE4F9F5),
          child: SizedBox(
            height: 56,
            child: GestureDetector(
              onTap: () {
                if (isNextExist) {
                  nextQuestion();
                } else {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ResultPage(
                        correctAnswerCount: correctAnswerCount,
                        totalQuestionCount: totalQuestionCount,
                        correctPercentage: '$correctPercentage%',
                      ),
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
                      onPressed: () {
                        if (isNextExist) {
                          nextQuestion();
                        } else {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ResultPage(
                                correctAnswerCount: correctAnswerCount,
                                totalQuestionCount: totalQuestionCount,
                                correctPercentage: '$correctPercentage%',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

      default:
        return BottomAppBar(
          color: const Color(0xFFE4F9F5),
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                const Spacer(flex: 1), // デバイスサイズに応じた余白を追加
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      _checkAnswer("ア");
                      _tabController.animateTo(1);
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
                      _tabController.animateTo(1);
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
                      _tabController.animateTo(1);
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
                      _tabController.animateTo(1);
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
        );
    }
  }

  Widget _buildQuestionTab(quizData, isQuestionLong) {
    print('questionタブ生成');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ページごとに違う内容
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
                buildOptionWithBorder(
                    "ア", quizChoices['ア'] ?? "選択肢が見つかりませんでした。"),
                const SizedBox(height: 10),
                buildOptionWithBorder(
                    "イ", quizChoices['イ'] ?? "選択肢が見つかりませんでした。"),
                const SizedBox(height: 10),
                buildOptionWithBorder(
                    "ウ", quizChoices['ウ'] ?? "選択肢が見つかりませんでした。"),
                const SizedBox(height: 10),
                buildOptionWithBorder(
                    "エ", quizChoices['エ'] ?? "答えが見つかりませんでした。"),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExplanationTab(quizData, isQuestionLong) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ページごとに違う内容
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController, // スクロールコントローラーを追加
            child: Column(
              children: [
                Center(
                  // 中央に寄せる
                  child: _isCorrect
                      ? Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center, // 横方向に中央揃え
                          children: [
                            Icon(Icons.radio_button_unchecked,
                                color: Colors.green,
                                size: 100), // 不正解の場合は赤いクローズアイコンを表示
                            const SizedBox(width: 8),
                            Column(
                              children: [
                                const Text(
                                  "",
                                  style: TextStyle(fontSize: 5),
                                ),
                                // 空のテキストを追加
                                const Text("正解: ",
                                    style: TextStyle(fontSize: 30),
                                    textAlign: TextAlign.center),
                              ],
                            ),
                            Text(correctAnswer, style: TextStyle(fontSize: 40)),
                          ],
                        )
                      : Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center, // 横方向に中央揃え
                          children: [
                            Icon(Icons.close, color: Colors.red, size: 100),
                            // 不正解の場合は赤いクローズアイコンを表示
                            const SizedBox(width: 8),
                            Column(
                              children: [
                                const Text(
                                  "",
                                  style: TextStyle(fontSize: 5),
                                ),
                                // 空のテキストを追加
                                const Text("正解: ",
                                    style: TextStyle(fontSize: 30),
                                    textAlign: TextAlign.center),
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
                      if (quizData['link'] != null &&
                          quizData['link'].isNotEmpty)
                        Align(
                          alignment: Alignment.centerRight, // 右寄せにする
                          child: Text(
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

  void _checkAnswer(String selectedChoice) {
    int judgeValue = 0; // 判定値を保持
    int nowJudgeValue = 0;

    if (quizDataList[_randomIndex]['judge'] != null) {
      nowJudgeValue = quizDataList[_randomIndex]['judge'];
    }

    if (selectedChoice == correctAnswer) {
      // 正解の処理
      judgeValue = 2;
      _isCorrect = true;
      correctAnswerCount++;
      audioPlayer.play(AssetSource("audios/correct.mp3"));
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
    _tabController.animateTo(1);
    setState(() {
      if (!_isAnswered) {
        totalQuestionCount++;
      }
      _isAnswered = true;
    });

    // 正答率を計算
    correctPercentage = (correctAnswerCount / totalQuestionCount) * 100;
    // 小数点第一位まで
    correctPercentage = (correctPercentage * 10).round() / 10;
    // データベースのjudgeフィールドを更新
    if (nowJudgeValue != 2) {
      _database!.update(
        'quizData',
        {'judge': judgeValue}, // judgeフィールドを更新
        where: 'id = ?', // 条件
        whereArgs: [quizDataList[_randomIndex]['id']], // 条件に渡す引数
      );
    }
  }
}
