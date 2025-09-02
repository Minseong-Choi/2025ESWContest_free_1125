# imagen_service.py
import base64
import os
from openai import OpenAI
from PIL import Image
from io import BytesIO

client = OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))

# 이미지 생성 함수
def generate_image(prompt: str, save_path: str = "static/generated/img1.png") -> str:
    os.makedirs(os.path.dirname(save_path), exist_ok=True)

    result = client.images.generate(
        model="gpt-image-1",
        prompt=prompt,
        quality="low",
        size="1024x1024"
    )

    # Base64 → 이미지 변환
    image_base64 = result.data[0].b64_json
    image_bytes = base64.b64decode(image_base64)
    image = Image.open(BytesIO(image_bytes))

    # PNG로 저장
    image.save(save_path, format="PNG", optimize=True)
    return save_path