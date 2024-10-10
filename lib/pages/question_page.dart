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
    print(dbPath);
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
    print(quizChoices);


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
              // 新しいランダムな問題を設定して、問題タブに戻る
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
                      // 右矢印ボタンのタップ時も同じ動作をする
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: buildAnswerButton("ア", buttonSize, () {
                  setState(() {
                    _currentTabIndex = 1; // "解説"タブに切り替え
                  });
                }),
              ),
              Expanded(
                child: buildAnswerButton("イ", buttonSize, () {
                  setState(() {
                    _currentTabIndex = 1; // "解説"タブに切り替え
                  });
                }),
              ),
              Expanded(
                child: buildAnswerButton("ウ", buttonSize, () {
                  setState(() {
                    _currentTabIndex = 1; // "解説"タブに切り替え
                  });
                }),
              ),
              Expanded(
                child: buildAnswerButton("エ", buttonSize, () {
                  setState(() {
                    _currentTabIndex = 1; // "解説"タブに切り替え
                  });
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 選択肢ボタンを生成するウィジェット
  Widget buildAnswerButton(String label, double size, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.all(size * 0.2),
        ),
        child: Text(label, style: const TextStyle(fontSize: 18)),
      ),
    );
  }

  // 選択肢のウィジェット（枠付き）
  Widget buildOptionWithBorder(String label, String text) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Text(
        "$label. $text",
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}
