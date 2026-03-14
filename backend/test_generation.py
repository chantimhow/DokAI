from google import genai
import os
from dotenv import load_dotenv

load_dotenv()
client = genai.Client(api_key=os.getenv("GOOGLE_API_KEY"))

models_to_test = [
    "gemini-2.0-flash", 
    "gemini-2.5-flash",
    "gemini-1.5-flash", 
    "gemini-flash-latest",
    "gemma-2-9b-it",
    "gemma-3-1b-it"
]

for model_id in models_to_test:
    try:
        response = client.models.generate_content(
            model=model_id,
            contents="say hi"
        )
        print(f"SUCCESS with {model_id}: {response.text.strip()}")
    except Exception as e:
        print(f"FAILED with {model_id}: {e}")
