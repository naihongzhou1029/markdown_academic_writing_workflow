import subprocess
import sys
import os
import re

def get_pdf_text(pdf_path):
    try:
        result = subprocess.run(["pdftotext", "-layout", pdf_path, "-"], capture_output=True, text=True, check=True)
        return result.stdout
    except Exception:
        cwd = os.getcwd()
        rel_path = os.path.relpath(pdf_path, cwd)
        rel_path = rel_path.replace(os.sep, '/')
        docker_cmd = [
            "docker", "run", "--rm",
            "-v", f"{cwd}:/workspace",
            "-w", "/workspace",
            "--entrypoint", "pdftotext",
            "dalibo/pandocker:latest-full",
            "-layout", rel_path, "-"
        ]
        try:
            result = subprocess.run(docker_cmd, capture_output=True, text=True, check=True)
            return result.stdout
        except Exception as e:
            print(f"Error: Could not extract text from PDF using pdftotext locally or via Docker. Details: {e}", file=sys.stderr)
            sys.exit(1)

def copy_to_clipboard(content):
    if sys.platform == 'darwin':
        try:
            process = subprocess.Popen(['pbcopy'], stdin=subprocess.PIPE, text=True)
            process.communicate(input=content)
            return True
        except Exception as e:
            print(f"Failed to copy to clipboard via pbcopy: {e}", file=sys.stderr)
    elif sys.platform == 'win32':
        try:
            process = subprocess.Popen(['clip'], stdin=subprocess.PIPE, text=True)
            process.communicate(input=content)
            return True
        except Exception as e:
            print(f"Failed to copy to clipboard via clip: {e}", file=sys.stderr)
    else:
        try:
            if os.path.exists('/proc/version'):
                with open('/proc/version', 'r') as f:
                    if 'microsoft' in f.read().lower():
                        process = subprocess.Popen(['clip.exe'], stdin=subprocess.PIPE, text=True)
                        process.communicate(input=content)
                        return True
        except Exception:
            pass
        
        for tool in [['xclip', '-selection', 'clipboard'], ['xsel', '--clipboard', '--input']]:
            try:
                process = subprocess.Popen(tool, stdin=subprocess.PIPE, text=True)
                process.communicate(input=content)
                return True
            except Exception:
                continue
                
    return False

def main():
    if len(sys.argv) > 1:
        pdf_path = sys.argv[1]
    else:
        pdf_path = "Thesis-乃宏-FinalVersion.pdf"

    if len(sys.argv) > 2:
        output_md = sys.argv[2]
    else:
        output_md = "toc_list.md"

    if not os.path.exists(pdf_path):
        print(f"Error: File '{pdf_path}' does not exist.", file=sys.stderr)
        sys.exit(1)

    print(f"Extracting Table of Contents from '{pdf_path}'...")
    text = get_pdf_text(pdf_path)

    # 以分頁符切分
    pages = text.split("\x0c")

    # 1. 尋找 TOC 起始頁
    toc_start_page_idx = -1
    for idx, page in enumerate(pages):
        page_strip = page.strip()
        norm_text = re.sub(r"\s+", " ", page_strip)
        if "目錄" in norm_text or "目 錄" in norm_text or "Table of Contents" in norm_text or "Contents" in norm_text:
            toc_start_page_idx = idx
            break

    if toc_start_page_idx == -1:
        print("Error: Could not find Table of Contents starting page.", file=sys.stderr)
        sys.exit(1)

    # 2. 尋找正文起始頁（TOC 的終止頁）
    body_start_page_idx = -1
    for idx in range(toc_start_page_idx + 1, len(pages)):
        page_strip = pages[idx].strip()
        lines = [l.strip() for l in page_strip.split("\n") if l.strip()]
        if not lines:
            continue
        
        is_body = False
        for line in lines[:5]:
            if re.match(r"^(1\s+緒論|1\.\s+緒論|1\s+Introduction|1\.\s+Introduction|第一章\s+緒論)", line):
                is_body = True
                break
        if is_body:
            body_start_page_idx = idx
            break

    if body_start_page_idx == -1:
        print("Warning: Could not find body starting page. Using default offset.", file=sys.stderr)
        body_start_page_idx = min(toc_start_page_idx + 5, len(pages))

    print(f"TOC page range: Page {toc_start_page_idx + 1} to Page {body_start_page_idx}")

    # 3. 擷取並清理目錄頁面內容
    toc_pages = pages[toc_start_page_idx:body_start_page_idx]
    cleaned_lines = []

    for page in toc_pages:
        lines = page.split("\n")
        for line in lines:
            stripped = line.strip()
            if not stripped:
                continue
            if stripped.isdigit() and len(stripped) <= 3:
                continue
            cleaned_lines.append(line.rstrip())

    final_toc = "\n".join(cleaned_lines)

    # 寫入輸出的 Markdown 檔案
    is_zh = "zh_tw" in output_md or "中文" in output_md
    title = "# 目錄\n\n" if is_zh else "# Table of Contents\n\n"

    try:
        with open(output_md, "w", encoding="utf-8") as f:
            f.write(title + final_toc + "\n")
        print(f"Successfully generated clean TOC list artifact: {output_md}")
    except Exception as e:
        print(f"Error writing output file: {e}", file=sys.stderr)
        sys.exit(1)

    # 複製到剪貼簿 (如果成功，則會靜默或列印訊息)
    copied = copy_to_clipboard(final_toc)
    if copied:
        print("Successfully processed and copied TOC to clipboard!")
    else:
        print("Processed successfully, but could not copy to clipboard.")

    # 顯示部分內容預覽
    print("\n--- Preview of Processed TOC (First 15 lines) ---")
    preview_lines = final_toc.split('\n')
    for line in preview_lines[:15]:
        print(line)
    print("...")
    if len(preview_lines) > 20:
        print("\n--- Preview of Processed TOC (Last 5 lines) ---")
        for line in preview_lines[-5:]:
            print(line)

if __name__ == '__main__':
    main()
