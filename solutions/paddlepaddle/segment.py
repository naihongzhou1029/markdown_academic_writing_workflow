"""
Layout Detection Script for PaddleOCR

IMPORTANT: This script requires Python 3.11 (PaddlePaddle doesn't support Python 3.14 yet).
Run with: py -3.11 segment.py <image_path>
"""

from paddleocr import LayoutDetection
import cv2
import numpy as np
import argparse
import os
import sys

import yaml

# Configuration options to try:
# 1. Increase img_size for better detection of smaller regions
#    Default is usually 800, try: 1280, 1536, 1920, or 2560
# 2. Adjust layout_threshold (lower = more detections)
#    Default is usually 0.5, try: 0.3, 0.4 for more sensitive detection
# 3. Note: PP-DocLayout-L is trained on document layouts, not game interfaces
#    Your slot machine image may need different preprocessing

# Initialize model
# Note: img_size parameter is not supported for PP-DocLayout-L model
# The model will automatically handle image sizing
model = LayoutDetection(model_name="PP-DocLayout-L")

def load_profile():
    """Load shared configuration from profile.yaml (if present)."""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    profile_path = os.path.join(script_dir, "profile.yaml")
    if not os.path.isfile(profile_path):
        return {}
    try:
        with open(profile_path, "r", encoding="utf-8") as f:
            data = yaml.safe_load(f) or {}
        if not isinstance(data, dict):
            return {}
        return data
    except Exception as e:
        print(f"Warning: failed to load profile.yaml: {e}", file=sys.stderr)
        return {}


_PROFILE = load_profile()
_LAYOUT_CFG = _PROFILE.get("layout") or {}

TEXT_BOX_WIDTH_FACTOR = float(_LAYOUT_CFG.get("text_box_width_factor", 1.05))
TEXT_BOX_HEIGHT_FACTOR = float(_LAYOUT_CFG.get("text_box_height_factor", 1.8))


# Optional: Preprocess image to improve detection
def preprocess_image(image_path, max_size=1920, enhance_contrast=True):
    """
    Preprocess image before layout detection.
    
    Args:
        image_path: Path to input image
        max_size: Maximum dimension (width or height) to resize to
        enhance_contrast: Whether to enhance image contrast
    """
    img = cv2.imread(image_path)
    if img is None:
        raise ValueError(f"Could not read image: {image_path}")
    
    h, w = img.shape[:2]
    original_size = (w, h)
    
    # Resize if image is too large (helps with memory and detection)
    if max_size and max(h, w) > max_size:
        scale = max_size / max(h, w)
        new_w, new_h = int(w * scale), int(h * scale)
        img = cv2.resize(img, (new_w, new_h), interpolation=cv2.INTER_LINEAR)
        print(f"Resized image from {original_size} to ({new_w}, {new_h})")
    
    # Optional: Enhance contrast (may help with detection)
    if enhance_contrast:
        img = cv2.convertScaleAbs(img, alpha=1.2, beta=10)
        print("Applied contrast enhancement")
    
    return img

# Parse command-line arguments
parser = argparse.ArgumentParser(description='Layout Detection Script for PaddleOCR')
parser.add_argument('image_path', help='Path to the input image file')
parser.add_argument(
    '--box-width-scale',
    type=float,
    default=1.0,
    help='Base horizontal scale factor for layout boxes; label-specific scaling (e.g. text vs image) is applied on top.',
)
parser.add_argument(
    '--box-height-scale',
    type=float,
    default=1.0,
    help='Base vertical scale factor for layout boxes; label-specific scaling (e.g. text vs image) is applied on top.',
)
parser.add_argument(
    '--layout-threshold',
    type=float,
    default=None,
    help='Score threshold for layout detection boxes (lower = more boxes, None = use model default).',
)
args = parser.parse_args()

# Derive deterministic output image name based on input
input_path = args.image_path
input_basename = os.path.splitext(os.path.basename(input_path))[0]
input_ext = os.path.splitext(os.path.basename(input_path))[1] or ".png"

