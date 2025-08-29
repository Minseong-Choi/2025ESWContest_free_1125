import cv2
import numpy as np
import os

def _fit_contours_to_box(contours, target_w=400, target_h=1100, padding=0, center=True):
    """
    contours를 주어진 캔버스 크기 안(0..target_w, 0..target_h)에
    가능한 한 크게(비율 유지) 스케일/이동하여 반환합니다.
    반환 형식은 OpenCV drawContours 호환 형태 (N,1,2) int32 리스트입니다.
    """
    if not contours:
        return contours, 0.0

    # 모든 좌표를 모아 바운딩박스 계산
    all_pts = np.vstack([c.reshape(-1, 2) for c in contours]).astype(np.float64)
    minx, miny = np.min(all_pts, axis=0)
    maxx, maxy = np.max(all_pts, axis=0)

    src_w = max(1.0, float(maxx - minx))
    src_h = max(1.0, float(maxy - miny))

    # 여백 고려한 사용 가능 크기
    avail_w = max(1.0, float(target_w - 2 * padding))
    avail_h = max(1.0, float(target_h - 2 * padding))

    # 비율 유지 최대 스케일
    scale = min(avail_w / src_w, avail_h / src_h)

    # 출력에서 차지할 폭/높이
    out_w = src_w * scale
    out_h = src_h * scale

    # 오프셋 (센터 정렬 또는 패딩 정렬)
    if center:
        offset_x = (target_w - out_w) / 2.0
        offset_y = (target_h - out_h) / 2.0
    else:
        offset_x = float(padding)
        offset_y = float(padding)

    fitted = []
    for cnt in contours:
        pts = cnt.reshape(-1, 2).astype(np.float64)
        pts[:, 0] = (pts[:, 0] - minx) * scale + offset_x
        pts[:, 1] = (pts[:, 1] - miny) * scale + offset_y

        # 반올림 & 경계 클립
        pts[:, 0] = np.clip(np.rint(pts[:, 0]), 0, target_w).astype(np.int32)
        pts[:, 1] = np.clip(np.rint(pts[:, 1]), 0, target_h).astype(np.int32)

        # 빈 컨투어(점 개수 0) 제거 대비
        if pts.size == 0 or pts.shape[0] == 0:
            continue

        fitted.append(pts.reshape(-1, 1, 2))

    return fitted, scale


def _rotate_contours_90(contours):
    """
    contours를 원점 기준으로 90도 회전 (시계방향)시킨 새 contours 반환.
    """
    rotated = []
    for cnt in contours:
        pts = cnt.reshape(-1, 2).astype(np.float64)
        # (x, y) -> (y, -x)
        new_pts = np.empty_like(pts)
        new_pts[:, 0] = pts[:, 1]
        new_pts[:, 1] = -pts[:, 0]
        rotated.append(new_pts.reshape(-1, 1, 2))
    return rotated


def find_simplified_contours(
    image_path,
    output_file_path,
    simplification_ratio=0.0001,
    target_w=400,
    target_h=1100,
    padding=0,
    center=True
):
    """
    윤곽선을 단순화하여 지정된 파일에 좌표를 저장.
    항상 결과를 0<=x<=target_w, 0<=y<=target_h 박스 안에 최대 크기로 스케일/이동.
    만약 90도로 돌린 쪽이 더 크게 채워진다면 회전 버전을 선택.
    """
    # 1. 이미지 읽기 및 전처리
    image = cv2.imread(image_path)
    if image is None:
        print(f"Error: Unable to load image at {image_path}")
        return

    gray_image = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    ret, binary_image = cv2.threshold(
        gray_image, 127, 255, cv2.THRESH_BINARY_INV | cv2.THRESH_OTSU
    )

    # 2. 윤곽선 찾기
    contours, hierarchy = cv2.findContours(
        binary_image, cv2.RETR_LIST, cv2.CHAIN_APPROX_SIMPLE
    )

    # 3. 윤곽선 단순화
    simplified_contours = []
    total_points = 0
    for contour in contours:
        perimeter = cv2.arcLength(contour, True)
        epsilon = simplification_ratio * perimeter
        approx = cv2.approxPolyDP(contour, epsilon, True)
        if len(approx) > 0:
            simplified_contours.append(approx)
            total_points += len(approx)

    print(f"Total points after simplification: {total_points}")

    if not simplified_contours:
        print("No contours found to save.")
        return

    # 4. 회전 안한 버전 / 회전한 버전 비교 후 선택
    fitted_normal, scale_normal = _fit_contours_to_box(
        simplified_contours, target_w, target_h, padding, center
    )

    rotated = _rotate_contours_90(simplified_contours)
    fitted_rotated, scale_rotated = _fit_contours_to_box(
        rotated, target_w, target_h, padding, center
    )

    if scale_rotated > scale_normal:
        final_contours = fitted_rotated
        print("Rotated 90 degrees for better fit.")
    else:
        final_contours = fitted_normal
        print("Used normal orientation.")

    # 4.5 빈 컨투어 필터링 & 연속 메모리/형 변환(안정성)
    filtered = []
    dropped = 0
    for c in final_contours:
        if c is None or c.size == 0 or c.shape[0] == 0:
            dropped += 1
            continue
        c_fixed = np.ascontiguousarray(c.reshape(-1, 1, 2), dtype=np.int32)
        if c_fixed.shape[0] == 0:
            dropped += 1
            continue
        filtered.append(c_fixed)
    final_contours = filtered
    if dropped > 0:
        print(f"Warning: dropped {dropped} empty contour(s) before drawing.")

    if len(final_contours) == 0:
        print("No drawable contours remain after filtering.")
        return

    # 5. 텍스트 파일로 저장
    os.makedirs(os.path.dirname(output_file_path), exist_ok=True)
    with open(output_file_path, 'w') as f:
        print(f"Saving simplified contours to {output_file_path}...")
        for i, contour in enumerate(final_contours):
            f.write(f"# contour {i}\n")
            for point in contour.reshape(-1, 2):
                x, y = int(point[0]), int(point[1])
                f.write(f"{x},{y}\n")
        print("Done.")

    # 6. 결과 시각화
    contour_image = cv2.drawContours(image.copy(), final_contours, -1, (0, 255, 0), 2)
    cv2.imshow('Simplified Contours', contour_image)
    cv2.waitKey(3000)
    cv2.destroyAllWindows()


# ===== 실행 예시 =====
image_file_path = 'static/images/animals/cat_drawing.jpg'
output_txt_path = 'drawing_bot/contour_txt/animals/cat_contours.txt'

find_simplified_contours(
    image_file_path,
    output_txt_path,
    simplification_ratio=0.0001,
    target_w=400,
    target_h=1100
)
