from flask import Flask, jsonify, send_from_directory, request
from flask_cors import CORS
from services.imagen_service import generate_image
from services.contour_service import process_contours_and_split3
from services.json_service import contours_txt_to_json
from services.image_question_service import generate_questions_from_image
from services.tts_service import generate_tts
import os, random,subprocess, re
import subprocess

app = Flask(__name__)
CORS(app)

# 이미지가 들어있는 폴더 경로
IMAGE_FOLDER = os.path.join(app.root_path, "static/images")
JSON_FOLDER = os.path.join(app.root_path, "drawing_bot/contour_json")

# 파일명 → 한글 이름 매핑
NAME_MAP = {
    "apple": "사과",
    "grape": "포도",
    "banana": "바나나",
    "strawberry": "딸기",
    "watermelon" : "수박",
    "pear" : "배",
    "cosmos":"코스모스",
    "jangmi" : "장미",
    "haebalagi" : "해바라기",
    "gookhwa" : "국화",
    "baekhap" :"백합",
    "tulip" : "튤립",
    "jindallae" :"진달래",
    "bicycle" : "자전거",
    "airplane" : "비행기",
    "bus" : "버스",
    "motorcycle" : "오토바이",
    "train" : "기차",
    "yulgigoo" : "열기구",
    "ship" : "배",
    "bag" : "가방",
    "clock" : "시계",
    "cup" : "컵",
    "glass" : "안경",
    "hat" : "모자",
    "shoes" : "신발",
    "umbrella" : "우산",
    "cat_drawing" : "고양이",
    "dog_drawing" : "강아지",
    "fox_drawing" : "여우",
    "giraffe_drawing" : "기린",
    "hippo_drawing" : "하마",
    "owl_drawing" : "부엉이",
    "penguin" : "펭귄",
    "1_drawing" : "송학(솔)",
    "2_drawing" : "매조",
    "3_drawing" : "벚꽃(사쿠라)",
    "4_draiwng" :"등나무(흑싸리)",
    "5_drawing" : "제비붓꽃(난초)",
    "6_drawing" : "모란(목단)",
    "7_drawing" : "싸리",
    "8_drawing" : "억새",
    "9_drawing" : "국화",
    "10_drawing" : "단풍",
    "11_drawing" : "오동",
    "12_drawing" : "버드나무"
}

CATEGORY_MAP = {
    "동물": "animals",
    "과일": "fruits",
    "탈것": "vehicles",
    "꽃": "flowers",
    "화투" : "hwatu",
    "사물" : "objects"
}

@app.route("/api/random/<category>")
def random_image(category):
    folder_name = CATEGORY_MAP.get(category)
    if not folder_name:
        return jsonify({"error": "Category not found"}), 404

    category_path = os.path.join(IMAGE_FOLDER, folder_name)
    images = [img for img in os.listdir(category_path) if img.lower().endswith((".png", ".jpg", ".jpeg"))]
    if not images:
        return jsonify({"error": "No images in this category"}), 404

    image_file = random.choice(images)
    correct_name = NAME_MAP.get(os.path.splitext(image_file)[0], os.path.splitext(image_file)[0])

    wrong_names = [
        NAME_MAP.get(os.path.splitext(img)[0], os.path.splitext(img)[0])
        for img in images if img != image_file
    ]
    wrong_sample = random.sample(wrong_names, min(3, len(wrong_names)))

    return jsonify({
        "name": correct_name,
        "imageUrl": f"/static/images/{folder_name}/{image_file}",
        "part1JsonUrl": f"/drawing_bot/contour_json/{folder_name}/{image_file}_part1.json",
        "part2JsonUrl": f"/drawing_bot/contour_json/{folder_name}/{image_file}_part2.json",
        "part3JsonUrl": f"/drawing_bot/contour_json/{folder_name}/{image_file}_part3.json",
        "wrongAnswers": wrong_sample
    })