output_dir = "./output"
os.makedirs(output_dir, exist_ok=True)
seg_filename = f"{input_basename}_seg{input_ext}"
seg_path = os.path.join(output_dir, seg_filename)
json_filename = f"{input_basename}_seg.json"
json_path = os.path.join(output_dir, json_filename)

# Method 1: Direct file path (simplest)
# output = model.predict(args.image_path, batch_size=1)

# Method 2: Preprocess first (recommended for large or low-contrast images)
image = preprocess_image(args.image_path, max_size=1920, enhance_contrast=True)

predict_kwargs = {}
if args.layout_threshold is not None:
    predict_kwargs["threshold"] = args.layout_threshold

output = model.predict(image, batch_size=1, **predict_kwargs)

# Process results
def get_box_coords(box):
    if 'bbox' in box:
        return box['bbox']
    if 'coordinate' in box:
        return box['coordinate']
    return None

def is_inside(inner, outer):
    # inner, outer are [x1, y1, x2, y2]
    ix1, iy1, ix2, iy2 = inner
    ox1, oy1, ox2, oy2 = outer
    return ix1 >= ox1 and iy1 >= oy1 and ix2 <= ox2 and iy2 <= oy2

def filter_nested_boxes(boxes):
    if not boxes: return []
    to_remove = set()
    for i in range(len(boxes)):
        for j in range(len(boxes)):
            if i == j: continue
            box_i = boxes[i]
            box_j = boxes[j]
            coords_i = get_box_coords(box_i)
            coords_j = get_box_coords(box_j)
            
            if not coords_i or not coords_j: continue
            
            # Check labels - strictly image inside image.
            # Labels might be 'figure', 'image', etc. Depending on model.
            # Assuming 'image' based on user description.
            label_i = str(box_i.get('label', '')).lower()
            label_j = str(box_j.get('label', '')).lower()
            
            # Adjust these terms if needed based on model output classes
            target_labels = ['image', 'figure', 'picture']
            is_image_i = any(t in label_i for t in target_labels)
            is_image_j = any(t in label_j for t in target_labels)
            
            if is_image_i and is_image_j:
                if is_inside(coords_i, coords_j):
                    # i is inside j. Remove i.
                    to_remove.add(i)
    
    return [b for k, b in enumerate(boxes) if k not in to_remove]


def sort_boxes_top_to_down(boxes):
    """
    Sort layout boxes in reading order: top-to-down, then left-to-right for same row.
    Uses top edge (y1) then left edge (x1). Coordinate format: [x1, y1, x2, y2].
    """
    if not boxes:
        return boxes

    def sort_key(box):
        coords = get_box_coords(box)
        if not coords:
            return (0, 0)
        x1, y1, x2, y2 = coords
        return (y1, x1)

    return sorted(boxes, key=sort_key)


def shrink_boxes_inplace(boxes, width_scale: float = 1.0, height_scale: float = 1.0):
    """
    Scale detected layout boxes around their centers before visualization.
    Values < 1.0 shrink boxes, values > 1.0 enlarge them.
    A label-specific factor is applied on top:
      - text/paragraph/paragraph_title: width/height factors from profile.yaml
        (defaults: width +5% (×1.05), height +80% (×1.8))
      - image/figure/picture: no additional scaling beyond base factors
    This affects both the rectangles in the *_seg.png image and
    the coordinates saved into the *_seg.json file.
    """
    if not boxes:
        return boxes

    for box in boxes:
        coords = get_box_coords(box)
        if not coords:
            continue

        # Derive label-based scaling
        label = str(box.get('label', '')).lower()
        text_labels = ['text', 'paragraph', 'paragraph_title']

        w_scale = width_scale
        h_scale = height_scale

        if any(t in label for t in text_labels):
            w_scale *= TEXT_BOX_WIDTH_FACTOR
            h_scale *= TEXT_BOX_HEIGHT_FACTOR
        # image/figure/picture: no extra scaling (keep base width_scale/height_scale)

        x1, y1, x2, y2 = coords
        cx = (x1 + x2) / 2.0
        cy = (y1 + y2) / 2.0

        half_w = (x2 - x1) * w_scale / 2.0
        half_h = (y2 - y1) * h_scale / 2.0

        nx1 = int(round(cx - half_w))
        ny1 = int(round(cy - half_h))
        nx2 = int(round(cx + half_w))
        ny2 = int(round(cy + half_h))

        # Ensure coordinates remain valid and ordered
        if nx2 <= nx1 or ny2 <= ny1:
            continue

        if 'bbox' in box:
            box['bbox'] = [nx1, ny1, nx2, ny2]
        elif 'coordinate' in box:
            box['coordinate'] = [nx1, ny1, nx2, ny2]

    return boxes


