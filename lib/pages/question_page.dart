import 'package:flutter/material.dart';

class QuestionPage extends StatelessWidget {
  const QuestionPage({super.key});

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
                  child: Container(
                    color: Colors.pink[200],
                    padding: EdgeInsets.all(8),
                    child: Center(child: Text("問題")),
                  ),
                ),
                Expanded(
                  child: Container(
                    color: Colors.grey[300],
                    padding: EdgeInsets.all(8),
                    child: Center(child: Text("解説")),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            // Question description
            Text(
              "インターネットVPNのセキュリティに関する記述のうち、適切なものはどれか。",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            // Scrollable area
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
                    buildOption("イ", "iii"),
                    buildOption("ウ", "uuu"),
                    buildOption("エ", "eee"),
                    buildOption("オ", "ooo"),
                    buildOption("カ", "kkk"),
                    buildOption("イ", "iii"),
                    buildOption("ウ", "uuu"),
                    buildOption("エ", "eee"),
                    buildOption("オ", "ooo"),
                    buildOption("カ", "kkk"),
                    buildOption("イ", "iii"),
                    buildOption("ウ", "uuu"),
                    buildOption("エ", "eee"),
                    buildOption("オ", "ooo"),
                    buildOption("カ", "kkk"),
                    // Add more options as needed
                  ],
                ),
              ),
            ),
            // Bottom bar with answer buttons and arrow icon
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center, // Aligns vertically
              children: [
                buildAnswerButton("ア"),
                buildAnswerButton("イ"),
                buildAnswerButton("ウ"),
                buildAnswerButton("エ"),
                // Align arrow icon with buttons
                Icon(Icons.keyboard_arrow_right, size: 30),
              ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8.0), // Add horizontal padding between buttons
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: Size(50, 50), // Adjust the button size
        ),
        onPressed: () {
          // Handle button press
        },
        child: Text(label),
      ),
    );
  }
}
