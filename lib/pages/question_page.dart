import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionPage extends StatefulWidget {
  const QuestionPage({super.key});

  @override
  _QuestionPageState createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  int _currentTabIndex = 0; // 現在のタブのインデックスを保持
  Database? _database; // データベースのインスタンス
  List<Map<String, dynamic>> quizDataList = [];
  int _randomIndex = 0; // ランダムな問題のインデックスを保持

  @override
  void initState() {
    super.initState();
    _initDbAndFetchData(); // DBの初期化とデータ取得を実行
  }

  Future<void> _initDbAndFetchData() async {
    _database = await initializeDb(); // ローカルデータベースの初期化
    await loadQuizData(); // ローカルDBからデータを読み込み
    await setRandomIndex(); // クイズデータを設定
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
    final List<Map<String, dynamic>> maps = await _database!.query('quizData');
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
    final quizLength = quizDataList.length;
    if (quizLength > 0) {
      final random = Random();
      setState(() {
        _randomIndex = random.nextInt(quizLength); // 0からquizLengthの範囲でランダムなインデックスを選ぶ
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width; // 画面の幅を取得
    final buttonSize = screenWidth * 0.15; // ボタンのサイズを画面幅の15%に設定
    final quizData = quizDataList.isNotEmpty ? quizDataList[_randomIndex] : {}; // ランダムに選ばれたクイズデータ
    final quizChoices = {
      quizData['mistake1'].substring(0, 1): quizData['mistake1'].substring(2),
      quizData['mistake2'].substring(0, 1): quizData['mistake2'].substring(2),
      quizData['mistake3'].substring(0, 1): quizData['mistake3'].substring(2),
      quizData['answer'].substring(0, 1): quizData['answer'].substring(2),
    };

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
        title: const Text('Question Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score and percentage row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("正解数3 / 4問中"),
                Text("正答率75.0%"),
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
                        _currentTabIndex = 1; // "解説"タブがタップされたとき
                      });
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
              Text(
                quizData['question'] ?? "問題が見つかりませんでした。",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              // Scrollable area for question options
              Expanded(
                child: SingleChildScrollView(
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
                  child: Container(
                    margin: const EdgeInsets.all(8.0), // 周りにマージンを追加
                    padding: const EdgeInsets.all(16.0), // 内側にパディングを追加
                    decoration: BoxDecoration(
                      color: Colors.grey[200], // 背景色を淡いグレーに変更
                      borderRadius: BorderRadius.circular(10), // 角を丸くする
                    ),
                    child: Text(
                      quizData['comment'] ?? "解説が見つかりませんでした。",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ],
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
              await setRandomIndex();
              setState(() {
                _currentTabIndex = 0; // 問題タブに切り替え
              });
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
                      await setRandomIndex();
                      setState(() {
                        _currentTabIndex = 0; // 問題タブに切り替え
                      });
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
                    _checkAnswer(quizChoices['ア'] ?? "選択肢が見つかりませんでした。", context);
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
                    _checkAnswer(quizChoices['イ'] ?? "選択肢が見つかりませんでした。", context);
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
                    _checkAnswer(quizChoices['ウ'] ?? "選択肢が見つかりませんでした。", context);
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
                    _checkAnswer(quizChoices['エ'] ?? "選択肢が見つかりませんでした。", context);
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
        borderRadius: BorderRadius.circular(8),
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

  void _checkAnswer(String selectedChoice, context) async {
    final correctAnswer = quizDataList[_randomIndex]['answer'].substring(2).trim(); // 正解を取得してトリム
    selectedChoice = selectedChoice.trim(); // 選択肢もトリムして比較

    // 選択肢の判定に基づいてjudgeの値を設定
    int judgeValue = selectedChoice == correctAnswer ? 2 : 1;
    // データベースのjudgeフィールドを更新
    await _database!.update(
      'quizData',
      {'judge': judgeValue}, // judgeフィールドを更新
      where: 'id = ?', // 条件
      whereArgs: [quizDataList[_randomIndex]['id']], // 条件に渡す引数
    );

    if (selectedChoice == correctAnswer) {
      // 正解の処理
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("正解！"),
            content: const Text("おめでとうございます！正しい答えです。"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _currentTabIndex = 1; // 解説タブに切り替え
                  });
                },
                child: const Text("解説を見る"),
              ),
            ],
          );
        },
      );
    } else {
      // 不正解の処理
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("不正解"),
            content: const Text("残念！もう一度考えてみてください。"),
          );
        },
      );

      // 1秒後に自動でダイアログを閉じて解説タブに移動
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.of(context).pop(); // ダイアログを閉じる
        setState(() {
          _currentTabIndex = 1; // 解説タブに切り替え
        });
      });
    }
  }
}
