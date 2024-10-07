import 'dart:ffi';

import 'package:fe_project/pages/question_page.dart';
import 'package:flutter/material.dart';

class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String categoryName = "テクノロジ系"; // 後で動的に変える
    const double blockHeight = 75.0;
    const Map<String, List<String>> categoryMap = {
      "テクノロジ系": ["基礎理論", "アルゴリズムとプログラミング", "コンピュータの構成要素", "システムの構成要素", "ソフトウェア", "ハードウェア", "ヒューマンインターフェイス", "マルチメディア", "データベース", "ネットワーク", "セキュリティ", "システム開発技術", "ソフトウェア開発管理技術"],
      "ストラテジ系": ["aaa", "iii"],
      "マネジメント系": ["mamamaa", "mimimi"],
    };
    const List<String> categoryList = ["基礎理論", "アルゴリズムとプログラミング", "コンピュータの構成要素", "システムの構成要素", "ソフトウェア", "ハードウェア", "ヒューマンインターフェイス", "マルチメディア", "データベース", "ネットワーク", "セキュリティ", "システム開発技術", "ソフトウェア開発管理技術"];

    return Scaffold(
      appBar: AppBar(
        leading:
        ListTile(
          onTap:(){ Navigator.pop(context);}
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('カテゴリ詳細'),
      ),
      body:
        ListView.builder(
          itemCount: categoryMap[categoryName]!.length,
          itemBuilder: (context, index) {
            return  Container(
            height: blockHeight,
            child: ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuestionPage(), // 次のページに遷移
                  ),
                );
              },
              title: Text(categoryMap[categoryName]![index]), // 各カテゴリー名を表示
              trailing: Icon(Icons.keyboard_arrow_right),
              ),
            );
    }// ListView(

        ));
    }
  }
