import cv2
import numpy as np
import os

def visualize_and_save_contours(image_path, output_dir, simplification_ratio=0.0001):
    os.makedirs(output_dir, exist_ok=True)

    base_name = os.path.splitext(os.path.basename(image_path))[0]

    # 이미지 읽기 및 이진화
    image = cv2.imread(image_path)
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    _, binary = cv2.threshold(gray, 127, 255, cv2.THRESH_BINARY_INV | cv2.THRESH_OTSU)

    # 윤곽선 찾기 및 단순화
    contours, _ = cv2.findContours(binary, cv2.RETR_LIST, cv2.CHAIN_APPROX_SIMPLE)
    simplified = []
    for c in contours:
        peri = cv2.arcLength(c, True)
        epsilon = simplification_ratio * peri
        approx = cv2.approxPolyDP(c, epsilon, True)
        simplified.append(approx)

    # 이미지 높이, 너비
    h, w = image.shape[:2]

    # === 드로잉 영역만 찾기 ===
    ys, xs = np.where(binary == 0)  # 검은색 픽셀 위치
    if len(xs) == 0 or len(ys) == 0:
        print("드로잉 영역이 없습니다.")
        return

    x_min, x_max = xs.min(), xs.max()
    y_min, y_max = ys.min(), ys.max()
    drawing_w = x_max - x_min
    drawing_h = y_max - y_min

    # === 드로잉봇 최대 영역 설정 및 스케일 계산 ===
    MAX_X, MAX_Y = 400, 1100
    scale = min(MAX_X / drawing_w, MAX_Y / drawing_h)
    pad_x = (MAX_X - drawing_w * scale) / 2
    pad_y = (MAX_Y - drawing_h * scale) / 2

    # 좌표 변환 함수
    def to_robot_coords(x, y):
        rx = int((x - x_min) * scale + pad_x)
        ry = int(MAX_Y - ((y - y_min) * scale + pad_y))  # y=0 아래쪽 기준
        return rx, ry

    # === 실제 드로잉 영역 기준 3등분 ===
    h_step = drawing_h / 3
    areas = [
        (y_min + 2*h_step, y_max),   # part1: 맨 아래
        (y_min, y_min + h_step),     # part2: 맨 위
        (y_min + h_step, y_min + 2*h_step) # part3: 중간
    ]

    for idx_area, (y_start, y_end) in enumerate(areas):
        canvas = np.ones_like(image) * 255
        filename = os.path.join(output_dir, f"{base_name}_part{idx_area+1}.txt")
        total_points = 0
        contour_idx = 0

        with open(filename, "w") as f:
            for c in simplified:
                coords = c[:, 0, :]
                segment = []

                for x, y in coords:
                    if y_start <= y < y_end:
                        segment.append(to_robot_coords(x, y))
                    else:
                        if len(segment) > 0:
                            for i in range(len(segment)-1):
                                cv2.line(canvas, segment[i], segment[i+1], (0,0,0), 2)
                            f.write(f"# contour {contour_idx}\n")
                            for sx, sy in segment:
                                f.write(f"{sx},{sy}\n")
                            total_points += len(segment)
                            contour_idx += 1
                        segment = []

                if len(segment) > 0:
                    for i in range(len(segment)-1):
                        cv2.line(canvas, segment[i], segment[i+1], (0,0,0), 2)
                    f.write(f"# contour {contour_idx}\n")
                    for sx, sy in segment:
                        f.write(f"{sx},{sy}\n")
                    total_points += len(segment)
                    contour_idx += 1

        print(f"Saved {filename} | Total points: {total_points}")
        cv2.imshow(f"Area Split Part {idx_area+1}", canvas)

    cv2.waitKey(0)
    cv2.destroyAllWindows()


# 사용 예시
image_path = "static/images/animals/cat_drawing.jpg"
output_dir = "drawing_bot/contour_txt/animals"
visualize_and_save_contours(image_path, output_dir=output_dir)