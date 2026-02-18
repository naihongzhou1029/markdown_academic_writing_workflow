#!/usr/bin/env python3
"""
Post-process for PaddleOCR layout segmentation (segment.py).

Reads segmentation metadata (JSON) and the corresponding image; for each region
(in top-to-bottom order):
- text / paragraph_title: extract text via OCR and append to a description block.
- image: describe the crop with an LLM using prior description context, then append.

Writes the final description block as a Markdown file to the export path.

Usage:
  python describe.py <metadata.json> <image.png> [output_dir]

Output is written to <output_dir>/<image_basename>_descriptions.md; if output_dir
is omitted, the script directory (e.g. solutions/paddlepaddle) is used.

The image should be the same one used to generate the metadata (same dimensions)
so that box coordinates align. Requires PaddleOCR and (for image regions) a
Gemini API key in .api_key or --api-key-file.
"""

import argparse
import base64
import json
import os
import sys
import urllib.request
import urllib.error

import cv2
import numpy as np


def get_box_coords(box):
    if "bbox" in box:
        return box["bbox"]
    if "coordinate" in box:
        return box["coordinate"]
    return None


def sort_boxes_top_to_down(boxes):
    """Sort layout boxes in reading order: top-to-down, then left-to-right."""
    if not boxes:
        return boxes

    def sort_key(box):
        coords = get_box_coords(box)
        if not coords:
            return (0, 0)
        x1, y1, x2, y2 = coords
        return (y1, x1)

    return sorted(boxes, key=sort_key)


def crop_from_image(img, coords, pad=10):
    """Return image crop for [x1, y1, x2, y2] with optional padding; coords are float, clipped to image bounds."""
    h, w = img.shape[:2]
    x1 = max(0, int(coords[0]) - pad)
    y1 = max(0, int(coords[1]) - pad)
    x2 = min(w, int(coords[2]) + pad)
    y2 = min(h, int(coords[3]) + pad)
    if x2 <= x1 or y2 <= y1:
        return None
    return img[y1:y2, x1:x2].copy()


def extract_text_ocr(crop_bgr, ocr_engine):
    """Run OCR on a BGR crop; return single string (lines joined by newline)."""
    if crop_bgr is None or crop_bgr.size == 0:
        return ""
    result = ocr_engine.predict(crop_bgr)
    if not result:
        return ""
    page = result[0]
    # PaddleOCR v3: result[0] can be OCRResult (rec_texts attr) or dict-like (rec_texts key).
    rec_texts = getattr(page, "rec_texts", None)
    if not isinstance(rec_texts, list) and hasattr(page, "get") and callable(getattr(page, "get")):
        for key in ("rec_texts", "dt_text", "text", "texts"):
            val = page.get(key)
            if isinstance(val, list) and val:
                rec_texts = val
                break
    if isinstance(rec_texts, list) and rec_texts:
        return "\n".join(str(t) for t in rec_texts).strip()
    # Fallback: legacy list-of-(box, (text, conf)) per page.
    block = page if isinstance(page, (list, tuple)) else []
    lines = []
    for item in (block if isinstance(block, (list, tuple)) else []):
        if isinstance(item, (list, tuple)) and len(item) >= 2:
            lines.append(item[1][0] if isinstance(item[1], (list, tuple)) else str(item[1]))
    return "\n".join(lines).strip()


def _call_gemini(parts, model, api_key):
    """Send a Gemini generateContent request and return the response text."""
    payload = {"contents": [{"parts": parts}]}
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"
    try:
        data = json.dumps(payload).encode("utf-8")
        req = urllib.request.Request(
            url, data=data, headers={"Content-Type": "application/json"}
        )
        with urllib.request.urlopen(req, timeout=120) as response:
            response_data = json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8") if e.fp else ""
        raise RuntimeError(f"Gemini API HTTP error {e.code}: {body}") from e
    except urllib.error.URLError as e:
        raise RuntimeError(f"Gemini API request failed: {e.reason}") from e
    if "error" in response_data:
        raise RuntimeError(
            f"Gemini API error: {response_data['error'].get('message', response_data['error'])}"
        )
    if "candidates" not in response_data or not response_data["candidates"]:
        return ""
    part = response_data["candidates"][0]["content"]["parts"][0]
    return (part.get("text") or "").strip()


