import requests
import os
from dotenv import load_dotenv

load_dotenv()

# Assuming flextoken provides an OpenAI-compatible endpoint
api_key = os.getenv("GOOGLE_API_KEY") # User might have put the flextoken here
url = "https://api.openai.com/v1/chat/completions" # Need to ask user for the flextoken URL

headers = {
    "Authorization": f"Bearer {api_key}",
    "Content-Type": "application/json"
}

data = {
    "model": "gpt-3.5-turbo", # Just guessing a generic model for now
    "messages": [{"role": "user", "content": "say hi"}]
}

try:
    response = requests.post(url, headers=headers, json=data)
    print(response.status_code)
    print(response.json())
except Exception as e:
    print(e)
