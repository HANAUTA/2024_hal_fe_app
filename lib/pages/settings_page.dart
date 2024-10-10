// settings_page.dart
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          'ここに設定内容を表示',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
