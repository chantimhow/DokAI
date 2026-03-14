import os
import requests
import base64
from dotenv import load_dotenv

load_dotenv()

# User's Flextoken API Configuration
API_URL = "https://aiworkshopapi.flexinfra.com.my/v1/chat/completions"
# Ideally the user puts this back into .env, but we'll use their provided key here for now,
# falling back to the env var if it exists.
API_KEY = os.getenv("FLEXTOKEN_API_KEY", "sk-lByvUFGh9OH13RasoMXXfA")
MODEL_NAME = "qwen2.5"

SYSTEM_PROMPT = """You are a helpful and knowledgeable AI assistant for a medical application. 
You are designed to help users understand their symptoms or skin conditions.
However, you MUST always include a disclaimer that you are not a doctor.
Provide clear, concise information and suggest basic next steps (like whether they should see a doctor urgently or if home care might be sufficient), but never provide a definitive diagnosis.
Respond empathically and professionally."""

async def generate_chat_response(prompt: str) -> str:
    """
    Generates a response for a text-based symptom description using Flextoken API.
    """
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {API_KEY}"
    }
    
    data = {
        "model": MODEL_NAME,
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": prompt}
        ],
        "max_tokens": 4096,
        "temperature": 0.1,
        "top_p": 0.9
    }

    try:
        response = requests.post(API_URL, headers=headers, json=data)
        response.raise_for_status() # Raise an exception for bad status codes
        
        response_json = response.json()
        if "choices" in response_json and len(response_json["choices"]) > 0:
             return response_json["choices"][0]["message"]["content"]
        else:
             print(f"Unexpected API response format: {response_json}")
             return "I'm sorry, I received an unexpected response from the AI service."
             
    except Exception as e:
        print(f"Error generating chat response: {e}")
        return f"I'm sorry, I encountered an error while communicating with the AI service: {e}"


async def analyze_image(image_bytes: bytes, mime_type: str, user_description: str = "") -> str:
    """
    Generates a response based on an image and optional text description.
    Note: qwen2.5 is primarily a text model, but we will send it in standard OpenAI vision format
    in case the endpoint routing handles it or a vision model is swapped in later.
    """
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {API_KEY}"
    }
    
    base64_image = base64.b64encode(image_bytes).decode('utf-8')
    image_url = f"data:{mime_type};base64,{base64_image}"
    
    prompt_text = "The user has uploaded an image"
    if user_description:
        prompt_text += f" and provided this description: '{user_description}'."
    prompt_text += "\nPlease analyze the image and provide possible insights or general advice. Remember the disclaimer."

    data = {
        "model": MODEL_NAME,
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": prompt_text},
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": image_url
                        }
                    }
                ]
            }
        ],
        "max_tokens": 4096,
        "temperature": 0.1,
        "top_p": 0.9
    }

    try:
        response = requests.post(API_URL, headers=headers, json=data)
        
        # If the model doesn't support vision, it usually throws a 400. Let's catch it gracefully.
        if response.status_code == 400:
             print(f"Vision API Error: {response.text}")
             return "I'm sorry, the current AI model (qwen2.5) does not support image analysis. Please describe your symptoms in text."
             
        response.raise_for_status()
        
        response_json = response.json()
        if "choices" in response_json and len(response_json["choices"]) > 0:
             return response_json["choices"][0]["message"]["content"]
        else:
             print(f"Unexpected API response format: {response_json}")
             return "I'm sorry, I received an unexpected response from the AI service."
             
    except Exception as e:
        print(f"Error analyzing image: {e}")
        return f"I'm sorry, I encountered an error while analyzing the image: {e}"
