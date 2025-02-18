import 'package:flutter/material.dart';
import 'screens/questions_list.dart';
import 'screens/question_details.dart';
import 'screens/create_question.dart';
import 'screens/update_question.dart';

void main() {
    runApp(MyApp());
}

class MyApp extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Real-time Q&A Forum',
        theme: ThemeData(
        primarySwatch: Colors.blue,
        ),
        initialRoute: '/',
        routes: {
            '/': (context) => QuestionsListScreen(),
            '/question': (context) => QuestionDetailsScreen(),
            '/create-question': (context) => CreateQuestionScreen(),
            '/update-question': (context) => UpdateQuestionScreen(),
        },
    );
  }
}

