import requests
import os
from dotenv import load_dotenv

load_dotenv()
API_URL = "https://aiworkshopapi.flexinfra.com.my/v1/chat/completions"
API_KEY = os.getenv("FLEXTOKEN_API_KEY", "sk-lByvUFGh9OH13RasoMXXfA")
headers = {"Content-Type": "application/json", "Authorization": f"Bearer {API_KEY}"}

data = {
    "model": "qwen2.5",
    "messages": [{"role": "user", "content": "I have a sharp pain in my stomach. Explain what it could be in detail. Use a lot of text so I can verify."}],
    "max_new_tokens": 1024
}

r = requests.post(API_URL, headers=headers, json=data)
print("max_new_tokens test:", r.json())