def correct_ocr_with_llm(raw_text, crop_bgr, model, api_key):
    """Fix garbled/truncated OCR text using Gemini vision on the original crop."""
    if crop_bgr is None or crop_bgr.size == 0:
        return raw_text
    _, buf = cv2.imencode(".png", crop_bgr)
    b64 = base64.b64encode(buf.tobytes()).decode("ascii")
    prompt = (
        "You are correcting OCR output from a document that may contain Traditional Chinese, "
        "Simplified Chinese, and English mixed together.\n"
        "The image shows the original text region. The OCR engine produced the following raw text:\n\n"
        f"{raw_text}\n\n"
        "Return ONLY the corrected text. Fix garbled characters, missing characters (e.g. truncated "
        "punctuation at line ends), and wrong digits. Preserve the original line structure. "
        "Do NOT add any explanation or extra content."
    )
    parts = [
        {"text": prompt},
        {"inline_data": {"mime_type": "image/png", "data": b64}},
    ]
    return _call_gemini(parts, model, api_key)


def describe_image_with_llm(crop_bgr, context_so_far, model, api_key):
    """Describe the image crop using Gemini vision; context_so_far is prior description text."""
    if crop_bgr is None or crop_bgr.size == 0:
        return ""
    _, buf = cv2.imencode(".png", crop_bgr)
    b64 = base64.b64encode(buf.tobytes()).decode("ascii")
    prompt = (
        "You are describing a cropped region from a document or UI image. "
        "Below is the text content that has already been extracted from surrounding regions (in order). "
        "Describe concisely what is shown in THIS image region (e.g. chart, diagram, screenshot, photo). "
        "One or two sentences in plain language. Do not repeat the surrounding text.\n\n"
        "Surrounding text so far:\n"
    )
    if context_so_far.strip():
        prompt += context_so_far.strip() + "\n\n"
    prompt += "Describe only this image region:"
    parts = [
        {"text": prompt},
        {"inline_data": {"mime_type": "image/png", "data": b64}},
    ]
    return _call_gemini(parts, model, api_key)


def load_metadata(path):
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    boxes = data.get("boxes") or data.get("res", {}).get("boxes")
    if not boxes:
        raise ValueError(f"No 'boxes' in metadata: {path}")
    return boxes


