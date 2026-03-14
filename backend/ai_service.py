from google import genai
import os
from dotenv import load_dotenv

load_dotenv()

# We will use Gemini 1.5 Flash for both text and vision for now
# As it provides a good balance of speed and capability for medical reasoning
# User needs to set GOOGLE_API_KEY in .env
api_key = os.getenv("GOOGLE_API_KEY")

if api_key:
    client = genai.Client(api_key=api_key)
else:
    client = None

SYSTEM_PROMPT = """You are a helpful and knowledgeable AI assistant for a medical application. 
You are designed to help users understand their symptoms or skin conditions.
However, you MUST always include a disclaimer that you are not a doctor.
Provide clear, concise information and suggest basic next steps (like whether they should see a doctor urgently or if home care might be sufficient), but never provide a definitive diagnosis.
Respond empathically and professionally."""

async def generate_chat_response(prompt: str) -> str:
    """
    Generates a response for a text-based symptom description.
    """
    if not client:
         return "Error: GOOGLE_API_KEY is not set in the backend environment."
         
    try:
        full_prompt = f"{SYSTEM_PROMPT}\n\nUser Question/Symptom: {prompt}\n\nResponse:"
        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=full_prompt,
        )
        return response.text
    except Exception as e:
        print(f"Error generating chat response: {e}")
        if '429' in str(e):
            return "Error: Your Google AI API key quota has been exceeded or the free tier is unavailable in your region."
        return "I'm sorry, I encountered an error while processing your request. Please try again later."


async def analyze_image(image_bytes: bytes, mime_type: str, user_description: str = "") -> str:
    """
    Generates a response based on an image and optional text description.
    """
    if not client:
         return "Error: GOOGLE_API_KEY is not set in the backend environment."
         
    try:
        prompt_text = f"{SYSTEM_PROMPT}\n\nThe user has uploaded an image"
        if user_description:
            prompt_text += f" and provided this description: '{user_description}'."
        prompt_text += "\nPlease analyze the image and provide possible insights or general advice. Remember the disclaimer."

        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=[prompt_text, {"mime_type": mime_type, "data": image_bytes}],
        )
        return response.text
    except Exception as e:
        print(f"Error analyzing image: {e}")
        if '429' in str(e):
            return "Error: Your Google AI API key quota has been exceeded or the free tier is unavailable in your region."
        return "I'm sorry, I encountered an error while analyzing the image. Please ensure it is a valid image format."
