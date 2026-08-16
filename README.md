# Mark Paper

English | [繁體中文](README.zh-TW.md)

---

This repository is a self-contained, reproducible example of a modern plain‑text academic workflow built around **Markdown**, **Pandoc**, and **LaTeX**. The core idea is to separate content from presentation: you write the manuscript as plain text in `paper.md`, while formatting, typesetting, and output details are handled automatically by Pandoc, LaTeX, and a small set of configuration files.

The `main` branch itself is that example: `paper.md` is a tutorial/methodology paper that explains **why** and **how** to author an academic paper or thesis this way — plain text, Pandoc, LaTeX, and Git — instead of a word processor like Microsoft Word or Google Docs. It demonstrates the full pipeline end to end (citations, bibliography, tables, cross‑references, Mermaid diagrams, multilingual typesetting, custom page layout, standalone cover pages, and AI-assisted workflows) using itself as the worked example.

**Note**: The author's actual completed thesis, built with an earlier iteration of this tooling, is archived on the `M11326915` branch for reference rather than kept on `main`.

### Key Ideas

- **Sustainability and durability**: Plain‑text Markdown files are future‑proof compared to proprietary word‑processor formats. They remain readable and diff‑friendly, and integrate naturally with Git.
- **Separation of concerns**: The manuscript (`paper.md`) contains only semantic content and structure; the visual appearance is delegated to LaTeX templates and Pandoc settings defined in the YAML metadata block.
- **Reproducibility**: The entire pipeline—from Markdown and bibliography data to final PDF—is scripted and repeatable. Anyone with the same toolchain can regenerate the exact same output.
- **Transparency and debuggability**: Every stage (Markdown → Pandoc → LaTeX → PDF) is inspectable. Intermediate artifacts like the generated `.tex` file can be examined to debug typesetting or filter issues.
- **Git‑friendly writing**: Because everything is plain text (manuscript, metadata, bibliography), the full research and writing history can be tracked, branched, and merged with standard version control practices.
- **Flattening the toolchain learning curve**: AI assistants and autonomous coding tools serve as compiler copilots, translating high-level writing and layout intents into precise Pandoc YAML and LaTeX macros without requiring authors to master arcane TeX syntax.

### Components Demonstrated in `paper.md`

- **Pandoc**: The central document converter, transforming `paper.md` into LaTeX and then to PDF.
- **LaTeX distribution (TeX Live / XeLaTeX)**: Provides the Unicode-aware typesetting engine and packages needed for advanced layouts, micro-typography, and multilingual text.
- **Plain‑text editor**: Any modern editor (VS Code, Zettlr, etc.) used for authoring the Markdown source.
- **Reference managers (Zotero + Better BibTeX)**: Manages bibliographic data and exports it automatically as `references.json` or `references.bib` for Pandoc to consume.
- **CSL styles**: Citation Style Language definitions (e.g., `chicago-author-date.csl`) governing in-text citations and the bibliography.
- **Pandoc filters**:
  - `--citeproc` for automated citation processing and bibliography generation.
  - `pandoc-crossref` for numbering and cross‑referencing figures, tables, and equations.
- **Mermaid.js & Puppeteer**: Automated headless rendering of programmatic diagrams into high-resolution images (`images/mermaid-*.png`).
- **Standalone LaTeX cover page (`cover_page.tex`)**: A dedicated cover page template featuring the official `images/scholarship_logo.jpg` emblem and bilingual metadata.

### Features Illustrated

- **YAML metadata block as control panel**: At the top of `paper.md`, a rich YAML header configures:
  - Document metadata (title, author, abstract).
  - Bibliography files (`references.json`, `references.bib`) and CSL style (`chicago-author-date.csl`).
  - PDF engine (`xelatex`) and LaTeX header includes (`header-includes`).
  - Cross‑reference prefixes (`figPrefix`, `tblPrefix`, `eqnPrefix`) and formatting conventions.
  - Section numbering (`numbersections: true`), table of contents (`toc`), and page numbering behavior.
  - Complete bibliography inclusion (`nocite: '@*'`).