def annotate_image_with_classes(image_path: str, boxes):
    """
    Overlay class id / label text near each detected box on the
    visualization image produced by PaddleOCR.
    """
    if not boxes:
        return

    img = cv2.imread(image_path)
    if img is None:
        print(f"Warning: could not read image for annotation: {image_path}")
        return

    for box in boxes:
        coords = get_box_coords(box)
        if not coords:
            continue

        x1, y1, x2, y2 = coords
        x1_i, y1_i = int(x1), int(y1)

        cls_id = box.get("cls_id", "")
        label = str(box.get("label", ""))
        # Example: "2:text" or "2" if label missing
        if label:
            text = f"{cls_id}:{label}"
        else:
            text = str(cls_id)

        # Draw text slightly above the top-left corner of the box
        text_pos = (x1_i, max(0, y1_i - 5))
        cv2.putText(
            img,
            text,
            text_pos,
            cv2.FONT_HERSHEY_SIMPLEX,
            0.5,
            (0, 0, 255),
            1,
            cv2.LINE_AA,
        )

    cv2.imwrite(image_path, img)

for res in output:
    # Filter nested images before processing
    if 'res' in res and 'boxes' in res['res']:
        boxes = filter_nested_boxes(res['res']['boxes'])
        boxes = shrink_boxes_inplace(
            boxes,
            width_scale=args.box_width_scale,
            height_scale=args.box_height_scale,
        )
        res['res']['boxes'] = sort_boxes_top_to_down(boxes)
    elif 'boxes' in res:
        boxes = filter_nested_boxes(res['boxes'])
        boxes = shrink_boxes_inplace(
            boxes,
            width_scale=args.box_width_scale,
            height_scale=args.box_height_scale,
        )
        res['boxes'] = sort_boxes_top_to_down(boxes)

    res.print()

    # Track files before saving so we can rename the newly generated image
    before_files = set(os.listdir(output_dir))

    # Let PaddleOCR write its visualization image(s) into the output directory
    res.save_to_img(save_path=output_dir)

    # Persist raw detection data
    res.save_to_json(save_path=json_path)

    # Rename the first new image to <input_basename>_seg.<ext>
    after_files = set(os.listdir(output_dir))
    new_files = sorted(
        f
        for f in after_files - before_files
        if os.path.splitext(f)[1].lower() in {".png", ".jpg", ".jpeg", ".bmp"}
    )
    if new_files:
        src_path = os.path.join(output_dir, new_files[0])
        if src_path != seg_path:
            os.replace(src_path, seg_path)
            print(f"Saved segmented layout image as: {seg_path}")

    # Access boxes from the result structure (res is a dict-like object)
    boxes = None
    if 'res' in res and 'boxes' in res['res']:
        boxes = res['res']['boxes']
    elif 'boxes' in res:
        boxes = res['boxes']

    # Optionally annotate the visualization with cls_id / label
    if boxes is not None and os.path.exists(seg_path):
        annotate_image_with_classes(seg_path, boxes)

    # Print detection statistics
    if boxes is not None:
        print(f"\nDetected {len(boxes)} layout regions")
        labels = [box['label'] for box in boxes]
        label_counts = {}
        for label in labels:
            label_counts[label] = label_counts.get(label, 0) + 1
        print(f"Label distribution: {label_counts}")

