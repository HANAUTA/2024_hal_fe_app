import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart'; // 追加: シェア機能用
import 'package:vibration/vibration.dart'; // 追加: 振動機能用

class ResultPage extends StatefulWidget {
  final int correctAnswerCount;
  final int totalQuestionCount;
  final String correctPercentage;

  const ResultPage({
    super.key,
    required this.correctAnswerCount,
    required this.totalQuestionCount,
    required this.correctPercentage,
  });

  @override
  _ResultPageState createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isAnimating = false; // アニメーションの状態を管理するフラグ

  @override
  void initState() {
    super.initState();

    // アニメーションコントローラーの初期化
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation =
        Tween<double>(begin: 1.0, end: 1.5).animate(_controller); // スケールアニメーション

    // 全問正解の場合にアニメーションを実行
    if (widget.correctAnswerCount == widget.totalQuestionCount) {
      _startAnimation();
      Vibration.vibrate(duration: 1000); // 1秒間振動
    }
  }

  void _startAnimation() {
    _isAnimating = true;
    _controller.forward().then((_) {
      _controller.reverse().then((_) {
        _controller.forward().then((_) {
          _controller.reverse().then((_) {
            _isAnimating = false; // アニメーションが完了したらフラグをリセット
          });
        });
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // コントローラーの破棄
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // デバイスの画面サイズに基づくレスポンシブ設定
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    final padding = screenHeight * 0.03;
    final buttonHeight = screenHeight * 0.07;
    final buttonWidth = screenWidth * 0.6;
    final fontSize = screenHeight * 0.03;

    // グラデーションの定義
    final Shader linearGradient = const LinearGradient(
      colors: <Color>[
        Color(0xFF0000FF), // 青
        Color(0xFF4B0082), // 藍
        Color(0xFF9400D3), // 紫
      ],
    ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)); // 幅を調整

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('結果'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF00BFA6), Color(0xFF005662)],
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: screenHeight * 0.1),
                  Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    shadowColor: Colors.black26,
                    child: Padding(
                      padding: EdgeInsets.all(padding * 1.5),
                      child: Column(
                        children: [
                          Text(
                            "正解数 ${widget.correctAnswerCount} / ${widget.totalQuestionCount} 問中",
                            style: TextStyle(
                              fontSize: fontSize,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "正答率 ${widget.correctPercentage}",
                            style: TextStyle(
                              fontSize: fontSize,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.03),
                          if (widget.correctAnswerCount ==
                              widget.totalQuestionCount) ...[
                            ScaleTransition(
                              scale: _scaleAnimation,
                              child: ShaderMask(
                                shaderCallback: (bounds) {
                                  return linearGradient;
                                },
                                child: Text(
                                  '全問正解！',
                                  style: TextStyle(
                                    fontSize: fontSize * 1.2,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white, // 白に設定
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.07),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                          horizontal: buttonWidth * 0.15,
                          vertical: buttonHeight * 0.4),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.teal,
                      side: const BorderSide(color: Colors.teal, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                    ),
                    child: const Text(
                      'カテゴリ選択',
                      style: TextStyle(
                        fontSize: 18,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                          horizontal: buttonWidth * 0.15,
                          vertical: buttonHeight * 0.4),
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFD70000),
                      side:
                          const BorderSide(color: Color(0xFFD70000), width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                    ),
                    child: const Text(
                      'ホームに戻る',
                      style: TextStyle(
                        fontSize: 18,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  ElevatedButton(
                    onPressed: () {
                      Share.share(
                        '私はクイズで ${widget.correctAnswerCount} / ${widget.totalQuestionCount} 問正解しました！正答率: ${widget.correctPercentage}',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                          horizontal: buttonWidth * 0.15,
                          vertical: buttonHeight * 0.4),
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      '結果をシェア',
                      style: TextStyle(
                        fontSize: 18,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
