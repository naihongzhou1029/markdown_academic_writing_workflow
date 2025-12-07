---
name: Convert Google Docs HTML to Framework
overview: "Convert the Google Docs HTML export in `imported_paper/` into the framework's required format: `paper.md` (with YAML metadata), `bibliography.json` (CSL JSON format), and `cover_page.tex` (LaTeX cover page). The conversion will parse HTML structure, extract metadata, convert content to Markdown, handle 56 images, and use the user-provided bibliography file."
todos:
  - id: parse-html
    content: Create Python script to parse HTML file, extract structure (headings, paragraphs, tables, images), and identify cover page, abstract, and main content sections
    status: pending
  - id: extract-metadata
    content: "Extract metadata: title (both Chinese and English), author (Chinese), advisor (Chinese), student ID, abstract, and date from HTML"
    status: pending
  - id: convert-to-markdown
    content: "Convert HTML elements to Markdown: headings, paragraphs, lists, tables, formatting, and handle Traditional Chinese text encoding"
    status: pending
  - id: handle-images
    content: Map image references from HTML to Markdown syntax, copy images from imported_paper/images/ to images/, and generate figure labels
    status: pending
  - id: process-bibliography
    content: Process user-provided bibliography file in imported_paper/ (JSON or BibTeX) and save as bibliography.json
    status: pending
  - id: generate-paper-md
    content: Generate paper.md with YAML metadata block (matching existing format) and converted Markdown content
    status: pending
  - id: generate-cover-tex
    content: Generate cover_page.tex using existing template, renaming metadata commands (\TitleEn -> \Title, \AuthorEn -> \Author, \AdvisorEn -> \Advisor) and replacing them with extracted values (Chinese names)
    status: pending
  - id: test-build
    content: Test the generated files by running ./make-docker.sh to verify compilation and identify any issues
    status: pending
---

# Convert Google Docs HTML Export to Framework Format

## Overview

The imported paper in `imported_paper/` contains:

- `LeveragingGenerativeAIforKnowledgeExtractionf.html` - Single-line HTML export (~244KB)
- `images/` directory with 56 PNG images (image1.png through image56.png)
- `collections.json` - CSL JSON bibliography file with 29 entries (already in correct format, will become `bibliography.json`)
- `bibliography.json` - BetterBibTeX JSON export from Zotero with `itemID` → `citationKey` mapping (useful for citation mapping backup)

The document appears to be a Traditional Chinese thesis with English title, containing cover page information, abstract, and main content.

## Implementation Strategy

### Phase 1: HTML Parsing and Analysis

1. **Parse HTML structure**

   - Use Python's `html.parser` or `BeautifulSoup` to parse the single-line HTML
   - Extract document structure: headings, paragraphs, tables, lists, images
   - Identify cover page section (appears to be in a table at the beginning)
   - Locate abstract section
   - Find main content sections

