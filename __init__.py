from flask import Flask
from .server.database import mongo

def create_app():
    app = Flask(__name__)
    app.config.from_object("config.Config")
    mongo.init_app(app)
    return app

