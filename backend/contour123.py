import cv2
import numpy as np
import os

def visualize_and_save_contours(image_path, output_dir, simplification_ratio=0.0001):
    os.makedirs(output_dir, exist_ok=True)

    base_name = os.path.splitext(os.path.basename(image_path))[0]

    # 이미지 읽기 및 이진화
    image = cv2.imread(image_path)
    if image is None:
        print(f"Error: unable to load {image_path}")
        return

    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    _, binary = cv2.threshold(gray, 127, 255, cv2.THRESH_BINARY_INV | cv2.THRESH_OTSU)

    # 윤곽선 찾기 및 단순화
    contours, _ = cv2.findContours(binary, cv2.RETR_LIST, cv2.CHAIN_APPROX_SIMPLE)
    simplified = []
    for c in contours:
        peri = cv2.arcLength(c, True)
        epsilon = simplification_ratio * peri
        approx = cv2.approxPolyDP(c, epsilon, True)
        if approx is not None and approx.shape[0] > 0:
            simplified.append(approx)

    # === 원본 드로잉 영역(BGR에서 검은색=0) ===
    ys, xs = np.where(binary == 0)
    if len(xs) == 0 or len(ys) == 0:
        print("드로잉 영역이 없습니다.")
        return

    x_min, x_max = xs.min(), xs.max()
    y_min, y_max = ys.min(), ys.max()
    drawing_w = max(1, x_max - x_min)
    drawing_h = max(1, y_max - y_min)

    # === 드로잉봇 최대 영역 & 전역 스케일 ===
    MAX_X, MAX_Y = 400, 1100
    scale = min(MAX_X / drawing_w, MAX_Y / drawing_h)
    pad_x = (MAX_X - drawing_w * scale) / 2.0
    pad_y = (MAX_Y - drawing_h * scale) / 2.0

    # 좌표 변환(전체 기준 스케일/패딩, y축 뒤집기)
    def to_robot_coords(x, y):
        rx = (x - x_min) * scale + pad_x
        ry = MAX_Y - ((y - y_min) * scale + pad_y)  # 위가 +가 되도록 반전
        return rx, ry

    # === 실제 드로잉 영역 기준 3등분 ===
    h_step = drawing_h / 3.0
    # part1=아래, part2=위, part3=중간 (기존 순서 유지)
    areas = [
        (y_min + 2 * h_step, y_max),           # part1: 맨 아래
        (y_min, y_min + h_step),               # part2: 맨 위
        (y_min + h_step, y_min + 2 * h_step)   # part3: 중간
    ]

    for idx_area, (y_start, y_end) in enumerate(areas, start=1):
        canvas = np.ones_like(image) * 255

        # 1) 각 파트에 속하는 폴리라인 분절 수집 (원본 좌표에서 y범위로 자름)
        polylines = []   # 각 단편 polyline ([(x,y), ...])의 리스트
        for c in simplified:
            coords = c[:, 0, :]  # (N,2)
            segment = []
            for x, y in coords:
                if y_start <= y < y_end:
                    segment.append((x, y))
                else:
                    if len(segment) > 0:
                        polylines.append(segment)
                        segment = []
            if len(segment) > 0:
                polylines.append(segment)

        if len(polylines) == 0:
            print(f"Part {idx_area}: 포함된 점이 없어 건너뜀.")
            cv2.imshow(f"Area Split Part {idx_area}", canvas)
            continue

        # 2) 로봇 좌표로 변환
        polylines_robot = []
        for seg in polylines:
            pr = [to_robot_coords(x, y) for (x, y) in seg]
            polylines_robot.append(pr)

        # 3) 파트의 바운딩박스 계산 (로봇 좌표계)
        all_x = [p[0] for seg in polylines_robot for p in seg]
        all_y = [p[1] for seg in polylines_robot for p in seg]
        part_min_x, part_max_x = min(all_x), max(all_x)
        part_min_y, part_max_y = min(all_y), max(all_y)
        part_w = max(0.0, part_max_x - part_min_x)
        part_h = max(0.0, part_max_y - part_min_y)

        # 4) 남은 영역 계산 및 여백의 1/2만큼 이동 (x/y 각각)
        remaining_x = max(0.0, MAX_X - part_w)
        remaining_y = max(0.0, MAX_Y - part_h)
        # min을 remaining/2로 맞추는 평행이동량
        shift_x = (remaining_x / 2.0) - part_min_x
        shift_y = (remaining_y / 2.0) - part_min_y

        def apply_shift_and_clip(pt):
            x, y = pt
            x = int(round(x + shift_x))
            y = int(round(y + shift_y))
            x = int(np.clip(x, 0, MAX_X))
            y = int(np.clip(y, 0, MAX_Y))
            return (x, y)

        polylines_centered = [[apply_shift_and_clip(p) for p in seg] for seg in polylines_robot]

        # 5) 파일 저장 + 캔버스 그리기
        filename = os.path.join(output_dir, f"{base_name}_part{idx_area}.txt")
        total_points = 0
        contour_idx = 0
        with open(filename, "w") as f:
            for seg in polylines_centered:
                if len(seg) < 2:
                    # 점 1개뿐이면 라인 그릴 수 없지만, 좌표는 저장할 수 있음
                    f.write(f"# contour {contour_idx}\n")
                    for sx, sy in seg:
                        f.write(f"{sx},{sy}\n")
                    total_points += len(seg)
                    contour_idx += 1
                    continue

                # 시각화(선연결) 및 저장
                for i in range(len(seg) - 1):
                    cv2.line(canvas, seg[i], seg[i + 1], (0, 0, 0), 2)

                f.write(f"# contour {contour_idx}\n")
                for sx, sy in seg:
                    f.write(f"{sx},{sy}\n")
                total_points += len(seg)
                contour_idx += 1

        print(f"Saved {filename} | Total points: {total_points}")
        cv2.imshow(f"Area Split Part {idx_area}", canvas)

    cv2.waitKey(0)
    cv2.destroyAllWindows()


# 사용 예시
image_path = "static/images/animals/cat_drawing.jpg"
output_dir = "drawing_bot/contour_txt/animals"
visualize_and_save_contours(image_path, output_dir=output_dir)
