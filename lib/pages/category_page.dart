import 'package:fe_project/pages/question_page.dart';
import 'package:flutter/material.dart';

class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading:
        ListTile(
          onTap:(){ Navigator.pop(context);}
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('a'),
      ),
      body:
       ListView(
         children: [
           ListTile(
             onTap: (){
               Navigator.push(context, MaterialPageRoute(
                 builder: (context) => QuestionPage()
               ));
             },
           )
         ],
       )
        );
  }
}
