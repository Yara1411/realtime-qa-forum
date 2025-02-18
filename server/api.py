
from flask import Flask, request, jsonify
from flask_pymongo import PyMongo
from bson.objectid import ObjectId
from extensions import socketio
from flask_cors import CORS
from schemas import ValidationError, QuestionSchema, validate_request_data, AnswerSchema, AnswerUpdateSchema, validate_unique_title
import os


api_app = Flask(__name__)
api_app.config["MONGO_URI"] = os.getenv("MONGO_URI", "mongodb://localhost:27017/qadb") # TODO: Change hostname
mongo = PyMongo(api_app)
CORS(api_app)

@api_app.route("/questions", methods=["POST"])
def create_question():
    data = request.json
    input_error, error_code = validate_request_data(QuestionSchema(), data)

    if error_code:
        return input_error, error_code

    try:
        validate_unique_title(input_error["title"])
    except ValidationError as err:
        return jsonify({"error": err.messages[0]}), 400

    question = {
        "title": data["title"],
        "content": data["content"],
        "answers": []
    }
    question_id = mongo.db.questions.insert_one(question).inserted_id

    return jsonify({"message": "Question created", "id": str(question_id)}), 201


@api_app.route("/questions", methods=["GET"])
def get_questions():
    questions = list(mongo.db.questions.find({}, {"answers": 0}))

    for question in questions:
        question["_id"] = str(question["_id"])

    return jsonify(questions), 200

@api_app.route("/questions/<question_id>", methods=["GET"])
def get_question(question_id):
    question = mongo.db.questions.find_one({"_id": ObjectId(question_id)})

    if not question:
        return jsonify({"error": "Question not found"}), 404
    question["_id"] = str(question["_id"])

    return jsonify(question), 200


@api_app.route("/questions/<question_id>/answers", methods=["POST"])
def add_answers(question_id):
    data = request.json
    input_error, error = validate_request_data(AnswerSchema(), data)
    if error:
        return input_error, error

    answer = {"content": data["content"]}

    mongo.db.questions.update_one(
        {"_id": ObjectId(question_id)},
        {"$push": {"answers": answer}}
    )

    on_new_answer(question_id, answer)

    return jsonify({"message": "Answer added"}), 201


@api_app.route("/questions/<question_id>", methods=["PUT"])
def update_question(question_id):
    data = request.json
    input_error, error_code = validate_request_data(QuestionSchema(), data)
    if error_code:
        return input_error, error_code

    if not data:
        return jsonify({"error": "No valid fields to update"}), 400

    try:
        validate_unique_title(input_error["title"])
    except ValidationError as err:
        return jsonify({"error": err.messages[0]}), 400

    update_fields = {"title": data["title"], "content": data["content"]}

    result = mongo.db.questions.update_one({"_id": ObjectId(question_id)}, {"$set": update_fields})

    if result.matched_count == 0:
        return jsonify({"error": "Question not found"}), 404

    return jsonify({"message": "Question updated"}), 200


@api_app.route("/questions/<question_id>/answers/<int:answer_index>", methods=["PUT"])
def update_answer(question_id, answer_index):
    data = request.json
    input_error, error = validate_request_data(AnswerUpdateSchema(), data)

    if error:
        return input_error, error

    try:
        validate_unique_title(input_error["title"])
    except ValidationError as err:
        return jsonify({"error": err.messages[0]}), 400

    question = mongo.db.questions.find_one({"_id": ObjectId(question_id)})

    if not question:
        return jsonify({"error": "Question not found"}), 404

    if answer_index < 0 or answer_index >= len(question["answers"]):
        return jsonify({"error": "Answer index out of range"}), 400

    question["answers"][answer_index]["content"] = data["content"]
    mongo.db.questions.update_one({"_id": ObjectId(question_id)}, {"$set": {"answers": question["answers"]}})

    return jsonify({"message": "Answer updated"}), 200


@api_app.route("/questions/<question_id>", methods=["DELETE"])
def delete_question(question_id):
    result = mongo.db.questions.delete_one({"_id": ObjectId(question_id)})

    if result.deleted_count == 0:
        return jsonify({"error": "Question not found"}), 404

    return jsonify({"message": "Question deleted"}), 200


@api_app.route("/questions", methods=["DELETE"])
def delete_all_questions():
    mongo.db.questions.delete_many({})

    return jsonify({"message": "All questions deleted"}), 200



def on_new_answer(question_id, answer):
    socketio.emit("new_answer", {"question_id": question_id, "answer": answer}, room=question_id)
