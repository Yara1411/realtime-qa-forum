import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;
import 'package:socket_io_client/socket_io_client.dart' as IO;

class QuestionDetailsScreen extends StatefulWidget {
    @override
    _QuestionDetailsScreenState createState() => _QuestionDetailsScreenState();
}

class _QuestionDetailsScreenState extends State<QuestionDetailsScreen> {
    Map<String, dynamic>? question;
    List<dynamic> answers = [];
    bool isLoading = true;
    final TextEditingController _answerController = TextEditingController();
    bool isSubmitting = false;
    WebSocketChannel? channel;

    @override
    void didChangeDependencies() {
        super.didChangeDependencies();
        final Map<String, dynamic>? args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

        if (args != null) {
        setState(() {
            question = args;
        });

            final questionId = question!['_id']?.toString() ?? question!['id']?.toString() ?? "";

            if (questionId.isEmpty) {
                print("ERROR: Question ID is null or empty");
            } else {
                fetchAnswers(questionId);
                connectToSocketIO(questionId);
            }
        } else {
            print("ERROR: No question arguments found!");
        }
    }

    Future<void> fetchAnswers(String questionId) async {
        try {
            final response = await http.get(Uri.parse('http://localhost:5000/questions/$questionId'));

            if (response.statusCode == 200) {
                Map<String, dynamic> data = jsonDecode(response.body);
                setState(() {
                    question = data;
                    answers = data['answers'] ?? [];
                    isLoading = false;
                });
            } else {
                throw Exception('Failed to load answers');
            }
        } catch (e) {
            setState(() {
            isLoading = false;
            });
        }
    }

    IO.Socket? socket;

    void connectToSocketIO(String questionId) {
        if (socket != null && socket!.connected) {
            socket!.disconnect();
            socket!.dispose();
            socket = null;
        }
        socket = IO.io('http://localhost:5000', <String, dynamic>{
            'transports': ['websocket'],
            'autoConnect': false,
        });

        socket!.connect();

        socket!.onConnect((_) {

        socket!.emit("join_question", {"question_id": questionId});
        });


        socket!.on("new_answer", (data) {
            if (data is Map<String, dynamic> && data.containsKey("answer")) {
                setState(() {
                    answers.add(data["answer"]);
                });
            } else {
                print("Unexpected data format: $data");
            }
        });
        socket!.onDisconnect((_) {
               print(" WebSocket disconnected!");
        });

        socket!.onError((error) {
            print("WebSocket error: $error");
        });
    }

    Future<void> submitAnswer() async {
        if (_answerController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Answer cannot be empty")),
            );
            return;
        }

        setState(() {
            isSubmitting = true;
        });

        try {
            final response = await http.post(
                Uri.parse('http://localhost:5000/questions/${question!['_id']}/answers'),
                headers: {"Content-Type": "application/json"},
                body: jsonEncode({
                "content": _answerController.text,
                }),
            );

            if (response.statusCode == 201) {
                _answerController.clear();
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
    void dispose() {
        socket?.disconnect();
        socket?.dispose();
        socket = null;
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        if (question == null) {
            return Scaffold(
                appBar: AppBar(title: Text('Question Details')),
                body: Center(child: Text('No question selected')),
                );
        }

        return Scaffold(
            appBar: AppBar(title: Text(question!['title'] ?? 'Question Details')),
            body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Padding(
                    padding: const EdgeInsets.all(16.0),
                        child: Text(
                            question!['content'] ?? '',
                            style: TextStyle(fontSize: 18),
                        ),
                    ),
                    Divider(),
                    Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                            'Answers:',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                    ),
                    Expanded(
                        child: isLoading
                        ? Center(child: CircularProgressIndicator())
                        : answers.isEmpty
                            ? Center(child: Text('No answers yet'))
                            : ListView.builder(
                                itemCount: answers.length,
                                itemBuilder: (context, index) {
                                return ListTile(
                                    title: Text(answers[index]['content'] ?? 'No answer'),
                                );
                            },
                        ),
                    ),
                    Divider(),
                    Padding(
                    padding: const EdgeInsets.all(16.0),
                        child: Column(
                            children: [
                                TextField(
                                controller: _answerController,
                                decoration: InputDecoration(labelText: "Your Answer"),
                                maxLines: 3,
                                ),
                        SizedBox(height: 10),
                            ElevatedButton(
                                onPressed: isSubmitting ? null : submitAnswer,
                                child: isSubmitting
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text("Submit Answer"),
                            ),
                        ],
                    ),
                ),
            ],
        ),
    );
  }
}




