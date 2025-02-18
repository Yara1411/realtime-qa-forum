from marshmallow import Schema, fields, validate, ValidationError
from flask_pymongo import PyMongo
from bson.objectid import ObjectId

def validate_objectid(value):
    try:
        ObjectId(value)
    except Exception:
        raise ValidationError("Invalid question ID format.")

def validate_unique_title(value):
    from app import mongo
    existing_question = mongo.db.questions.find_one({"title": value})
    if existing_question:
        raise ValidationError("A question with this title already exists. Please choose a different title.")

class QuestionSchema(Schema):
    title = fields.String(
        required=True,
        validate=validate.Length(min=5, max=100),
        error_messages={"required": "Title is required."}
    )
    content = fields.String(
        required=True,
        validate=validate.Length(min=10, max=500),
        error_messages={"required": "Content is required."}
    )

class AnswerSchema(Schema):
    content = fields.String(
        required=True,
        validate=validate.Length(min=5, max=300),
        error_messages={"required": "Answer content is required."}
    )

class QuestionUpdateSchema(Schema):
    title = fields.String(validate=validate.Length(min=5, max=100))
    content = fields.String(validate=validate.Length(min=10, max=500))

class AnswerUpdateSchema(Schema):
    content = fields.String(
        required=True,
        validate=validate.Length(min=5, max=300),
        error_messages={"required": "Updated content is required."}
    )

def validate_request_data(schema, data):
    try:
        return schema.load(data), None
    except ValidationError as err:
        return None, {"error": err.messages}, 400
