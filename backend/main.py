from fastapi import FastAPI, HTTPException, UploadFile, File, Form
from pydantic import BaseModel
from typing import Optional
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import os
from dotenv import load_dotenv

import ai_service

load_dotenv()

app = FastAPI(title="MedApp Backend")

# Allow requests from the Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods
    allow_headers=["*"],  # Allows all headers
)

class ChatRequest(BaseModel):
    message: str
    
class ChatResponse(BaseModel):
    response: str
    disclaimer: str = "This is an AI-generated response and is not intended as professional medical advice. Please consult a healthcare professional for diagnosis and treatment."

@app.post("/api/chat", response_model=ChatResponse)
async def chat_endpoint(request: ChatRequest):
    """
    Endpoint for text-based symptom checking via MedGemma.
    """
    try:
        # Call the AI service
        ai_response = await ai_service.generate_chat_response(request.message)
        return ChatResponse(response=ai_response)
    except Exception as e:
        print(f"Error in /api/chat: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

@app.post("/api/scan", response_model=ChatResponse)
async def scan_endpoint(
    image: UploadFile = File(...),
    description: Optional[str] = Form("")
):
    """
    Endpoint for image-based condition scanning (using Gemini Vision).
    """
    try:
        # Read image content
        contents = await image.read()
        
        # Call the AI service
        ai_response = await ai_service.analyze_image(contents, image.content_type, description)
        
        return ChatResponse(response=ai_response)
    
    except Exception as e:
        import traceback
        traceback.print_exc()
        print(f"Error in /api/scan: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

@app.get("/health")
def health_check():
    return {"status": "ok"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
