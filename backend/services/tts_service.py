from openai import OpenAI
import os

client = OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))

def generate_tts(text, save_path="output.mp3"):
    """
    GPT TTS 모델을 사용해 음성 파일 생성
    """
    response = client.audio.speech.create(
        model="gpt-4o-mini-tts",
        voice="alloy",    # 원하는 목소리
        input=text
    )
    with open(save_path, "wb") as f:
        f.write(response.audio)