import re
import json
from pathlib import Path

# EV3 축 기준 최대값
AXIS_MAX_X = 400
AXIS_MAX_Y = 1100

def parse_contours(raw_text):
    blocks = re.split(r'#\s*contour\s*\d+', raw_text)[1:]
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

def scale_contours(contours):
    xs = [x for c in contours for x,_ in c]
    ys = [y for c in contours for _,y in c]
    minx, maxx = min(xs), max(xs)
    miny, maxy = min(ys), max(ys)

    def mx(px): return (px - minx) / (maxx - minx) * AXIS_MAX_X
    def my(py): return (py - miny) / (maxy - miny) * AXIS_MAX_Y

    return [
        [(mx(x), my(y)) for x,y in contour]
        for contour in contours
    ]

def contours_txt_to_json(txt_files, outfile_path):
    """여러 txt 파일을 읽어서 json 파일로 변환"""
    all_contours = []

    for txt_file in txt_files:
        raw = Path(txt_file).read_text(encoding="utf-8")
        contours = parse_contours(raw)
        scaled = scale_contours(contours)
        all_contours.extend(scaled)

    outfile = Path(outfile_path)
    outfile.parent.mkdir(parents=True, exist_ok=True)

    with outfile.open("w", encoding="utf-8") as f:
        for contour in all_contours:
            f.write(json.dumps(contour, ensure_ascii=False))
            f.write("\n")

    print(f"✔ {outfile.name} 생성 완료: {len(all_contours)} contours")
    return str(outfile)