import 'package:fe_project/services/database/quiz_data.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatelessWidget {
  SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFFC58940),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFF5F7FA),
              const Color(0xFFFFFFFF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildLinkTile(
              title: 'プライバシーポリシー',
              icon: Icons.privacy_tip,
              url: 'https://note.com/assist_work/n/nb8efc32958b2',
              context: context,
            ),
            _buildLinkTile(
              title: 'お問い合わせ',
              icon: Icons.contact_mail,
              url: 'https://note.com/assist_work/n/n5988b2ffd70a',
              context: context,
            ),
            _buildLinkTile(
              title: '利用規約',
              icon: Icons.description,
              url: 'https://note.com/assist_work/n/n28b44c01d91f',
              context: context,
            ),
            const Divider(),
            _buildSettingsTile(
              context,
              title: 'アプリの説明',
              icon: Icons.info,
              onTap: () {
                _showInfoDialog(
                  context,
                  'アプリ説明',
                  'このアプリは基本情報科目Aを学ぶためのアプリです。\n'
                      'クイズを解いて学習を進めましょう！',
                );
              },
            ),
            const Divider(),
            _buildSettingsTile(
              context,
              title: 'クイズ進捗のリセット',
              icon: Icons.refresh,
              onTap: () {
                _showResetConfirmation(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        child: ListTile(
          title: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          leading: Icon(icon, color: const Color(0xFFC58940), size: 28),
          trailing:
              const Icon(Icons.keyboard_arrow_right, color: Colors.black54),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildLinkTile({
    required String title,
    required IconData icon,
    required String url,
    required BuildContext context,
  }) {
    return _buildSettingsTile(
      context,
      title: title,
      icon: icon,
      onTap: () async {
        final Uri uri = Uri.parse(url);
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          throw 'Could not launch $url';
        }
      },
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
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
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('確認'),
          content: const Text('データをリセットしますか？'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC58940),
              ),
              onPressed: () async {
                await reset();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('データをリセットしました')),
                );
              },
              child: const Text('リセット', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> reset() async {
    var quizDataInstance = QuizData();
    await quizDataInstance.initDb();
    await quizDataInstance.resetProgress();
  }
}
