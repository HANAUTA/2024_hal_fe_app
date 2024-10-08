import 'package:flutter/material.dart';

class QuestionPage extends StatefulWidget {
  const QuestionPage({super.key});

  @override
  _QuestionPageState createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  int _currentTabIndex = 0; // 現在のタブのインデックスを保持

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width; // 画面の幅を取得
    final buttonSize = screenWidth * 0.15; // ボタンのサイズを画面幅の15%に設定

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
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: const Text(
                          "ア：IPアドレスを悪用した不正アクセスや侵入の危険性はないので、IPアドレスも含めたパケット全体の暗号化は必要ない。",
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Scrollable options (イ, ウ, エ, etc.)
                      buildOption("イ", "iii"),
                      buildOption("ウ", "uuu"),
                      buildOption("エ", "eee"),
                      buildOption("オ", "ooo"),
                      buildOption("カ", "kkk"),
                    ],
                  ),
                ),
              ),
            ] else if (_currentTabIndex == 1) ...[
              // 解説タブが選択されたときの内容
              const Text(
                "解説内容をここに表示します。",
                style: TextStyle(fontSize: 16),
              ),
              // ここに解説の詳細を追加
            ],
          ],
        ),
      ),
      // Fixed BottomAppBar
      bottomNavigationBar: Container(
        child: BottomAppBar(
          color: const Color(0xFFE4F9F5),
          child: _currentTabIndex == 0 // "問題"タブの場合
              ? Row(
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
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Expanded(
                child: Center(
                  child: Text('次の問題へ', style: TextStyle(fontSize: 16)),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_right, size: 30),
                onPressed: () {
                  // 次のページに遷移
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

  // Helper method to build options
  Widget buildOption(String label, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
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
