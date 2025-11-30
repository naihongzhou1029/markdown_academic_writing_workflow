#!/bin/bash
# Detect fonts on Linux using fc-list

MAIN_FONT="Liberation Serif"

# Try to detect available CJK fonts, prioritizing Noto (installed via deps)
# Check if Noto Sans CJK SC is available, fallback to commonly available fonts
CJK_FONT_SC=$(fc-list 2>/dev/null | grep -i "Noto Sans CJK SC" | head -1 | cut -d: -f2 | cut -d, -f1 | xargs)
if [ -z "$CJK_FONT_SC" ]; then
    # Fallback: try to find any Simplified Chinese font
    CJK_FONT_SC=$(fc-list :lang=zh-cn 2>/dev/null | head -1 | cut -d: -f2 | cut -d, -f1 | xargs)
fi
if [ -z "$CJK_FONT_SC" ]; then
    # Final fallback to commonly available font
    CJK_FONT_SC="AR PL UMing CN"
fi

# Same for Traditional Chinese
CJK_FONT_TC=$(fc-list 2>/dev/null | grep -i "Noto Sans CJK TC" | head -1 | cut -d: -f2 | cut -d, -f1 | xargs)
if [ -z "$CJK_FONT_TC" ]; then
    # Fallback: try to find any Traditional Chinese font
    CJK_FONT_TC=$(fc-list :lang=zh-tw 2>/dev/null | head -1 | cut -d: -f2 | cut -d, -f1 | xargs)
fi
if [ -z "$CJK_FONT_TC" ]; then
    # Final fallback to commonly available font
    CJK_FONT_TC="AR PL UMing TW"
fi

echo "CJK_FONT_SC=$CJK_FONT_SC"
echo "CJK_FONT_TC=$CJK_FONT_TC"
echo "MAIN_FONT=$MAIN_FONT"

