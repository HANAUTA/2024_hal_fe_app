import 'package:fe_project/services/database/quiz_data.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatelessWidget {

  SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('アプリの説明'),
            leading: const Icon(Icons.info_outline),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('アプリの説明'),
                    content: const Text(
                      'このアプリは基本情報技術者試験の問題に挑戦できるクイズアプリです。'
                          '豊富な問題と選択肢で、あなたの知識を試すことができます。',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('閉じる'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('利用規約'),
            leading: const Icon(Icons.description_outlined),
            onTap: () async {
              final Uri url = Uri.parse('https://note.com/assist_work/n/n28b44c01d91f');
              if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                throw 'Could not launch $url';
              }
            },
          ),
          ListTile(
            title: const Text('プライバシーポリシー'),
            leading: const Icon(Icons.privacy_tip_outlined),
            onTap: () async {
              final Uri url = Uri.parse('https://note.com/assist_work/n/nb8efc32958b2');
              if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                throw 'Could not launch $url';
              }
            },
          ),
          ListTile(
            title: const Text('お問い合わせ'),
            leading: const Icon(Icons.contact_mail_outlined),
            onTap: () async {
              final Uri url = Uri.parse('https://note.com/assist_work/n/n5988b2ffd70a');
              if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                throw 'Could not launch $url';
              }
            },
          ),
          const Divider(),
          // ここにリセットのListTileを追加
          ListTile(
            title: const Text('クイズ進捗のリセット'),
            leading: const Icon(Icons.refresh_outlined),
            onTap: () {
              // 確認ダイアログを表示
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('確認'),
                    content: const Text('データをリセットしますか？'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // ダイアログを閉じる
                        },
                        child: const Text('キャンセル'),
                      ),
                      TextButton(
                        onPressed: () async {
                          // リセットを実行
                          await reset();
                          Navigator.of(context).pop(); // ダイアログを閉じる
                          // 処理完了のメッセージを表示
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('データをリセットしました')),
                          );
                        },
                        child: const Text('リセット'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> reset() async {
    var quizDataInstance = QuizData();
    await quizDataInstance.initDb();
    await quizDataInstance.resetProgress();
  }
}
