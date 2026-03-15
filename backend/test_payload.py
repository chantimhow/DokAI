import os
import base64
from google.cloud import aiplatform

PROJECT_ID = "project-2dfacedf-5d4a-4fdf-9aa"
LOCATION = "us-central1"  
ENDPOINT_ID = "mg-endpoint-7079bfbb-2633-44ac-b047-beb2c365e1e8"

aiplatform.init(project=PROJECT_ID, location=LOCATION)
endpoint = aiplatform.Endpoint(ENDPOINT_ID)

img_bytes = base64.b64decode("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=")
base64_image = base64.b64encode(img_bytes).decode("utf-8")

payloads = [
    {
        "prompt": "Analyze this medical image: <image>",
        "image": {"bytesBase64": base64_image}
    },
    {
        "prompt": "Analyze this medical image: <image>",
        "image": base64_image
    },
    {
        "prompt": "Analyze this medical image: <image>\n<image>",
        "images": [{"bytesBase64": base64_image}]
    },
    {
        "messages": [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": "Analyze this medical image:"},
                    {"type": "image_url", "image_url": {"url": f"data:image/png;base64,{base64_image}"}}
                ]
            }
        ]
    }
]

for p in payloads:
    print(f"\\nTrying payload format: {list(p.keys())}")
    try:
        response = endpoint.predict(instances=[p])
        print("Success!", response.predictions)
    except Exception as e:
        print("Failed:", str(e)[:300]) # Trucate long error messages
