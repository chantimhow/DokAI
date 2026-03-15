from fastapi import FastAPI, HTTPException, UploadFile, File, Form
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import os
import requests
from dotenv import load_dotenv

import ai_service

load_dotenv()

app = FastAPI(title="MedApp Backend")


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods
    allow_headers=["*"],  # Allows all headers
)

class ChatRequest(BaseModel):
    message: str
    history: Optional[List[Dict[str, Any]]] = []
    user_profile: Optional[Dict[str, Any]] = None
    
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
        ai_response = await ai_service.generate_chat_response(request.message, request.history, request.user_profile)
        return ChatResponse(response=ai_response)
    except Exception as e:
        print(f"Error in /api/chat: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

@app.post("/api/scan", response_model=ChatResponse)
async def scan_endpoint(
    image: UploadFile = File(...),
    description: Optional[str] = Form(""),
    user_profile: Optional[str] = Form(None)
):
    """
    Endpoint for image-based condition scanning (using Gemini Vision).
    """
    try:
        # Read image content
        contents = await image.read()
        
        # Parse the JSON string from the Form into a dict if it exists
        profile_dict = None
        if user_profile:
            import json
            profile_dict = json.loads(user_profile)

        # Call the AI service
        ai_response = await ai_service.analyze_image(contents, image.content_type, description, profile_dict)
        
        return ChatResponse(response=ai_response)
    
    except Exception as e:
        import traceback
        traceback.print_exc()
        print(f"Error in /api/scan: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

@app.get("/api/clinics")
def get_clinics(lat: float, lon: float):
    """
    Proxies the clinic search query to Overpass API to avoid frontend CORS issues.
    """
    overpass_url = "https://overpass-api.de/api/interpreter"
    query = f"""
        [out:json];
        (
          node["amenity"="clinic"](around:5000,{lat},{lon});
          node["amenity"="hospital"](around:5000,{lat},{lon});
        );
        out 3;
    """
    try:
        response = requests.post(overpass_url, data={"data": query})
        response.raise_for_status()
        return response.json()
    except Exception as e:
        print(f"Error querying Overpass API: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch clinics")

@app.get("/health")
def health_check():
    return {"status": "ok"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
