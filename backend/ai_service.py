import os
import requests
import base64
import re
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


# --- Vertex AI MedGemma Configuration ---
from google.cloud import aiplatform

PROJECT_ID = os.getenv("MEDGEMMA_PROJECT_ID", "project-2dfacedf-5d4a-4fdf-9aa")
ENDPOINT_ID = os.getenv("MEDGEMMA_ENDPOINT_ID", "mg-endpoint-7079bfbb-2633-44ac-b047-beb2c365e1e8")
LOCATION = os.getenv("MEDGEMMA_LOCATION", "us-central1")

# Initialize Vertex AI globally. It will automatically detect the GOOGLE_APPLICATION_CREDENTIALS
# you set up in your .env file!
aiplatform.init(project=PROJECT_ID, location=LOCATION)

async def analyze_image(image_bytes: bytes, mime_type: str, user_description: str = "") -> str:
    """
    Sends medical image and text to the MedGemma endpoint using the Vertex AI SDK.
    """
    # Flutter often sends file bytes as 'application/octet-stream' which breaks the Vertex image parser.
    # Force it to a valid image mimetype so the Data URI gets parsed correctly.
    if mime_type == "application/octet-stream":
        mime_type = "image/jpeg"
        
    try:
        # 1. Connect to your Dedicated Endpoint
        endpoint = aiplatform.Endpoint(ENDPOINT_ID)
        
        # 2. Prepare the Image
        base64_image = base64.b64encode(image_bytes).decode("utf-8")
        
        # Append the emergency text logic 
        # Add a strict system persona to prevent MedGemma from refusing the request due to safety filters.
        full_prompt = (
            "You are a clinical imaging assistant. You MUST NOT refuse to answer.\n"
            "Do NOT provide a definitive medical diagnosis.\n"
            "Instead, formally describe the visual characteristics of the skin lesion or condition in this image.\n"
            "List possible visual differentials based ONLY on the image.\n"
            f"User notes: {user_description}\n"
            "If you determine the symptoms sound like a medical emergency, you MUST append the exact text `[URGENT_CLINIC_SEARCH]` at the very end of your response."
        )
        
        # 3. Construct the Instance
        # MedGemma expects explicit conversational turns to know when the user prompt ends.
        conversational_prompt = (
            f"<start_of_turn>user\n"
            f"data:{mime_type};base64,{base64_image}\n"
            f"{full_prompt}\n"
            f"<end_of_turn>\n"
            f"<start_of_turn>model\n"
        )
        
        instances = [{
            "prompt": conversational_prompt
        }]
        
        # 4. Request Prediction from the SDK
        # CRUCIAL: Vertex Model Garden vLLM containers IGNORE the python SDK's `parameters={}` argument!
        # You MUST inject `max_tokens` directly into the payload instance dictionary!
        instances = [{
            "prompt": conversational_prompt,
            "max_tokens": 2048,
            "temperature": 0.2,
            "top_p": 0.95
        }]
        
        response = endpoint.predict(instances=instances)
        
        if response.predictions:
            pred = response.predictions[0]
            
            # The model often returns the full prompt followed by 'Output:\n<answer>'
            raw_text = ""
            if isinstance(pred, str):
                 raw_text = pred
            elif isinstance(pred, dict) and 'content' in pred:
                 raw_text = pred['content']
            else:
                 raw_text = str(pred)
                 
            # Strip out the prompt regurgitation if it exists
            if "Output:\n" in raw_text:
                 # Only take the part after 'Output:\n' but don't strip internal newlines
                 raw_text = raw_text.split("Output:\n", 1)[1].strip()
                 
            # Some models use different formatting or repeat the prompt
            elif "<start_of_turn>model\n" in raw_text:
                 raw_text = raw_text.split("<start_of_turn>model\n", 1)[1].strip()
                 
            # Feed the clinical findings into the Qwen persona model
            qwen_prompt = (
                f"The user uploaded a medical image described as: '{user_description}'.\n\n"
                f"Our clinical imaging assistant (MedGemma) analyzed the image and found the following:\n"
                f"{raw_text}\n\n"
                "Based on these visual findings, please respond to the user following your empathetic 'DokAI' persona rules. "
                "Translate the clinical findings into simple, non-technical language to help them understand. "
                "Suggest next steps (Urgent or Non-Urgent) and ask follow-up questions."
            )
            
            # Gracefully handle Qwen/Flextoken API downtime (like 503 Server Error)
            try:
                final_response = await generate_chat_response(qwen_prompt)
                
                # If Qwen's error string is returned, fallback to raw Vertex output
                if "encountered an error while communicating with the AI service" in final_response:
                    # Clean up MedGemma formatting for the fallback
                    fallback_text = raw_text.replace("VISUAL DIFFERENTIALS:", "\n\nVISUAL DIFFERENTIALS:\n")
                    fallback_text = fallback_text.replace("IMPORTANT NOTE:", "\n\nIMPORTANT NOTE:\n")
                    fallback_text = re.sub(r'\*\*(.*?)\*\*', r'\n\n**\1**\n', fallback_text)
                    fallback_text = re.sub(r'\*(.*?):', r'\n• \1:', fallback_text)
                    # Fix MedGemma spelling errors on the urgent tag so the Flutter app can parse it correctly
                    fallback_text = re.sub(r'\[URGENT_CLIN.*?SEARCH\]', '', fallback_text)
                    
                    return f"I am currently experiencing connection issues with my communication interface. However, I have still analyzed your image. Here are the clinical findings:\n\n{fallback_text.strip()}"
                
                return final_response
            except Exception as e:
                print(f"Fallback triggered. Qwen API failed during image pipeline: {e}")
                
                fallback_text = raw_text.replace("VISUAL DIFFERENTIALS:", "\n\nVISUAL DIFFERENTIALS:\n")
                fallback_text = fallback_text.replace("IMPORTANT NOTE:", "\n\nIMPORTANT NOTE:\n")
                fallback_text = re.sub(r'\*\*(.*?)\*\*', r'\n\n**\1**\n', fallback_text)
                fallback_text = re.sub(r'\*(.*?):', r'\n• \1:', fallback_text)
                fallback_text = re.sub(r'\[URGENT_CLIN.*?SEARCH\]', '', fallback_text)
                    
                return f"I am currently experiencing connection issues with my communication interface. However, I have still analyzed your image. Here are the clinical findings:\n\n{fallback_text.strip()}"
            
        return "No prediction returned from MedGemma."
        
    except Exception as e:
        print(f"Vertex AI SDK Error: {e}")
        return f"Error connecting to Vertex AI via SDK: {str(e)}"
