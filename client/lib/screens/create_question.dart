import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CreateQuestionScreen extends StatefulWidget {
    @override
    _CreateQuestionScreenState createState() => _CreateQuestionScreenState();
}

class _CreateQuestionScreenState extends State<CreateQuestionScreen> {
    final TextEditingController _titleController = TextEditingController();
    final TextEditingController _contentController = TextEditingController();
    bool isSubmitting = false;

    Future<void> submitQuestion() async {

        if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Title and content cannot be empty")),
            );
            return;
        }

        setState(() {
            isSubmitting = true;
        });

        try {
            final response = await http.post(
            Uri.parse('http://localhost:5000/questions'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
                "title": _titleController.text,
                "content": _contentController.text,
            }),
        );

        if (response.statusCode == 201) {
            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Question created successfully!")),
            );
            Navigator.pop(context);
        } else {
            final responseBody = jsonDecode(response.body);
            final errorMessage = responseBody['error'] ?? 'Failed to create question';
            throw Exception(errorMessage);
            }
        } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
        );
        } finally {
            setState(() {
            isSubmitting = false;
            });
        }
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
        appBar: AppBar(title: Text('Create New Question')),
        body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
            children: [
                TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: "Question Title"),
                ),
                SizedBox(height: 10),
                TextField(
                controller: _contentController,
                decoration: InputDecoration(labelText: "Question Content"),
                maxLines: 4,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                onPressed: isSubmitting ? null : submitQuestion,
                child: isSubmitting
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text("Submit Question"),
                ),
            ],
        ),
      ),
    );
  }
}
