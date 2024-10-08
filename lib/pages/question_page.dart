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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('question'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score and percentage row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("正解数3 / 4問中"),
                Text("正答率75.0%"),
              ],
            ),
            SizedBox(height: 10),
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
                      padding: EdgeInsets.all(8),
                      child: Center(child: Text("問題")),
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
                      padding: EdgeInsets.all(8),
                      child: Center(child: Text("解説")),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            // Question or Explanation content based on the selected tab
            if (_currentTabIndex == 0) ...[
              Text(
                "インターネットVPNのセキュリティに関する記述のうち、適切なものはどれか。",
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
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
                        padding: EdgeInsets.all(10),
                        child: Text(
                          "ア：IPアドレスを悪用した不正アクセスや侵入の危険性はないので、IPアドレスも含めたパケット全体の暗号化は必要ない。",
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      SizedBox(height: 10),
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
              Text(
                "解説内容をここに表示します。",
                style: TextStyle(fontSize: 16),
              ),
              // ここに解説の詳細を追加
            ],
          ],
        ),
      ),
      // Fixed BottomAppBar
      bottomNavigationBar: BottomAppBar(
        child: _currentTabIndex == 0 // "問題"タブの場合
            ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: buildAnswerButton("ア"),
            ),
            Expanded(
              child: buildAnswerButton("イ"),
            ),
            Expanded(
              child: buildAnswerButton("ウ"),
            ),
            Expanded(
              child: buildAnswerButton("エ"),
            ),
            Icon(Icons.keyboard_arrow_right, size: 30), // Always shown
          ],
        )
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center, // 中央寄せ
          children: [
            // '次の問題へ'とアイコンを中央に表示
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0), // テキストとアイコンの間のスペース
              child: Row(
                children: [
                  Text('次の問題へ', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 8), // テキストとアイコンの間のスペース
                  Icon(Icons.keyboard_arrow_right, size: 30), // Always shown
                ],
              ),
            ),
          ],
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
          Text("$label : ", style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  // Helper method to build answer buttons without trailing icon
  Widget buildAnswerButton(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(50, 50),
        ),
        onPressed: () {
          // Handle button press
        },
        child: Text(label),
      ),
    );
  }
}
