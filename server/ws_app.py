from api import api_app
from extensions import socketio
from flask_socketio import join_room

def create_ws_app(host="0.0.0.0", port=5000, debug=True):
    socketio.init_app(api_app, cors_allowed_origins="*", async_mode="gevent")

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

    socketio.run(api_app, host=host, port=port, debug=debug, use_reloader=False)

