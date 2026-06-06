import subprocess
import sys
import os
import re

def main():
    if len(sys.argv) < 3:
        print("Usage: python3 extract-references-pandoc.py <input_temp_md> <output_ref_md>", file=sys.stderr)
        sys.exit(1)

    input_md = sys.argv[1]
    output_md = sys.argv[2]

    if not os.path.exists(input_md):
        print(f"Error: Input file '{input_md}' does not exist.", file=sys.stderr)
        sys.exit(1)

    # 執行 pandoc 並加上 --wrap=none 確保每一項文獻在 Markdown 中為完整單行
    cmd = [
        "pandoc",
        input_md,
        "--citeproc",
        "--wrap=none",
        "-t", "markdown"
    ]

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        pandoc_output = result.stdout
    except Exception as e:
        print(f"Error executing pandoc: {e}", file=sys.stderr)
        sys.exit(1)

    # 尋找個別的 CSL 條目 (例如 ::: {#ref-key .csl-entry} ... :::)
    # 使用 re.DOTALL 跨行比對
    entry_pattern = r':::\s*\{\s*#ref-([^\s}]+)\s+\.csl-entry\s*\}\s*\n(.*?)\n:::'
    entries = re.findall(entry_pattern, pandoc_output, re.DOTALL)

    if not entries:
        # 備用方案：無 .csl-entry 的格式
        entry_pattern = r':::\s*\{\s*#ref-([^\s}]+)\s*\}\s*\n(.*?)\n:::'
        entries = re.findall(entry_pattern, pandoc_output, re.DOTALL)

    if entries:
        formatted_entries = []
        for idx, (ref_id, entry_content) in enumerate(entries):
            # 清除殘留的 ::: 屬性
            cleaned_content = entry_content.replace(':::', '').strip()
            # 將條目內部的斷行改為單個空格
            cleaned_content = re.sub(r'\s*\n\s*', ' ', cleaned_content)
            # 格式化為有編號的 Markdown 列表
            formatted_entries.append(f"{idx + 1}. {cleaned_content}")
        
        cleaned_text = "\n\n".join(formatted_entries)
    else:
        # 如果無法解析個別條目，回退到整區塊清理，但嘗試手動分割為編號列表
        print("Warning: Could not extract entries individually. Using fallback parser.", file=sys.stderr)
        match = re.search(r':::\s*\{\s*#refs', pandoc_output)
        if not match:
            match = re.search(r'<div\s+id="refs"', pandoc_output)

        if not match:
            print("Error: Could not find references section in pandoc output.", file=sys.stderr)
            sys.exit(1)

        refs_part = pandoc_output[match.start():]
        cleaned = re.sub(r':::\s*\{\s*#[^}]+\}', '', refs_part)
        cleaned = re.sub(r'\n::+[\s\n]*', '\n', cleaned)
        cleaned = re.sub(r':::', '', cleaned)
        
        # 對每一行非空行加上編號
        raw_lines = cleaned.split('\n')
        formatted_entries = []
        item_count = 1
        for line in raw_lines:
            line_strip = line.strip()
            if line_strip:
                formatted_entries.append(f"{item_count}. {line_strip}")
                item_count += 1
        
        cleaned_text = "\n\n".join(formatted_entries)

    # 寫入輸出的 Markdown 檔案
    is_zh = "zh_tw" in output_md or "中文" in output_md
    title = "# 參考文獻\n\n" if is_zh else "# References\n\n"

    try:
        with open(output_md, "w", encoding="utf-8") as f:
            f.write(title + cleaned_text + "\n")
        print(f"Successfully generated clean reference list artifact: {output_md}")
    except Exception as e:
        print(f"Error writing output file: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