# EV3 전송용 엔드포인트
@app.route("/api/draw/<category>/<image_name>", methods=["POST"])
def draw_on_ev3(category, image_name):
    folder_name = CATEGORY_MAP.get(category)
    if not folder_name:
        return jsonify({"error": "Category not found"}), 404

    json_dir = os.path.join(JSON_FOLDER, folder_name)
    json_file = os.path.join(json_dir, f"{os.path.splitext(image_name)[0]}.json")

    if not os.path.exists(json_file):
        return jsonify({"error": "JSON file not found"}), 404

    try:
        # control_ev3.py 실행 (경로 조정 필요)
        subprocess.run(
            ["python3", "control_ev3.py", json_file],
            check=True
        )
        return jsonify({"status": "success", "file": os.path.basename(json_file)})
    except subprocess.CalledProcessError as e:
        return jsonify({"error": str(e)}), 500

def safe_filename(text: str) -> str:
    return re.sub(r'[^a-zA-Z0-9_-]', '_', text)
@app.route("/api/request", methods=["POST"])
def handle_request():
    data = request.get_json()
    user_text = data.get("text", "").strip()
    prompt = f"Digital sketch of {user_text} with cartoon style, flat colors, playful and whimsical, white background"

    if not prompt:
        return jsonify({"error": "Empty prompt"}), 400

    try:
        safe_prompt = safe_filename(prompt)

        # 1️⃣ 이미지 생성
        image_path = f"static/generated/{safe_prompt}.png"
        image_url = generate_image(prompt, save_path=image_path)

        # 2️⃣ 이미지 → 컨투어
        output_dir = f"drawing_bot/contour_txt/{safe_prompt}"
        process_contours_and_split3(image_path, output_dir)

        txt_files = [
            os.path.join(output_dir, f) for f in os.listdir(output_dir) if f.endswith(".txt")
        ]

        # 3️⃣ txt → json 변환
        json_file = f"drawing_bot/json/{safe_prompt}.json"
        os.makedirs("drawing_bot/json", exist_ok=True)
        contours_txt_to_json(txt_files, json_file)

        # 4️⃣ EV3 실행
        subprocess.run(
            ["python3", "control_ev3.py", json_file],
            check=True
        )

        return jsonify({
            "status": "success",
            "prompt": prompt,
            "message" : "그림이 완성되었습니다!",
            "imageUrl": image_url,
            "jsonFile": os.path.basename(json_file)
        })

    except subprocess.CalledProcessError as e:
        return jsonify({"error": f"EV3 실행 실패: {str(e)}"}), 500
    except Exception as e:
        return jsonify({"error": f"처리 실패: {str(e)}"}), 500

UPLOAD_FOLDER = "static/uploads"
AUDIO_FOLDER = "static/audio"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(AUDIO_FOLDER, exist_ok=True)

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['AUDIO_FOLDER'] = AUDIO_FOLDER

# 업로드된 파일 접근 라우트
@app.route('/static/uploads/<filename>')
def uploaded_file(filename):
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

# 이미지 업로드 API
@app.route("/api/upload", methods=["POST"])
def upload_image():
    if "file" not in request.files:
        return jsonify({"error": "No file part"}), 400

    file = request.files["file"]
    if file.filename == "":
        return jsonify({"error": "No selected file"}), 400

    # 1️⃣ 이미지 저장
    save_path = os.path.join(app.config['UPLOAD_FOLDER'], file.filename)
    file.save(save_path)

    # 3️⃣ OpenAI로 질문 생성
    questions = generate_questions_from_image(save_path)

    return jsonify({
        "questions": questions
    })

    # 4️⃣ TTS 생성
    #audio_paths = []
    #for i, q in enumerate(questions):
        #audio_file = os.path.join(app.config['AUDIO_FOLDER'], f"{file.filename}_q{i}.mp3")
        #generate_tts(q, save_path=audio_file)
        #audio_paths.append(audio_file)

    #return jsonify({
        #"questions": questions,
        #"audioFiles": audio_paths
    #})

# 정적 파일 제공
@app.route("/static/images/<path:filename>")
def serve_image(filename):
    return send_from_directory(IMAGE_FOLDER, filename)

if __name__ == "__main__":
    import sys
    import logging
    logging.basicConfig(stream=sys.stdout, level=logging.DEBUG)
    app.run(host="0.0.0.0", port=5001, debug=True, use_reloader=False)