import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UpdateQuestionScreen extends StatefulWidget {
    @override
    _UpdateQuestionScreenState createState() => _UpdateQuestionScreenState();
}

class _UpdateQuestionScreenState extends State<UpdateQuestionScreen> {
    final TextEditingController _titleController = TextEditingController();
    final TextEditingController _contentController = TextEditingController();
    bool isUpdating = false;
    String? questionId;

    @override
    void didChangeDependencies() {
        super.didChangeDependencies();
        final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

        if (args != null) {
            questionId = args['id'];
            _titleController.text = args['title'] ?? '';
            _contentController.text = args['content'] ?? '';
        }
    }

    Future<void> updateQuestion() async {
        if (questionId == null || _titleController.text.isEmpty || _contentController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Title and content cannot be empty")),
            );
            return;
        }

        setState(() {
            isUpdating = true;
        });

        try {
            final response = await http.put(
            Uri.parse('http://localhost:5000/questions/$questionId'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
                "title": _titleController.text,
                "content": _contentController.text,
            }),
            );
            if (response.statusCode == 200) {
                ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Question updated successfully!")),
            );
            Navigator.pop(context, true);
            } else {
                final responseBody = jsonDecode(response.body);
                String errorMessage;
                if (responseBody['error'] is String) {
                    errorMessage = responseBody['error'];
                } else if (responseBody['error'] is Map) {
                    errorMessage = responseBody['error'].values.first[0];
                } else {
                    errorMessage = 'Error updating a question';
                }
                throw Exception(errorMessage);
            }
        } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString())),
        );
        } finally {
            setState(() {
                isUpdating = false;
            });
        }
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(title: Text("Update Question")),
            body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
                children: [
                    TextField(
                    controller: _titleController,
                    decoration: InputDecoration(labelText: "Title"),
                    ),
                    SizedBox(height: 10),
                    TextField(
                    controller: _contentController,
                    decoration: InputDecoration(labelText: "Content"),
                    maxLines: 3,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                        onPressed: isUpdating ? null : updateQuestion,
                        child: isUpdating
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text("Update"),
                    ),
                ],
            ),
        ),
    );
  }
}