def main():
    parser = argparse.ArgumentParser(
        description="Post-process segment.py output: OCR text regions, LLM-describe image regions, export Markdown."
    )
    parser.add_argument(
        "metadata_json",
        help="Path to segmentation metadata JSON (e.g. *_seg.json).",
    )
    parser.add_argument(
        "image_path",
        help="Path to the image corresponding to the metadata (.png or .jpg).",
    )
    _script_dir = os.path.dirname(os.path.abspath(__file__))
    parser.add_argument(
        "output_dir",
        nargs="?",
        default=_script_dir,
        help="Directory to write the output Markdown file (default: script directory, e.g. solutions/paddlepaddle).",
    )
    parser.add_argument(
        "--api-key-file",
        default=".api_key",
        help="Path to file containing Gemini API key (default: .api_key).",
    )
    parser.add_argument(
        "--model",
        default="gemini-3-flash-preview",
        help="Gemini model for image description (default: gemini-3-flash-preview).",
    )
    parser.add_argument(
        "--ocr-lang",
        default="ch",
        help="PaddleOCR language code: ch (Simplified+Traditional Chinese), chinese_cht (Traditional only), en (English). (default: ch).",
    )
    parser.add_argument(
        "--correct-ocr",
        action="store_true",
        default=False,
        help="After OCR, send each text crop + raw result to Gemini for correction (requires API key).",
    )
    parser.add_argument(
        "--export-text-crops-dir",
        default=None,
        help=(
            "Optional directory to save cropped images for text and paragraph_title regions. "
            "If a relative path is provided, it is resolved under output_dir."
        ),
    )
    args = parser.parse_args()

    if not os.path.isfile(args.metadata_json):
        print(f"Error: metadata file not found: {args.metadata_json}", file=sys.stderr)
        sys.exit(1)
    if not os.path.isfile(args.image_path):
        print(f"Error: image file not found: {args.image_path}", file=sys.stderr)
        sys.exit(1)
    if not os.path.isdir(args.output_dir):
        os.makedirs(args.output_dir, exist_ok=True)

    api_key = None
    api_key_path = args.api_key_file
    if not os.path.isabs(api_key_path):
        # Prefer repo root .api_key if running from solutions/paddlepaddle
        for root in (os.getcwd(), os.path.dirname(os.path.abspath(__file__))):
            candidate = os.path.join(root, api_key_path)
            if os.path.isfile(candidate):
                api_key_path = candidate
                break
    if os.path.isfile(api_key_path):
        with open(api_key_path, "r", encoding="utf-8") as f:
            api_key = f.read().strip()
    if not api_key:
        print(
            "Warning: No API key found; image regions will be skipped. Set --api-key-file or create .api_key.",
            file=sys.stderr,
        )

    base_name = os.path.splitext(os.path.basename(args.image_path))[0]

    text_crops_dir = None
    if args.export_text_crops_dir:
        # Resolve relative directory under output_dir for convenience.
        text_crops_dir = args.export_text_crops_dir
        if not os.path.isabs(text_crops_dir):
            text_crops_dir = os.path.join(args.output_dir, text_crops_dir)
        os.makedirs(text_crops_dir, exist_ok=True)

    boxes = load_metadata(args.metadata_json)
    boxes = sort_boxes_top_to_down(boxes)

    img = cv2.imread(args.image_path)
    if img is None:
        print(f"Error: could not read image: {args.image_path}", file=sys.stderr)
        sys.exit(1)

    try:
        from paddleocr import PaddleOCR
    except ImportError:
        print(
            "Error: PaddleOCR is required. Install with: pip install paddleocr paddlepaddle",
            file=sys.stderr,
        )
        sys.exit(1)

    ocr_engine = PaddleOCR(use_textline_orientation=False, lang=args.ocr_lang)
    description_blocks = []

    for i, box in enumerate(boxes):
        coords = get_box_coords(box)
        if not coords or len(coords) < 4:
            continue
        label = (box.get("label") or "").strip().lower()
        crop = crop_from_image(img, coords)
        if crop is None:
            continue

        if label in ("text", "paragraph_title"):
            if text_crops_dir:
                crop_filename = f"{base_name}_text_{i:03d}.png"
                crop_path = os.path.join(text_crops_dir, crop_filename)
                cv2.imwrite(crop_path, crop)
            text = extract_text_ocr(crop, ocr_engine)
            if text:
                if args.correct_ocr and api_key:
                    try:
                        text = correct_ocr_with_llm(text, crop, args.model, api_key)
                    except Exception as e:
                        print(f"Warning: OCR correction failed for box {i}: {e}", file=sys.stderr)
                if label == "paragraph_title":
                    description_blocks.append(f"## {text}")
                else:
                    description_blocks.append(text)
        elif label == "image" and api_key:
            context = "\n\n".join(description_blocks)
            try:
                desc = describe_image_with_llm(crop, context, args.model, api_key)
                if desc:
                    description_blocks.append(desc)
            except Exception as e:
                print(f"Warning: LLM description failed for box {i}: {e}", file=sys.stderr)
        elif label == "image" and not api_key:
            pass  # already warned above

    md_content = "\n\n".join(description_blocks)
    if not md_content.strip():
        md_content = "(No content extracted.)"

    out_md = os.path.join(args.output_dir, f"{base_name}_descriptions.md")
    with open(out_md, "w", encoding="utf-8") as f:
        f.write(md_content)
    print(f"Wrote: {out_md}")


if __name__ == "__main__":
    main()
