from google import genai
import os
from dotenv import load_dotenv

load_dotenv()
try:
    client = genai.Client(api_key=os.getenv("GOOGLE_API_KEY"))
    for m in client.models.list():
        print(m.name)
except Exception as e:
    print(f"Error: {e}")
