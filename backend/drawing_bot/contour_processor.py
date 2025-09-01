#!/usr/bin/env python3
import re
import json
from pathlib import Path
import argparse

# ======================
# 입력 파싱
# ======================
def parse_contours(raw_text: str):
    """
    '# contour N' 으로 구분된 블록에서
    'x, y' 형식의 좌표들을 추출해 contour 리스트를 만든다.
    return: List[List[Tuple[int,int]]]
    """
    blocks = re.split(r'#\s*contour\s*\d+', raw_text, flags=re.IGNORECASE)[1:]
    contours = []
    for blk in blocks:
        pts = []
        for line in blk.strip().splitlines():
            m = re.match(r'\s*(\d+)\s*,\s*(\d+)\s*$', line)
            if m:
                pts.append((int(m.group(1)), int(m.group(2))))
        if pts:
            contours.append(pts)
    return contours

# ======================
# 메인
# ======================
def main():
    parser = argparse.ArgumentParser(description="Convert contour txt to JSONL (EV3 coordinate ready).")
    parser.add_argument("--infile", type=str, default="contours.txt",
                        help="입력 contour 텍스트 파일 경로 (default: contours.txt)")
    parser.add_argument("--outfile", type=str, default="drawing_paths_stream.json",
                        help="출력 JSONL 파일 경로 (default: drawing_paths_stream.json)")
    args = parser.parse_args()

    infile = Path(args.infile)
    outfile = Path(args.outfile)

    raw = infile.read_text(encoding="utf-8")
    contours = parse_contours(raw)
    if not contours:
        raise SystemExit("❌ contours를 찾지 못했습니다. 입력 파일 형식을 확인하세요.")

    # contour 하나당 json.dumps → 한 줄씩 기록
    with outfile.open("w", encoding="utf-8") as f:
        for contour in contours:
            f.write(json.dumps(contour, ensure_ascii=False))
            f.write("\n")

    print(f"✔ {outfile.name} 생성 완료: {len(contours)} contours (한 줄에 1 contour씩)")
    print("   (스케일링 없음, 입력 좌표 그대로 사용)")

if __name__ == "__main__":
    main()
