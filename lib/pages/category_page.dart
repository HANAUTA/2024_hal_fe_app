import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fe_project/pages/question_page.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  _CategoryPageState createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {

  Map<String, List<dynamic>> seriesMap = {}; // series_nameごとのリストを保存するマップ

  // Firestoreからデータを取得し、series_nameごとに分類
  Future<void> fetchQuestion() async {
    final docRef = FirebaseFirestore.instance
        .collection('contents')
        .doc('data')
        .collection('quizzes')
        .doc('data1');

    final docSnapshot = await docRef.get();
    final datas = docSnapshot.data();

    if (datas != null && datas.containsKey('quizDataList')) {
      List<dynamic> quizDataList = datas['quizDataList'] as List<dynamic>;

      // quizDataListをseries_nameごとに分類
      Map<String, List<dynamic>> tempSeriesMap = {};
      for (var quizData in quizDataList) {
        String seriesName = quizData['series_name'];

        // series_nameが既に存在するかを確認し、リストに追加
        if (!tempSeriesMap.containsKey(seriesName)) {
          tempSeriesMap[seriesName] = [];
        }
        tempSeriesMap[seriesName]!.add(quizData);
      }

      setState(() {
        seriesMap = tempSeriesMap; // series_nameごとのリストをセット
      });

      // seriesMapをデバッグ用にprintする
      print(seriesMap.keys);
    }
  }



  final String categoryName = "テクノロジ系"; // 後で動的に変える
  static const double blockHeight = 75.0;
  static const Map<String, List<String>> categoryMap = {
    "テクノロジ系": [
      "テクノロジーまとめ",
      "基礎理論",
      "アルゴリズムとプログラミング",
      "コンピュータの構成要素",
      "システムの構成要素",
      "ソフトウェア",
      "ハードウェア",
      "ヒューマンインターフェイス",
      "マルチメディア",
      "データベース",
      "ネットワーク",
      "セキュリティ",
      "システム開発技術",
      "ソフトウェア開発管理技術"
    ],
    "ストラテジ系": ["aaa", "iii"],
    "マネジメント系": ["mamamaa", "mimimi"],
  };

  final int correctAnswers = 250; // 正解数
  final int totalQuestions = 500; // 総問題数
  double progress = 0.0;

  @override
  void initState() {
    super.initState();
    // 進捗計算を行う
    progress = correctAnswers / totalQuestions;
    fetchQuestion();
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text('カテゴリ詳細'),
      ),
      body: SafeArea(
        child: Container(
          color: const Color(0xFFE4F9F5), // SafeAreaの背景色を設定
          child: Column(
            children: [
              // 正解数と進捗バーを表示
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Column(
                  children: [
                    Text(
                      '正解数 $correctAnswers / $totalQuestions 問中',
                      style: const TextStyle(
                        fontSize: 20.0, // フォントサイズを固定
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10.0),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8, // バーの幅
                      height: 20.0, // バーの高さ
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black, width: 0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: progress, // 進捗率に基づいてバーの幅を調整
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(width: 0),
                                borderRadius: BorderRadius.circular(10),
                                color: const Color(0xFF30E3CA), // 正解の進捗部分の色
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    // 50%と100%のラベル表示
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Spacer(),
                          Text('50%'),
                          Spacer(),
                          Text('100%'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // カテゴリーリスト
              Expanded(
                child: ListView.builder(
                  itemCount: categoryMap[categoryName]!.length,
                  itemBuilder: (context, index) {
                    return Container(
                      height: blockHeight,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFFFFFFFF), // 下線の色を設定
                            width: 1.0, // 下線の幅を設定
                          ),
                        ),
                      ),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const QuestionPage(), // 次のページに遷移
                            ),
                          );
                        },
                        title: Text(categoryMap[categoryName]![index]), // 各カテゴリー名を表示
                        trailing: const Icon(Icons.keyboard_arrow_right),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
