from gevent import monkey
monkey.patch_all()

from ws_app import create_ws_app

if __name__ == "__main__":
    print("Running RealTime QA App")
    create_ws_app(host="0.0.0.0", port=5000, debug=True)


