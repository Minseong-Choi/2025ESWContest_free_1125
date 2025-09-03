from openai import OpenAI
import os
import base64

client = OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))

def encode_image(image_path):
    with open(image_path, "rb") as image_file:
        return base64.b64encode(image_file.read()).decode("utf-8")
def generate_questions_from_image(image_path):
    base64_image = encode_image(image_path)
    response = client.responses.create(
        model="gpt-4.1-mini",
        input=[
            {
                "role": "system",
                "content": "당신은 노인분들의 기억력과 인지 기능을 자극하는 대화 도우미입니다. 사진을 보고 구체적인 기억을 떠올릴 수 있도록 질문을 만드세요. 질문은 따뜻하고 존중하는 말투를 사용하세요."
            },
            {
                "role": "user",
                "content": [
                    {"type": "input_text", "text": "이 사진을 보고 기억을 떠올릴 수 있는 질문 3개를 만들어주세요. 단순히 기분을 묻기보다는, 사람, 장소, 계절, 활동 같은 구체적인 맥락을 자극하세요."},
                    {"type": "input_image", "image_url": f"data:image/jpeg;base64,{base64_image}"}
                ]
            }
        ],
    )

    text = response.output_text
    # 텍스트를 3개 질문 리스트로 변환
    questions = [q.strip() for q in text.split("\n") if q.strip()]
    return questions[:3]