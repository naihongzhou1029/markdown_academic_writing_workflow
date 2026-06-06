---
name: convert-conversation-figure
description: Converts a conversation screenshot figure in a Markdown document into a styled blockquote (User/AI). Verifies mdframed header, transcribes image content via OCR or vision, formats as blockquote, and updates figure references. Use when the user asks to replace a conversation screenshot with a styled blockquote, convert a conversation figure to text, or substitute a chat screenshot with quoted text.
---

# Convert Conversation Figure to Blockquote

Replaces a conversation screenshot (e.g. User/AI chat) in Markdown with a styled blockquote so the document remains readable and builds correctly with Pandoc/LaTeX.

## 1. Verify Prerequisites

In the document’s YAML frontmatter (`header-includes`), ensure the `mdframed` setup is present:

- `\usepackage{mdframed}`, `\usepackage{xcolor}`, and a `\surroundwithmdframed` block for `quote`.
- Required style:

```latex
\surroundwithmdframed[
  linewidth=2pt,
  linecolor=gray,
  topline=false,
  rightline=false,
  bottomline=false,
  leftmargin=0pt,
  innerleftmargin=-0.8em,
  skipabove=12pt,
  skipbelow=12pt
]{quote}
```

If missing or different, update the header to match.

## 2. Identify Target

- Find the image line at the user’s cursor or the given location (e.g. `![Alt Text](path/to/image.png){#fig:id}`).
- Note the **image path** and **figure ID** (e.g. `#fig:image13` or `image13`).

## 3. Transcribe Content

- **Option A**: Run `tesseract <image_path> stdout -l chi_tra+eng --psm 6` for OCR.
- **Option B**: If OCR is poor, use vision/image understanding to extract the conversation text.
- Split the text into **User** and **AI** (or System) turns.

## 4. Construct Blockquote

Use standard Markdown blockquotes (`>`):

```markdown
> User：[User Question/Text]
>
> AI：[AI Response/Text]
```

**Rules:**

- Role labels: plain text `User` and `AI`.
- Use a full-width colon (`：`) after the role name.
- Insert an empty blockquote line (`>`) between User and AI for separation.
- Preserve lists/bullets in the response where possible and follow the pattern of typical list style of Markdown texts, but don't use bold styles. Place blank lines above and below the list as well.
- Wrap any `@`-prefixed text (e.g. `@Google`, `@User`) in backticks: `` `@Google` `` to avoid citation parsing.

## 5. Apply Changes

1. Replace the original image line with the new blockquote.
2. Search the following paragraph(s) for references to the figure ID (e.g. `[@fig:image13]`, “Figure 13”, “圖 13”).
3. Reword those references to point to the text (e.g. “如上” / “as above”, “Gemini 的回答如上” / “Gemini’s answer is as above”) so the prose still flows.

## Reference

Full workflow: [.agent/workflows/convert-conversation-figure.md](../../.agent/workflows/convert-conversation-figure.md).
