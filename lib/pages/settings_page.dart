import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

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
        ],
      ),
    );
  }
}
