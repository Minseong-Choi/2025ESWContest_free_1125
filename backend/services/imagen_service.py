import os
import requests

GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")
IMAGEN_MODEL = "imagen-4.0-generate-001"
API_URL = f"https://generativelanguage.googleapis.com/v1beta/models/{IMAGEN_MODEL}:generateImages?key={GEMINI_API_KEY}"
def generate_image(prompt: str) -> str:
    body = {
        "prompt": prompt,
        "parameters": {
            "resolution": "1024x1024"
        }
    }

    response = requests.post(API_URL, json=body)
    response.raise_for_status()

    resp_json = response.json()
    return resp_json["predictions"][0]["imageUri"]