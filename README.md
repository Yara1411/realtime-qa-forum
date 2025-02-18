# Real-Time Q&A Forum

## Overview
This project is a real-time Q&A forum that allows users to create, retrieve, update, and delete questions, as well as post answers. The real-time feature applies **only to adding answers**, meaning that when an answer is added, all connected users viewing the question will see the update in real-time. However, creating and updating questions is **not** real-time.

The project consists of a **Flask backend** and a **Flutter frontend**.

---

## Backend (Flask)
- **Python 3.9**
- **Flask** for API development
- **MongoDB** as the database
- **Flask-SocketIO** for real-time WebSocket communication
- **Dockerized** for easy deployment

### API Features:
- **Create a Question** (`POST /questions`)
- **Retrieve All Questions** (`GET /questions`)
- **Retrieve a Specific Question** (`GET /questions/<question_id>`)
- **Update a Question** (`PUT /questions/<question_id>`)
- **Update an Answer** (`PUT /questions/<question_id>/<answers/<int::answer_index>`)
- **Delete a Question** (`DELETE /questions/<question_id>`)
- **Delete all Questiona** (`DELETE /questions`)
- **Add an Answer (Real-Time Update Enabled)** (`POST /questions/<question_id>/answers`)

When an answer is added, a **WebSocket event** (`new_answer`) is emitted, updating all connected users viewing the question in real-time.

---

## Frontend (Flutter)
- **Flutter** is used for the UI to interact with the API.
- Users can submit and view questions and answers.
- The frontend listens for WebSocket events to receive real-time updates when new answers are added.

---

## Installation & Setup
### **1. Clone the Repository**
Ensure you have Git installed, then run:
```sh
 git clone <http-github-repo-url>
 cd realtime-qa-forum
```

### **2. Install Dependencies**
Ensure you are using **Python 3.9**.

---

## Running the Application with Docker
To start the backend and database, run:
```sh
docker-compose up --build
```
This will:
- Start the **Flask backend** (running on `http://localhost:5000`)
- Start **MongoDB** (running on `mongodb://localhost:27017`)

Once the containers are running, you can:
- Access main UI page for forum at http://localhost:8080
- Use Postman, `curl`, or the frontend app to interact with the API.
- Open a WebSocket client (such as Postman’s WebSocket tool) and connect to `ws://localhost:5000/` to listen for new answers in real-time.
  
---

## API Usage Examples
### **Create a Question**
```sh
curl -X POST http://localhost:5000/questions -H "Content-Type: application/json" -d '{"title": "What is Flask?", "content": "Explain Flask framework."}'
```

### **Get All Questions**
```sh
curl -X GET http://localhost:5000/questions
```

### **Add an Answer (Triggers Real-Time Update)**
```sh
curl -X POST http://localhost:5000/questions/<question_id>/answers -H "Content-Type: application/json" -d '{"answer": "Flask is a micro web framework for Python."}'
```
(Replace `<question_id>` with an actual question ID.)

---


