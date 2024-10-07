import 'package:flutter/material.dart';

class QuestionPage extends StatelessWidget {
  const QuestionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading:
        ListTile(
            onTap:(){ Navigator.pop(context);}
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('question'),
      ),
    );
  }
}
