import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:fe_project/constants/category_data.dart';
import 'package:fe_project/services/database/quiz_data.dart';
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
  List<Map<String, dynamic>> quizDataList = [];
  int _randomIndex = 0;
  bool _isLoading = true;
  Map quizChoiceMap = {};
  bool _isCorrect = false;
  String correctAnswer = "";
  int totalQuestionCount = 0;
  int correctAnswerCount = 0;
  double correctPercentage = 0.0;
  bool _isAnswered = true;
  int nextQuestionIndex = 0;
  List<int> randomIndexList = [];
  int quizLength = 0;
  bool isNextExist = false;
  String categoryNum = "";
  String titleText = "";
  ScrollController _questionScrollController = ScrollController();
  ScrollController _choiceScrollController = ScrollController();
  ScrollController _explainScrollController = ScrollController();
  final audioPlayer = AudioPlayer();
  int judgeValue = 0; // クラスのフィールドとして定義し、初期化
  int nowJudgeValue = 0; // 現在の判定値も同様に
  Map<String, String> categoryNumMap = CategoryData.categoryNumMap;
  bool isQuestionLong = false;
  var quizDataInstance = QuizData();


  @override
  void initState() {
    super.initState();
    if (widget.category == "allStage") {
      categoryNum = "_";
    } else if (widget.category == "wrongStage") {
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
    // _scrollController.dispose(); // ScrollControllerを破棄
    _questionScrollController.dispose();
    _choiceScrollController.dispose();
    _explainScrollController.dispose();
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
    await quizDataInstance.initDb();
    setState(() {
      _isLoading = true; // データが読み込まれたらローディング状態を更新
    });
    await loadQuizData(); // ローカルDBからデータを読み込み
    await setRandomIndex(); // クイズデータを設定
    nextQuestion();
    setState(() {
      _isLoading = false; // データが読み込まれたらローディング状態を更新
    });
  }


  Future<void> loadQuizData() async {
    final List<Map<String, dynamic>> maps;
    // クイズデータを取得
    maps = await quizDataInstance.getTargetQuizData(
      targetCategory: widget.category,
      categoryNum: categoryNum,
    );

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
      randomIndexList = List.generate(quizLength, (index) => index);
      randomIndexList.shuffle();
    }
  }

  void nextQuestion() {
    if (nextQuestionIndex + 1 < quizLength) {
      print("next OK");
      isNextExist = true;
    } else {
      // CATEGORYページに戻る
      print('next NG');
      isNextExist = false;
    }
    _randomIndex = randomIndexList[nextQuestionIndex];
    _isCorrect = false;
    nextQuestionIndex++;
    judgeValue = 0;
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
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width; // 画面の幅を取得
    final buttonSize = screenWidth * 0.15; // ボタンのサイズを画面幅の15%に設定
    final quizData = quizDataList.isNotEmpty
        ? quizDataList[_randomIndex]
        : {}; // ランダムに選ばれたクイズデータ

    if (quizData.length != 0) {
      quizChoiceMap = {
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
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .inversePrimary,
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
          color: const Color(0xFFFFFFFF),
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
          color: const Color(0xFFE5BA73),
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
                      builder: (context) =>
                          ResultPage(
                            correctAnswerCount: correctAnswerCount,
                            totalQuestionCount: totalQuestionCount,
                            correctPercentage: '$correctPercentage%',
                          ),
                    ),
                  );
                }
              },
              child: Container(
                color: const Color(0xFFE5BA73),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const Expanded(
                      child: Center(
                        child: Text(
                            '次の問題へ', style: TextStyle(fontSize: 16)),
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
                              builder: (context) =>
                                  ResultPage(
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
          color: const Color(0xFFE5BA73),
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
              ? Scrollbar(
            thickness: 4,
            thumbVisibility: true,
            controller: _questionScrollController,
            child: SingleChildScrollView(
              controller: _questionScrollController, // スクロールコントローラーを追加
              child: Text(
                quizData['question'] ?? "問題が見つかりませんでした。",
                style: const TextStyle(fontSize: 16),
              ),
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
          child: Scrollbar(
            thickness: 4,
            thumbVisibility: true,
            controller: _choiceScrollController,
            child: SingleChildScrollView(
              controller: _choiceScrollController, // スクロールコントローラーを追加
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildOptionWithBorder(
                      "ア",
                      quizChoiceMap['ア'] ?? "選択肢が見つかりませんでした。"),
                  const SizedBox(height: 10),
                  buildOptionWithBorder(
                      "イ",
                      quizChoiceMap['イ'] ?? "選択肢が見つかりませんでした。"),
                  const SizedBox(height: 10),
                  buildOptionWithBorder(
                      "ウ",
                      quizChoiceMap['ウ'] ?? "選択肢が見つかりませんでした。"),
                  const SizedBox(height: 10),
                  buildOptionWithBorder(
                      "エ",
                      quizChoiceMap['エ'] ?? "答えが見つかりませんでした。"),
                  const SizedBox(height: 10),
                ],
              ),
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
          child: Scrollbar(
            controller: _explainScrollController,
            thickness: 4,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _explainScrollController, // スクロールコントローラーを追加
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
                            color: Color(0xFF00704A),
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
    // selectedChoice と correctAnswer の比較と処理
    if (selectedChoice == correctAnswer) {
      if (judgeValue != 2) {
        correctAnswerCount++;
      }
      judgeValue = 2;
      _isCorrect = true;

      // オーディオ関連の処理
      audioPlayer.setVolume(1.0);
      audioPlayer.stop();
      audioPlayer.release();
      audioPlayer.play(AssetSource("audios/correct.wav"));
    } else {
      // judgeValueが2でないときのみ不正解の処理を行う
      _isCorrect = false;
      if (judgeValue != 2) {
        judgeValue = 1; // 不正解の処理
      }
    }

    _tabController.animateTo(1);

    setState(() {
      if (!_isAnswered) {
        totalQuestionCount++;
      }
      _isAnswered = true;
    });

    // 正答率を計算
    correctPercentage = (correctAnswerCount / totalQuestionCount) * 100;
    correctPercentage = (correctPercentage * 10).round() / 10;

    // データベースの judge フィールドを更新
    if (nowJudgeValue != 2) {
      quizDataInstance.updateJudge(
        quizId: quizDataList[_randomIndex]['id'],
        judge: judgeValue,
      );
    }
  }
}