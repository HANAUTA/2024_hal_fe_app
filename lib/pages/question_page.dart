import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';




class QuestionPage extends StatefulWidget {
  const QuestionPage({super.key});

  @override
  _QuestionPageState createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  int _currentTabIndex = 0; // 現在のタブのインデックスを保持

  // Future<void> fetchQuestion() async {
  //   final docRef = FirebaseFirestore.instance
  //       .collection('contents') // First part of the path
  //       .doc('data') // Second part of the path
  //       .collection('quizzes') // Third part of the path
  //       .doc('data1'); // Fourth part of the path
  //
  //   final docSnapshot = await docRef.get();
  //   final datas = docSnapshot.data();
  //   print(datas!["quizDataList"][0]["series_name"]);
  // }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width; // 画面の幅を取得
    final buttonSize = screenWidth * 0.15; // ボタンのサイズを画面幅の15%に設定
    // print('---------');
    // fetchQuestion();
    // print('---------');
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
            if (_currentTabIndex == 0) ...[
              const Text(
                "インターネットVPNのセキュリティに関する記述のうち、適切なものはどれか。",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              // Scrollable area for question options
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // First description (ア)
                      buildOptionWithBorder("ア",
                          "IPアドレスを悪用した不正アクセスや侵入の危険性はないので、IPアドレスも含めたパケット全体の暗号化は必要ない。"),
                      const SizedBox(height: 10),
                      buildOptionWithBorder("イ", "iii"),
                      const SizedBox(height: 10),
                      buildOptionWithBorder("ウ", "uuu"),
                      const SizedBox(height: 10),
                      buildOptionWithBorder("エ", "eee"),
                    ],
                  ),
                ),
              ),
            ] else if (_currentTabIndex == 1) ...[
              // 解説タブが選択されたときの内容
              const Text(
                "購買，生産，販売及び物流の一連の業務を，企業間で全体最適の視点から見直し，納期短縮や在庫削減を図る。 SCM(Supply Chain Management)の説明です。   資材の調達から生産，保管，販売に至るまでの物流全体を，費用対効果が最適になるように総合的に管理し，合理化する。 物流管理システムの説明です。   電子・電機メーカーから，製品の設計や資材の調達，生産，物流，修理を一括して受託する。 EMS(Electronics Manufacturing Service)の説明です。   物流業務に加え，流通加工なども含めたアウトソーシングサービスを行い，また荷主企業の物流企画も代行する。 正しい。3PLの説明です。",
                style: TextStyle(fontSize: 16),
              ),
              // ここに解説の詳細を追加
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
            onTap: () {
              // 次のページに遷移
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QuestionPage()),
              );
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
                      // 右矢印ボタンのタップ時の動作
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const QuestionPage()),
                      );
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
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_right, size: 30),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const QuestionPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build options with bottom border only
  Widget buildOptionWithBorder(String label, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10), // 上下にパディングを追加
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey), // 下部にボーダーを追加
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label : ", style: const TextStyle(fontSize: 16)),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  // Helper method to build answer buttons with dynamic size
  Widget buildAnswerButton(String label, double buttonSize, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: SizedBox(
        width: buttonSize, // 動的なボタンサイズ
        height: buttonSize, // 動的なボタンサイズ
        child: FittedBox(
          fit: BoxFit.scaleDown, // コンテンツが収まるようにスケーリング
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: Size(buttonSize, buttonSize),
              shape: const CircleBorder(), // ボタンを円形に
              alignment: Alignment.center, // 中央揃え
            ),
            onPressed: onPressed,
            child: Text(label, textAlign: TextAlign.center), // テキストも中央揃え
          ),
        ),
      ),
    );
  }
}
