---
name: paste-crossref-image
description: Saves clipboard image to images/, generates a Pandoc figure markdown with cross-ref. Use when the user pastes an image from clipboard, asks to add a figure from clipboard, or invokes paste-crossref-image.
---

# Paste Crossref Image

When the current clipboard content is an image: describe it, save to `images/`, and output Pandoc figure markdown with `pandoc-crossref` label.

## Workflow

1. **Save clipboard to `images/`**
   - From project root, run: `./.cursor/skills/paste-crossref-image/scripts/save-clipboard-image.sh`
   - Optional arg: custom dir (default `images`). Script writes `images/YYYY-MM-DD-HH-MM-SS.png` (temp) and prints the path.
   - Uses macOS AppleScript (no external deps); avoids pngpaste which has known washed-out color issues.

2. **Describe the image**
   - Read the saved image (or use the image the user attached).
   - Describe in one phrase: **&lt; 4 words, underscores between words** (e.g. `odds_table_chart`, `ner_workflow_diagram`).
   - This phrase is the **name** (used as figure caption/alt text and filename).

3. **Rename and create label**
   - Rename temp file to `images/name.png`: `mv images/YYYY-MM-DD-HH-MM-SS.png images/name.png`
   - Label: **name_MMSS** (MMSS = minutes+seconds from the temp filename, e.g. `30-15` → `3015`).

4. **Insert markdown into the editing buffer**
   - **Do not** output the markdown in chat only. Use the edit tool (`search_replace`) to insert it into the document the user is editing.
   - Insert the figure markdown at the cursor position (or at the end of the file if cursor position is unknown). Target the focused/active file (e.g. `paper.md`).
   - Format:

```markdown
![name](images/name.png){#fig:name_MMSS}
```

## Example

Clipboard image: odds table screenshot.

1. Script saves → `images/2026-02-18-14-30-15.png` (temp)
2. Name: `odds_table_screenshot` → rename to `images/odds_table_screenshot.png`, label: `odds_table_screenshot_3015` (MMSS from 30-15)
3. Insert into the editing buffer (e.g. at cursor in `paper.md`):

```markdown
![odds_table_screenshot](images/odds_table_screenshot.png){#fig:odds_table_screenshot_3015}
```

## Fallback

If clipboard access fails: ask the user to save the image to `images/` manually with a temp filename (e.g. `YYYY-MM-DD-HH-MM-SS.png`), then proceed from step 2.
