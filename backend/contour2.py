import cv2
import numpy as np

def find_simplified_contours(image_path, output_file_path, simplification_ratio=0.0001):
    """
    윤곽선을 단순화하여 지정된 파일에 좌표를 저장하는 함수.

    Args:
        image_path (str): 이미지 파일 경로
        output_file_path (str): 좌표를 저장할 텍스트 파일 경로
        simplification_ratio (float): 윤곽선 길이에 대한 단순화 비율.
                                     값이 클수록 좌표 개수가 줄어듭니다.
    """
    # 1. 이미지 읽기 및 전처리
    image = cv2.imread(image_path)
    if image is None:
        print(f"Error: Unable to load image at {image_path}")
        return

    gray_image = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    ret, binary_image = cv2.threshold(gray_image, 127, 255, cv2.THRESH_BINARY_INV | cv2.THRESH_OTSU)

    # 2. 윤곽선 찾기
    contours, hierarchy = cv2.findContours(binary_image, cv2.RETR_LIST, cv2.CHAIN_APPROX_SIMPLE)

    # 3. 윤곽선 단순화 및 좌표 저장
    simplified_contours = []
    total_points = 0

    for contour in contours:
        # 각 윤곽선의 길이를 계산
        perimeter = cv2.arcLength(contour, True)
        
        # 윤곽선 길이의 일정 비율을 epsilon으로 설정
        epsilon = simplification_ratio * perimeter
        
        # 윤곽선을 근사하여 좌표 개수를 줄임
        approx = cv2.approxPolyDP(contour, epsilon, True)
        simplified_contours.append(approx)
        total_points += len(approx)

    print(f"Total points after simplification: {total_points}")

    # 4. 텍스트 파일에 저장
    with open(output_file_path, 'w') as f:
        print(f"Saving simplified contours to {output_file_path}...")
        for i, contour in enumerate(simplified_contours):
            f.write(f"# contour {i}\n")
            for point in contour:
                x, y = point[0]
                f.write(f"{x},{y}\n")
        print("Done.")

    # (선택 사항) 결과 시각화
    contour_image = cv2.drawContours(image.copy(), simplified_contours, -1, (0, 255, 0), 2)
    cv2.imshow('Simplified Contours', contour_image)
    cv2.waitKey(3000)
    cv2.destroyAllWindows()


# 실행할 때 사용할 파일 경로를 설정합니다.
image_file_path = 'static/images/animals/hippo_drawing.jpg'
output_txt_path = 'drawing_bot/contour_txt/animals/hippo_contours.txt'

# simplification_ratio 값을 조절하여 원하는 좌표 개수를 맞추세요.
# 기본값 0.01로 시작하여 너무 많으면 올리고, 너무 적으면 낮춥니다.
find_simplified_contours(image_file_path, output_txt_path, simplification_ratio=0.0001)