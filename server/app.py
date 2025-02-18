from gevent import monkey
monkey.patch_all()
from flask import Flask, request, jsonify
from flask_pymongo import PyMongo
from bson.objectid import ObjectId
from extensions import socketio
from flask_socketio import join_room
from flask_cors import CORS
import os

app = Flask(__name__)
app.config["MONGO_URI"] = os.getenv("MONGO_URI", "mongodb://localhost:27017/qadb")
mongo = PyMongo(app)
CORS(app)
socketio.init_app(app, cors_allowed_origins="*", async_mode="gevent")

@socketio.on("connect")
def handle_connect():
    print("A client connected via WebSocket", flush=True)

@socketio.on("disconnect")
def handle_disconnect():
    print("A client disconnected from WebSocket")

@socketio.on("join_question")
def handle_join_question(data):
    question_id = data.get("question_id")
    if question_id:
        join_room(question_id)

def broadcast_new_answer(question_id, answer):
    socketio.emit("new_answer", {"question_id": question_id, "answer": answer}, room=question_id)


def on_new_answer(question_id, answer):
    broadcast_new_answer(question_id, answer)

@app.route("/questions", methods=["POST"])
def create_question():
    data = request.json

    if "title" not in data or "content" not in data:
        return jsonify({"error": "Title and content are required"}), 400
    question = {
        "title": data["title"],
        "content": data["content"],
        "answers": []
    }
    question_id = mongo.db.questions.insert_one(question).inserted_id

    return jsonify({"message": "Question created", "id": str(question_id)}), 201


@app.route("/questions", methods=["GET"])
def get_questions():
    questions = list(mongo.db.questions.find({}, {"answers": 0}))

    for question in questions:
        question["_id"] = str(question["_id"])

    return jsonify(questions), 200

@app.route("/questions/<question_id>", methods=["GET"])
def get_question(question_id):
    question = mongo.db.questions.find_one({"_id": ObjectId(question_id)})

    if not question:
        return jsonify({"error": "Question not found"}), 404
    question["_id"] = str(question["_id"])

    return jsonify(question), 200


@app.route("/questions/<question_id>/answers", methods=["POST"])
def add_answers(question_id):
    data = request.json
    if "content" not in data:
        return jsonify({"error": "Answer content is required"}), 400

    answer = {"content": data["content"]}

    mongo.db.questions.update_one(
        {"_id": ObjectId(question_id)},
        {"$push": {"answers": answer}}
    )

    on_new_answer(question_id, answer)

    return jsonify({"message": "Answer added"}), 201


@app.route("/questions/<question_id>", methods=["PUT"])
def update_question(question_id):
    data = request.json
    update_fields = {}

    if "title" in data:
        update_fields["title"] = data["title"]
    if "content" in data:
        update_fields["content"] = data["content"]

    if not update_fields:
        return jsonify({"error": "No valid fields to update"}), 400

    result = mongo.db.questions.update_one({"_id": ObjectId(question_id)}, {"$set": update_fields})

    if result.matched_count == 0:
        return jsonify({"error": "Question not found"}), 404

    return jsonify({"message": "Question updated"}), 200


@app.route("/questions/<question_id>/answers/<int:answer_index>", methods=["PUT"])
def update_answer(question_id, answer_index):
    data = request.json

    if "content" not in data:
        return jsonify({"error": "Updated content is required"}), 400

    question = mongo.db.questions.find_one({"_id": ObjectId(question_id)})

    if not question:
        return jsonify({"error": "Question not found"}), 404

    if answer_index < 0 or answer_index >= len(question["answers"]):
        return jsonify({"error": "Answer index out of range"}), 400

    question["answers"][answer_index]["content"] = data["content"]
    mongo.db.questions.update_one({"_id": ObjectId(question_id)}, {"$set": {"answers": question["answers"]}})

    return jsonify({"message": "Answer updated"}), 200


@app.route("/questions/<question_id>", methods=["DELETE"])
def delete_question(question_id):
    result = mongo.db.questions.delete_one({"_id": ObjectId(question_id)})

    if result.deleted_count == 0:
        return jsonify({"error": "Question not found"}), 404

    return jsonify({"message": "Question deleted"}), 200


@app.route("/questions", methods=["DELETE"])
def delete_all_questions():
    mongo.db.questions.delete_many({})

    return jsonify({"message": "All questions deleted"}), 200


if __name__ == "__main__":
    print("🚀 Running Flask-SocketIO with gevent")
    socketio.run(app, host="0.0.0.0", port=5000, debug=True, use_reloader=False)