- **Automated citations & bibliography formatting**: In‑text citations use Pandoc's syntax (e.g., `[@key]`, `@key`, `[-@key]`) and resolve to a clean, bulleted reference list at the end of the manuscript with full author names.
- **Tables and cross‑references**: Semantic labels (e.g., `{#tbl:workbench}`, `{#fig:my-plot}`, `{#eq:relativity}`) plus `pandoc-crossref` enable automatic numbering and internal references like `@tbl:workbench`.
- **Programmatic diagramming with Mermaid**: Flowcharts written directly in `paper.md` are automatically rendered into crisp 3x resolution images and substituted before Pandoc compilation.
- **Multilingual typesetting**: Using XeLaTeX and CJK font settings (`Noto Sans CJK TC` / `PingFang SC`) enables high‑quality Traditional Chinese text alongside English.
- **Custom appearance and templates**: Hooking Pandoc into LaTeX templates (e.g., Eisvogel) allows deep layout customization entirely from YAML.
- **Dedicated cover page & document packaging**: `cover_page.tex` provides a dedicated cover page that is compiled with XeLaTeX and merged with the main manuscript into `printed.pdf` via `./devops.sh printed`.
- **Dynamic date injection**: Dates are automatically injected at build time rather than hardcoded in source files:
  - Paper PDFs use the current date in `YYYY-MM-DD` format (injected via Pandoc's `-V date` flag).
  - Cover PDFs use the current date in `Month DD, YYYY` format (injected via `tools/inject-date.sh`).
- **AI-assisted writing and automated validation**: Integrating LLMs for draft refinement, citation auditing, and structure-aware automated translation (`./devops.sh translate`).

### Repository Structure

```
├── paper.md                    # Primary manuscript (with embedded examples)
├── cover_page.tex              # Standalone LaTeX cover page template
├── references.json             # Bibliographic database in CSL-JSON format
├── references.bib              # Bibliographic database in BibTeX format
├── chicago-author-date.csl     # CSL style definition (Chicago author-date)
├── zh-tw.ini                   # Single configuration file for translation pipeline
├── devops.sh                   # Main build & Docker orchestration script (macOS/Linux/WSL)
├── devops.ps1                  # Windows PowerShell wrapper for devops.sh
├── Dockerfile                  # Extends pandocker with jq, curl, and tools
├── images/
│   └── scholarship_logo.jpg    # High-resolution vector emblem for cover page
└── tools/                      # Build, font detection, and translation helper scripts
    ├── detect-fonts.sh         # Detects available host/container CJK fonts
    ├── inject-date.sh          # Injects current date into cover_page.tex
    ├── merge-pdfs.sh           # Merges cover, administrative forms, and paper PDF
    ├── process-mermaid.sh      # Extracts and renders Mermaid code blocks via Puppeteer
    ├── translate.sh            # LLM translation engine (structure-aware)
    └── validate-and-fix-translated-md.sh # AI syntax validation and repair script
```

### Toolchain Requirements

This project uses **Docker** to provide a consistent, reproducible build environment. All toolchains run inside the container, which includes:

- **Pandoc** (with built‑in `--citeproc`) and **pandoc-crossref** filter
- **LaTeX distribution** (TeX Live) with XeLaTeX and standard packages
- **Mermaid CLI (`mmdc`)** with headless Chromium / Puppeteer for diagram compilation
- All necessary CJK fonts and dependencies

**Prerequisites:**

- **Docker** installed and running on your system
- **bash** available on `PATH` (Git for Windows / WSL on Windows) — `devops.ps1` shells out to `devops.sh`
- A **plain‑text editor** and **Git** for version control

### Basic Usage: Build the Example PDF

All build, translation, and utility operations are driven by a single **Development Operations Center** script:

- **Linux/macOS/WSL**: `./devops.sh <operation>`
- **Windows PowerShell**: `./devops.ps1 <operation>` (delegates to `bash ./devops.sh` — requires Git Bash or WSL)

```bash
# Linux/macOS/WSL
./devops.sh pdf

# Windows PowerShell
./devops.ps1 pdf
```

Running an operation will:

1. Check for the base image `dalibo/pandocker:latest-full` and pull it if needed.
2. Build a derived image `pandocker-with-tools:latest` (with `jq` and `curl` pre-installed) from `Dockerfile`, if it doesn't exist yet.
3. Run the requested operation inside an ephemeral container, with the current directory mounted at `/workspace`.
4. Remove the container automatically after the operation completes.

**Note**: The first run will build the derived image, which may take a few minutes. Subsequent runs reuse the cached image.

Run `./devops.sh help` (or `./devops.ps1 help`) to see all available operations:

| Operation                     | Description                                            |
| ------------------------------ | -------------------------------------------------------- |
| `pdf`                         | Build the main paper PDF (`paper.pdf`)                  |
| `pdf_date`                    | Build the paper PDF with a `YYYYMMDD` date suffix        |
| `cover`                       | Build the standalone cover page PDF (`cover.pdf`)       |
| `printed`                     | Build the printed version (cover + paper merged)        |
| `translate [step]`           | Run the translation pipeline (see below)                |
| `tags`                        | Generate `.tags` from all Markdown files                |
| `ref-list`                    | Extract references from a PDF to clipboard              |
| `toc-list`                    | Extract table of contents from a PDF to clipboard       |
| `clean`                       | Remove all generated intermediate and PDF files         |
| `deps`                        | Show information about local (non-Docker) dependencies  |

### Optional: Translate to Other Languages (`translate` target)

This project demonstrates how to leverage an LLM-backed translation pipeline, driven entirely from `devops.sh`, to produce translated versions of the paper and cover page for any target language.

- **Source**: The original English manuscript in `paper.md` and the cover page in `cover_page.tex`.
- **Config**: The translation target is defined in a single INI config file, `zh-tw.ini` at the repo root (source/target language names, output directory, LLM model, and optional pandoc-crossref label overrides).
- **LLM translation**: `./devops.sh translate` calls `tools/translate.sh`, which invokes a large language model (default `gemini-2.5-flash`, configurable in `zh-tw.ini`) using an API key stored in `.api_key`. The translated Markdown and LaTeX are written into the configured output directory.
- **AI-powered validation**: After initial translation, `tools/validate-and-fix-translated-md.sh` automatically reviews the translated Markdown for formatting errors (malformed tables, broken syntax, corrupted YAML) and fixes them while preserving the translated content.
- **Post-processing and typesetting**: Additional scripts fix fonts and crossref labels, then Pandoc and XeLaTeX compile the translated sources into fully typeset PDFs with cover pages.

```bash
./devops.sh translate                # run the full translation pipeline
./devops.sh translate pdf            # rebuild only the translated paper PDF (re-run one step)
```

`step` may be `all` (default), `markdown`, `cover`, `pdf`, `cover_pdf`, or `printed`.

The resulting files are written under the configured `DIR` (e.g. `translated-zh-tw/`), mirroring the structure of the original English workflow.

### Conceptual Overview of the Workflow

- **Input layer**: `paper.md` (manuscript) + JSON/BibTeX bibliography files (`references.json`, `references.bib`) + CSL style + `cover_page.tex`.
- **Processing layer**:
  - `tools/process-mermaid.sh` renders Mermaid diagrams to high-resolution PNGs.
  - Pandoc parses the Markdown and YAML metadata.
  - `--citeproc` resolves citations and formats the bulleted bibliography.
  - `pandoc-crossref` resolves numbering and cross‑references.
  - Pandoc produces LaTeX, which is compiled by XeLaTeX.
  - `tools/merge-pdfs.sh` fuses the cover page and manuscript into `printed.pdf`.
- **Output layer**: A fully typeset PDF bundle suitable for institutional archiving and academic publication.
