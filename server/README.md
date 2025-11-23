EcoSched AI Chat Backend (FastAPI)

Setup
- Python 3.10+
- Install deps: pip install -r requirements.txt
- Set key: set GEMINI_API_KEY=AIxxxxxxxxxxxxxxxxxxxxxxxx
- Run: uvicorn main:app --reload --port 8000

Endpoints
- GET /health → {"status":"ok"}
- POST /chat → {"text":"..."}

Example request
{
  "message": "Pickup schedule in Tago this week?",
  "history": ["User: Hello", "Assistant: Hi!"],
  "model": "gemini-2.5-flash"
}

Notes
- Specialized for Tago, Surigao del Sur. Replies are short (1–2 sentences).
- For production, restrict CORS and use HTTPS.