2. **Extract metadata**

   - **Title**: Extract from `<h1>` tags (both Traditional Chinese and English versions)
     - For `paper.md` YAML: Use both titles (Chinese and English)
   - **Author**: Extract from cover page table ("研究生：周乃宏")
     - For `paper.md`: Use Chinese name only: "周乃宏"
     - For `cover_page.tex`: Use Chinese name: "周乃宏"
   - **Advisor**: Extract from cover page ("指導教授：鄭正元，戴文凱 博士")
     - Two advisors: 鄭正元 (Zhengyuan Zheng) and 戴文凱 (Wenkai Dai)
     - For `cover_page.tex`: Use Chinese names: "鄭正元，戴文凱 博士"
     - Note: Advisor information may not be needed in `paper.md` YAML metadata (check if it's used)
   - **Student ID**: Extract "學號：M11326915"
   - **Abstract**: Extract abstract paragraph(s) in Traditional Chinese
   - **Date**: Extract from cover page ("115年 6月" - likely 2026 June)
   - **Language settings**:
     - Use `CJKmainfont: "PingFang TC"` (Traditional Chinese font) instead of "PingFang SC"
     - Use Chinese cross-reference prefixes:
       - `figPrefix: "圖"` (single string)
       - `tblPrefix: "表"` (single string)

### Phase 2: Content Conversion to Markdown

1. **Convert HTML elements to Markdown**

   - Headings: `<h1>` → `#`, `<h2>` → `##`, etc.
   - Paragraphs: `<p>` → plain text with proper spacing
   - Lists: `<ol>`, `<ul>` → Markdown lists
   - Tables: Convert HTML tables to Pandoc pipe tables
   - Bold/Italic: `<b>`, `<strong>`, `<i>`, `<em>` → `**text**`, `*text*`
   - Links: `<a>` → [`text`](url)

2. **Handle images**

   - Find all `<img>` tags with `src="images/image*.png"`
   - Map image references to framework's `images/` directory
   - Convert to Markdown image syntax: `![alt text](images/filename.png){#fig:label width=X%}`
   - Generate appropriate figure labels (e.g., `{#fig:image1}`)
   - Copy images from `imported_paper/images/` to framework's `images/` directory

3. **Handle Traditional Chinese text**

   - Decode HTML entities (e.g., `&#22283;` → 國)
   - Preserve mixed Chinese/English content
   - Ensure proper encoding (UTF-8)

4. **Convert citations**

   - Parse author-date citations from HTML: `(Author et al., Year)`, `(Author, Year)`, `(Author & Author, Year)`
   - Load `collections.json` to build citation key lookup
   - Match citations to bibliography entries by author surname + year
   - Convert to Pandoc citation syntax: `[@citationKey]`
   - Preserve citation context (text before/after citation)

### Phase 3: Bibliography Processing

1. **Process bibliography files**

   - `collections.json`: Already in correct CSL JSON format with 29 entries
   - `bibliography.json`: BetterBibTeX export (used for citation mapping backup)
   - Copy `collections.json` directly to `bibliography.json` (no conversion needed)

2. **Generate `bibliography.json`** (will REPLACE existing file)

   - Copy `imported_paper/collections.json` to `bibliography.json`
   - Validate JSON structure (should be an array of CSL JSON objects)
   - Each entry has proper `id` field matching citation keys (e.g., `ackoffDataWisdom1989`)

### Phase 4: Generate Output Files

1. **Generate `paper.md`** (will REPLACE existing file)

   - Read existing `paper.md` to understand YAML metadata structure
   - Create YAML metadata block matching existing structure:
     ```yaml
     ---
     title: "Traditional Chinese Title / English Title"
     author: "周乃宏"
     abstract: "Traditional Chinese abstract text"
     bibliography:
       - bibliography.json
     csl: chicago-author-date.csl
     CJKmainfont: "PingFang TC"
     figPrefix: "圖"
     tblPrefix: "表"
     # ... other metadata
     ---
     ```

   - Append converted Markdown content (primarily in Traditional Chinese, with English domain terms and citations preserved)
   - Ensure proper section numbering and structure

2. **Generate `cover_page.tex`** (will REPLACE existing file)

   - Read existing `cover_page.tex` to understand structure/format
   - Generate NEW `cover_page.tex` file that replaces the existing one
   - Rename metadata commands for neutrality:
     - `\TitleEn` → `\Title`
     - `\AuthorEn` → `\Author`
     - `\AdvisorEn` → `\Advisor`
   - Replace metadata commands with extracted values:
     - `\Title`: Chinese title (or both Chinese and English)
     - `\Author`: Chinese name ("周乃宏")
     - `\Advisor`: Chinese names ("鄭正元，戴文凱 博士")
     - `\StudentID`: Student ID ("M11326915")
     - `\ROCDate`: Date in "Month DD, YYYY" format (convert from "115年 6月")
   - Preserve LaTeX structure and formatting, updating command usages in the document body

3. **Generate `bibliography.json`** (will REPLACE existing file)

   - Copy content from user-provided bibliography file

### Phase 5: Image Management

1. **Copy images**

   - Copy all images from `imported_paper/images/` to framework's `images/` directory
   - Preserve original filenames or rename if needed for consistency
   - Update image references in Markdown to match new locations

## Technical Implementation

### Tools/Libraries

- Python 3 with `html.parser` or `BeautifulSoup4` for HTML parsing
- `json` for JSON generation
- Standard library for file operations

### Script Structure

Create a conversion script (e.g., `tools/convert-google-docs-html.py`) that:

1. Reads `imported_paper/LeveragingGenerativeAIforKnowledgeExtractionf.html`
2. Parses HTML structure
3. Extracts metadata and content
4. Converts to Markdown
5. Copies `collections.json` to `bibliography.json`
6. Generates `paper.md`, `bibliography.json`, `cover_page.tex`
7. Copies images to `images/` directory

## Challenges and Considerations

1. **Citation mapping**: Google Docs uses author-date citations that can be mapped to `collections.json` keys.

   - *Confirmed*: HTML contains author-date citations like `(Mardani et al., 2018)`, `(Ackoff, 1989)`, `(Huang & Li, 2009)`, etc.
   - *Available files*:
     - `collections.json`: Clean CSL JSON with proper citation keys (e.g., `mardaniRelationshipKnowledgeManagement2018`, `ackoffDataWisdom1989`)
     - `bibliography.json`: BetterBibTeX export with `itemID` → `citationKey` mapping (backup reference)
   - *Strategy*:
     - Parse `(Author et al., Year)` patterns from HTML using regex: `\([^)]*(?:19|20)\d{2}[^)]*\)`
     - Match to `collections.json` entries by author surname + year
       - Extract author surname from citation (e.g., "Mardani" from "Mardani et al., 2018")
       - Extract year (e.g., "2018")
       - Find matching entry in `collections.json` where `author[0].family` matches surname and `issued.date-parts[0][0]` matches year
     - Convert to Pandoc format: `[@mardaniRelationshipKnowledgeManagement2018]`
     - Handle edge cases:
       - Multiple authors: Match by first author surname
       - "et al." citations: Match by first author surname
       - Single author: Match by author surname
       - Use `bibliography.json` metadata as fallback if exact match fails
   - *Example transformation*:
     - HTML: `... knowledge management (Ackoff, 1989) shows that ...`
     - Markdown: `... knowledge management [@ackoffDataWisdom1989] shows that ...`

2. **Complex tables**: Some HTML tables may need manual adjustment after conversion.

3. **Image labeling**: Automatic figure labels may need adjustment for proper cross-referencing.

4. **Mixed language content**:

   - Primary language is Traditional Chinese
   - Preserve English domain terms and citations as-is
   - Use Traditional Chinese font (PingFang TC) in YAML metadata
   - Use Chinese cross-reference prefixes (圖, 表)

5. **Date format conversion**: Convert "115年 6月" (ROC calendar) to standard date format for cover page.

## Output Files (will REPLACE existing files)

- `paper.md`: Complete Markdown document with YAML metadata (REPLACES existing paper.md)
- `bibliography.json`: CSL JSON bibliography (REPLACES existing bibliography.json)
- `cover_page.tex`: LaTeX cover page with extracted metadata (REPLACES existing cover_page.tex)
- `images/*.png`: All images copied from imported_paper/images/ (adds to existing images/ directory)

## Post-Conversion Tasks

1. Review and verify `paper.md` structure
2. Verify citations map correctly to entries in `collections.json` (now `bibliography.json`)
3. Test build with `./make-docker.sh` to ensure proper compilation
4. Adjust image references and labels as needed
5. Verify cross-references work correctly

