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

SYSTEM_PROMPT = """You are 'DokAI', a compassionate and professional medical assistant specifically designed to help rural 'kampung' communities. Your goal is to provide early health guidance and bridge the gap between home care and professional medical services.

### OPERATIONAL RULES:
1. MEDICAL DISCLAIMER: You MUST start every response with:  I am an AI assistant, not a doctor. This info is not an official diagnosis
2. TONE: Respond with high empathy, patience, and professional warmth. Use simple, non-technical language that is easy for a non-expert to understand.
3. LANGUAGE: You are bilingual. Respond in the same language the user uses , English or Malay
4. NO DEFINITIVE DIAGNOSIS: Never say "You have [Disease]." Instead, use These symptoms might be related to
5. IMAGE HANDLING: Since you are a text model, if the user mentions an image or if you receive an 'auto-caption', acknowledge it  and ask clarifying questions about texture, itchiness, or duration.

### RESPONSE STRUCTURE:
1. Acknowledge the user's concern empathically.
2. Provide 2-3 common possibilities for the symptoms described.
3. Suggest (Next Steps):
   - Urgent: If symptoms sound like an emergency (e.g., chest pain, severe bleeding), tell them to go to the nearest clinic immediately.
   - Non-Urgent: Suggest home monitoring or basic first aid.
4. Ask 1-2 follow-up questions to help the user reflect on their condition.

Always encourage preventative care and visiting a local professional when in doubt.

### CRITICAL INSTRUCTION FOR EMERGENCIES:
If you determine the user's symptoms sound like a medical emergency (Urgent), you MUST append the exact text `[URGENT_CLINIC_SEARCH]` at the very end of your response. This hidden tag will trigger the app's GPS locator to find nearby hospitals automatically."""

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
        "max_completion_tokens": 4096,
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


from google.cloud import aiplatform

# Replace these with your actual values
PROJECT_ID = "project-2dfacedf-5d4a-4fdf-9aa"
LOCATION = "us-central1"  
ENDPOINT_ID = "mg-endpoint-7079bfbb-2633-44ac-b047-beb2c365e1e8"

# Initialize Vertex AI
aiplatform.init(project=PROJECT_ID, location=LOCATION)

async def analyze_image(image_bytes: bytes, mime_type: str, user_description: str = "") -> str:
    """
    Sends medical image and text to the MedGemma endpoint on Vertex AI.
    """
    # 1. Initialize the Endpoint
    endpoint = aiplatform.Endpoint(ENDPOINT_ID)
    
    # 2. Prepare the Image (Base64 encoded for JSON payload)
    base64_image = base64.b64encode(image_bytes).decode("utf-8")
    
    prompt_text = f"Analyze this medical image: {user_description}"
    prompt_text += " If you determine the symptoms sound like a medical emergency, you MUST append the exact text `[URGENT_CLINIC_SEARCH]` at the very end of your response."
    
    # 3. Construct the Instance (MedGemma 1.5 format)
    # Instances are sent as a list of dicts
    instances = [{
        "prompt": prompt_text,
        "image": {"bytesBase64": base64_image}
    }]
    
    try:
        # 4. Request Prediction
        response = endpoint.predict(instances=instances)
        
        # MedGemma typically returns a list of predictions
        if response.predictions:
            return response.predictions[0]
        return "No prediction returned from MedGemma."
        
    except Exception as e:
        print(f"Vertex AI Prediction Error: {e}")
        return f"Error connecting to Vertex AI: {str(e)}"
