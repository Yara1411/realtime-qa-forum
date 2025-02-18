import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class QuestionsListScreen extends StatefulWidget {
    @override
    _QuestionsListScreenState createState() => _QuestionsListScreenState();
}

class _QuestionsListScreenState extends State<QuestionsListScreen> {
    List<Map<String, dynamic>> questions = [];
    bool isLoading = true;

    @override
    void initState() {
        super.initState();
        fetchQuestions();
    }

    Future<void> fetchQuestions() async {
        try {
            final response = await http.get(Uri.parse('http://localhost:5000/questions'));

            if (response.statusCode == 200) {
                List<dynamic> data = jsonDecode(response.body);
                setState(() {
                    questions = data.cast<Map<String, dynamic>>().reversed.toList(); // Sort newest first
                    isLoading = false;
                });
            } else {
                throw Exception('Failed to load questions');
            }
        } catch (e) {
            setState(() {
                isLoading = false;
            });
        }
    }
    Future<void> deleteQuestion(String questionId) async {
        try {
            final response = await http.delete(Uri.parse('http://localhost:5000/questions/$questionId'));

            if (response.statusCode == 200) {
                setState(() {
                    questions.removeWhere((q) => q['_id'] == questionId);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Question deleted successfully!")),
                );
            } else {
                throw Exception('Failed to delete question');
            }
        } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error deleting question")),
            );
        }
    }


    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(title: Text('Questions List')),
            body: isLoading
            ? Center(child: CircularProgressIndicator())
            : questions.isEmpty
            ? Center(child: Text('No questions available'))
            : ListView.builder(
                itemCount: questions.length,
                itemBuilder: (context, index) {
                    final question = questions[index];

                    return ListTile(
                        title: Text(question['title'] ?? 'Untitled'),
                        subtitle: Text(question['content'] ?? ''),
                        onTap: () => Navigator.pushNamed(
                            context,
                            '/question',
                            arguments: {
                                'id': question['_id'],
                                'title': question['title'],
                                'content': question['content'],
                            },
                        ),
                        trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                            IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                                Navigator.pushNamed(
                                    context,
                                    '/update-question',
                                    arguments: {
                                    'id': question['_id'],
                                    'title': question['title'],
                                    'content': question['content'],
                                        },
                                    );
                                },
                            ),
                            IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                    showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                            return AlertDialog(
                                                title: Text("Confirm Delete"),
                                                content: Text("Are you sure you want to delete this question?"),
                                                actions: [
                                                    TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: Text("Cancel"),
                                                    ),
                                                TextButton(
                                                onPressed: () {
                                                    Navigator.pop(context); // Close the dialog
                                                    deleteQuestion(question['_id']); // Call delete function
                                                },
                                                child: Text("Delete", style: TextStyle(color: Colors.red)),
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
                },
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () => Navigator.pushNamed(context, '/create-question'),
                child: Icon(Icons.add),
            ),
        );
    }
}
