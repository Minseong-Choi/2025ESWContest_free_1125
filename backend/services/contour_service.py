import cv2
import numpy as np
import os

MAX_X, MAX_Y = 400, 1100  # 최종 캔버스 크기

def _rotate_points_90_ccw(contours_pts):
    rotated = []
    for cnt in contours_pts:
        pts = cnt.reshape(-1, 2).astype(np.float64)
        new_pts = np.empty_like(pts)
        new_pts[:, 0] = -pts[:, 1]
        new_pts[:, 1] =  pts[:, 0]
        rotated.append(new_pts.reshape(-1, 1, 2))
    return rotated

def _compute_fit_params(contours_pts, target_w=MAX_X, target_h=MAX_Y, padding=0, center=True):
    if not contours_pts:
        return 1.0, 0.0, 0.0
    all_pts = np.vstack([c.reshape(-1, 2) for c in contours_pts]).astype(np.float64)
    minx, miny = np.min(all_pts, axis=0)
    maxx, maxy = np.max(all_pts, axis=0)
    src_w = max(1.0, float(maxx - minx))
    src_h = max(1.0, float(maxy - miny))
    avail_w = max(1.0, float(target_w - 2*padding))
    avail_h = max(1.0, float(target_h - 2*padding))
    S = min(avail_w / src_w, avail_h / src_h)
    out_w = src_w * S
    out_h = src_h * S
    if center:
        tx = (target_w - out_w) / 2.0 - (-minx) * S
        ty = (target_h - out_h) / 2.0 - (-miny) * S
    else:
        tx = float(padding) - (-minx) * S
        ty = float(padding) - (-miny) * S
    return S, tx, ty

def _apply_transform_once(contours_pts, S, tx, ty):
    transformed = []
    for cnt in contours_pts:
        pts = cnt.reshape(-1, 2).astype(np.float64)
        pts[:, 0] = pts[:, 0] * S + tx
        pts[:, 1] = pts[:, 1] * S + ty
        transformed.append(pts.reshape(-1, 1, 2))
    return transformed

def _content_bbox_in_canvas(transformed_contours):
    all_pts = np.vstack([c.reshape(-1, 2) for c in transformed_contours]).astype(np.float64)
    minx = float(all_pts[:,0].min())
    maxx = float(all_pts[:,0].max())
    miny = float(all_pts[:,1].min())
    maxy = float(all_pts[:,1].max())
    return minx, miny, maxx, maxy

def _split_by_three_vertical_bands(transformed_contours, content_min_y, content_max_y):
    h = max(1e-9, content_max_y - content_min_y)
    step = h / 3.0
    bands = [
        (content_min_y, content_min_y + step),
        (content_min_y + step, content_min_y + 2*step),
        (content_min_y + 2*step, content_max_y + 1e-9)
    ]
    parts = [[], [], []]
    for cnt in transformed_contours:
        pts = cnt.reshape(-1, 2).astype(np.float64)
        if pts.shape[0] == 0:
            continue
        for band_idx, (y0, y1) in enumerate(bands):
            seg = []
            for i in range(pts.shape[0]):
                y = pts[i,1]
                in_band = (y0 <= y < y1) if band_idx < 2 else (y0 <= y <= y1)
                if in_band:
                    seg.append( (float(pts[i,0]), float(pts[i,1])) )
                else:
                    if len(seg) > 0:
                        parts[band_idx].append(seg)
                        seg = []
            if len(seg) > 0:
                parts[band_idx].append(seg)
    return parts

def _dedupe_consecutive_points(seq):
    if not seq: return seq
    deduped = [seq[0]]
    for p in seq[1:]:
        if p != deduped[-1]:
            deduped.append(p)
    return deduped

def _dedupe_parts(parts):
    cleaned = []
    for segs in parts:
        new_segs = []
        for seg in segs:
            d = _dedupe_consecutive_points(seg)
            if len(d) > 0:
                new_segs.append(d)
        cleaned.append(new_segs)
    return cleaned

def _round_clip_parts(parts, w=MAX_X, h=MAX_Y):
    out = []
    for segs in parts:
        new_segs = []
        for seg in segs:
            new_seg = []
            for (x, y) in seg:
                xi = int(np.clip(round(x), 0, w))
                yi = int(np.clip(round(y), 0, h))
                new_seg.append((xi, yi))
            new_segs.append(new_seg)
        out.append(new_segs)
    return out

def save_parts_as_txt(base_name, output_dir, parts_int):
    os.makedirs(output_dir, exist_ok=True)
    txt_files = []
    for i, segs in enumerate(parts_int, start=1):
        filename = os.path.join(output_dir, f"{base_name}_part{i}.txt")
        txt_files.append(filename)
        contour_idx = 0
        with open(filename, "w") as f:
            for seg in segs:
                if not seg: continue
                seg = _dedupe_consecutive_points(seg)
                if not seg: continue
                f.write(f"# contour {contour_idx}\n")
                for (x,y) in seg:
                    f.write(f"{x},{y}\n")
                contour_idx += 1
    return txt_files

def process_contours_and_split3(image_path, output_dir, simplification_ratio=0.0001):
    os.makedirs(output_dir, exist_ok=True)
    base_name = os.path.splitext(os.path.basename(image_path))[0]
    image = cv2.imread(image_path)
    if image is None:
        raise FileNotFoundError(f"Error: Unable to load image at {image_path}")
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    _, binary = cv2.threshold(gray, 127, 255, cv2.THRESH_BINARY_INV | cv2.THRESH_OTSU)
    contours, _ = cv2.findContours(binary, cv2.RETR_LIST, cv2.CHAIN_APPROX_SIMPLE)
    simplified = []
    for c in contours:
        peri = cv2.arcLength(c, True)
        eps = simplification_ratio * peri
        approx = cv2.approxPolyDP(c, eps, True)
        if approx is not None and approx.shape[0] > 0:
            simplified.append(approx)

    if not simplified:
        raise ValueError("No contours found.")

    normal_contours = [c.copy() for c in simplified]
    rotated_contours = _rotate_points_90_ccw(simplified)
    S_n, tx_n, ty_n = _compute_fit_params(normal_contours, MAX_X, MAX_Y, 0, True)
    S_r, tx_r, ty_r = _compute_fit_params(rotated_contours, MAX_X, MAX_Y, 0, True)

    if S_r > S_n:
        chosen_oriented = rotated_contours
        S, tx, ty = S_r, tx_r, ty_r
    else:
        chosen_oriented = normal_contours
        S, tx, ty = S_n, tx_n, ty_n

    transformed = _apply_transform_once(chosen_oriented, S, tx, ty)
    minx_c, miny_c, maxx_c, maxy_c = _content_bbox_in_canvas(transformed)
    parts_float = _split_by_three_vertical_bands(transformed, miny_c, maxy_c)
    parts_float = _dedupe_parts(parts_float)
    parts_int   = _round_clip_parts(parts_float, MAX_X, MAX_Y)
    return save_parts_as_txt(base_name, output_dir, parts_int)