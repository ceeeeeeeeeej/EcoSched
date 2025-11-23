import os
from typing import List, Optional

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

try:
    from google import genai
except Exception as import_error:  # pragma: no cover
    raise RuntimeError(
        "google-genai is not installed. Run: pip install -r requirements.txt"
    ) from import_error


GEMINI_MODEL_DEFAULT = "gemini-2.5-flash"

SYSTEM_INSTRUCTION = (
    "You are EcoSched Assistant for Tago, Surigao del Sur, Philippines. "
    "Detect the user's language (English, Filipino/Tagalog, Cebuano/Bisaya, or Tandaganon) and reply "
    "in the same language. Keep answers to 1–2 short, specific sentences focused on municipal waste "
    "management: collection schedules, segregation rules, pickup requests, reporting missed pickups, "
    "drop-off points, and local contacts. If a question is not about waste management or Tago, ask for "
    "a waste-related question for Tago. When replying in Cebuano/Bisaya or Tandaganon, use clear local "
    "terms and simple phrasing."
)


class ChatRequest(BaseModel):
    message: str = Field(..., min_length=1)
    history: Optional[List[str]] = None
    model: Optional[str] = GEMINI_MODEL_DEFAULT


class ChatResponse(BaseModel):
    text: str


app = FastAPI(title="EcoSched AI Chat API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def _get_client() -> "genai.Client":
    api_key = os.getenv("GEMINI_API_KEY") or os.getenv("GOOGLE_API_KEY")
    if not api_key:
        raise RuntimeError("GEMINI_API_KEY (or GOOGLE_API_KEY) is not set")
    return genai.Client(api_key=api_key)


def _build_contents(system_instruction: str, history: Optional[List[str]], message: str) -> str:
    transcript: List[str] = []
    if history:
        transcript.extend(history[-10:])  # keep last 10 turns
    transcript.append(f"User: {message}")
    conversation = "\n".join(transcript)
    prompt = (
        f"{system_instruction}\n\nConversation so far:\n{conversation}\n\n"
        f"Reply concisely (1–2 sentences):"
    )
    return prompt


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}


@app.post("/chat", response_model=ChatResponse)
def chat(req: ChatRequest) -> ChatResponse:
    try:
        client = _get_client()
        contents = _build_contents(SYSTEM_INSTRUCTION, req.history, req.message)
        resp = client.models.generate_content(model=req.model or GEMINI_MODEL_DEFAULT, contents=contents)
        text = getattr(resp, "text", None)
        if not text:
            raise HTTPException(status_code=502, detail="Empty response from model")
        return ChatResponse(text=text.strip())
    except HTTPException:
        raise
    except Exception as e:  # pragma: no cover
        raise HTTPException(status_code=500, detail=str(e)) from e


