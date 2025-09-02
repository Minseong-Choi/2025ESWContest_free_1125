from openai import OpenAI
import os

client = OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))
def generate_questions_from_image(image_url):
    response = client.responses.create(
        model="gpt-4.1-mini",
        input=[{
            "role": "user",
            "content": [
                {"type": "input_text", "text": "이 이미지를 보고 사진과 관련된 추억을 회상할 수 있을 만한 3개의 질문을 만들어주세요"},
                {"type": "input_image", "image_url": image_url},
            ],
        }],
    )

    text = response.output_text
    # 텍스트를 3개 질문 리스트로 변환
    questions = [q.strip() for q in text.split("\n") if q.strip()]
    return questions[:3]