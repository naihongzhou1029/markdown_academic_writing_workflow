# Remarcademic (Researcher's Markdown Academic) Writing Framework

This repository is a self-contained, reproducible example of a modern plain‑text academic workflow built around **Markdown**, **Pandoc**, and **LaTeX**. The core idea is to separate content from presentation: you write the manuscript as plain text in `paper.md`, while formatting, typesetting, and output details are handled automatically by Pandoc, LaTeX, and a small set of configuration files.

The `main` branch itself is that example: `paper.md` is a tutorial/methodology paper that explains **why** and **how** to author a thesis this way — plain text, Pandoc, LaTeX, and Git — instead of a word processor like Microsoft Word or Google Docs. It demonstrates the full pipeline end to end (citations, bibliography, tables, cross‑references, multilingual typesetting, custom page layout) using itself as the worked example.

**Note**: This author's actual completed thesis, built with an earlier iteration of this same tooling, is archived on the `M11326915` branch for reference rather than kept on `main`.

### Key Ideas

- **Sustainability and durability**: Plain‑text Markdown files are future‑proof compared to proprietary word‑processor formats. They remain readable and diff‑friendly, and integrate naturally with Git.
- **Separation of concerns**: The manuscript (`paper.md`) contains only semantic content and structure; the visual appearance is delegated to LaTeX templates and Pandoc settings defined in the YAML metadata block.
- **Reproducibility**: The entire pipeline—from Markdown and bibliography data to final PDF—is scripted and repeatable. Anyone with the same toolchain can regenerate the exact same output.
- **Transparency and debuggability**: Every stage (Markdown → Pandoc → LaTeX → PDF) is inspectable. Intermediate artifacts like the generated `.tex` file can be examined to debug typesetting or filter issues.
- **Git‑friendly writing**: Because everything is plain text (manuscript, metadata, bibliography), the full research and writing history can be tracked, branched, and merged with standard version control practices.

### Components Demonstrated in `paper.md`

- **Pandoc**: The central document converter, used to transform `paper.md` into LaTeX and then to PDF.
- **LaTeX distribution (e.g., TeX Live)**: Provides the typesetting engine (XeLaTeX in this example) and packages needed for advanced layouts and multilingual text.
- **Plain‑text editor**: Any modern editor (VS Code, Zettlr, etc.) is used for writing and editing the Markdown source.
- **Zotero + Better BibTeX**: Manages bibliographic data and exports it automatically (e.g., `references.json`, `bibliography.json`) for Pandoc to consume.
- **CSL styles**: A citation style definition (e.g., `chicago-author-date.csl`) controls how citations and the bibliography are rendered.
- **Pandoc filters**:
  - `--citeproc` for automated citation processing and bibliography generation.
  - `pandoc-crossref` for numbering and cross‑referencing figures, tables, and equations.

### Features Illustrated

- **YAML metadata block as control panel**: At the top of `paper.md`, a rich YAML header configures:
  - Document metadata (title, author, abstract).
  - Bibliography files and CSL style.
  - PDF engine (`xelatex`) and LaTeX header includes (`header-includes`).
  - Cross‑reference prefixes and formatting conventions.
  - Section numbering and page numbering behavior.
- **Automated citations**: In‑text citations use Pandoc's syntax (e.g., `[@key]`, `@key`, `[-@key]`) and are resolved into a formatted bibliography.
- **Tables and cross‑references**: Semantic labels (e.g., `{#tbl:workbench}`, `{#fig:my-plot}`, `{#eq:relativity}`) plus `pandoc-crossref` enable automatic numbering and internal references like `@tbl:workbench`.
- **Multilingual typesetting**: Using XeLaTeX and CJK font settings allows high‑quality Traditional Chinese text alongside English in the same document.
- **Custom appearance and templates**: The text discusses how to hook Pandoc into LaTeX templates (e.g., Eisvogel) to control cover pages and layout variables entirely from YAML.
- **Dynamic date injection**: Dates are automatically injected at build time rather than hardcoded in source files:
  - Paper PDFs use the current date in `YYYY-MM-DD` format (injected via Pandoc's `-V date` flag).
  - Cover PDFs use the current date in `Month DD, YYYY` format (injected via `tools/inject-date.sh` script).
  - This ensures documents always reflect their build date without manual updates to `paper.md` or `cover_page.tex`.

### Toolchain Requirements

This project uses **Docker** to provide a consistent, reproducible build environment. All toolchains run inside the `dalibo/pandocker` container, which includes:

- **Pandoc** (with built‑in `--citeproc`) and **pandoc-crossref** filter
- **LaTeX distribution** (TeX Live) with XeLaTeX and standard packages
- All necessary fonts and dependencies

**Prerequisites:**

- **Docker** installed and running on your system
- **bash** available on `PATH` (Git for Windows / WSL on Windows) — `devops.ps1` shells out to `devops.sh`
- **Zotero + Better BibTeX extension** for managing and exporting bibliographic data (runs on your host machine)
- **CSL style file** matching your preferred citation format (e.g., Chicago author‑date)
- A **plain‑text editor** and **Git** for version control

### Basic Usage: Build the Example PDF

All build, translation, and utility operations are driven by a single **Development Operations Center** script:

- **Linux/macOS/WSL**: `./devops.sh <operation>`
- **Windows PowerShell**: `./devops.ps1 <operation>` (delegates to `bash ./devops.sh` — requires Git Bash or WSL)

```bash
# Linux/macOS/WSL
./devops.sh printed

# Windows PowerShell
./devops.ps1 printed
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
| `cover`                       | Build the cover page PDF                                 |
| `printed`                     | Build the printed version (cover + paper merged)          |
| `translate [step]`           | Run the translation pipeline (see below)                  |
| `tags`                        | Generate `.tags` from all Markdown files                  |
| `ref-list`                    | Extract references from a PDF and copy them to the clipboard |
| `toc-list`                    | Extract the table of contents from a PDF and copy it to the clipboard |
| `clean`                       | Remove all generated files                                |
| `deps`                        | Show information about local (non-Docker) dependencies    |

**Direct Docker invocation:**

Alternatively, you can run `devops.sh` directly inside the container yourself. First, build the derived image:

```bash
docker build -t pandocker-with-tools:latest -f Dockerfile .
```

Then run an operation:

```bash
docker run --rm \
    -u "$(id -u):$(id -g)" \
    -v "$(pwd)":/workspace \
    -w /workspace \
    pandocker-with-tools:latest \
    bash devops.sh printed
```

### Optional: Translate to Other Languages (`translate` target)

This project also demonstrates how to leverage an LLM-backed translation pipeline, driven entirely from `devops.sh`, to produce translated versions of the paper and cover page for any target language.

- **Source**: The original English manuscript in `paper.md` and the NTUST cover page in `cover_page.tex`.
- **Config**: The translation target is defined in a single INI config file, `zh-tw.ini` at the repo root (source/target language names, output directory, LLM model, and optional pandoc-crossref label overrides). See the comments in that file for the full key list and available steps.
- **LLM translation**: `./devops.sh translate` calls `tools/translate.sh`, which invokes a large language model (default `gemini-2.5-flash`, configurable in `zh-tw.ini`) using an API key stored in `.api_key`. The translated Markdown and LaTeX are written into the configured output directory.
- **AI-powered validation**: After initial translation, `tools/validate-and-fix-translated-md.sh` automatically reviews the translated Markdown for formatting errors (malformed tables, broken syntax, corrupted YAML) and fixes them while preserving the translated content.
- **Post-processing and typesetting**: Additional scripts fix fonts and crossref labels, then Pandoc and XeLaTeX compile the translated sources into fully typeset PDFs with cover pages.

```bash
./devops.sh translate                # run the full translation pipeline
./devops.sh translate pdf            # rebuild only the translated paper PDF (re-run one step)
```

`step` may be `all` (default), `markdown`, `cover`, `pdf`, `cover_pdf`, or `printed` — useful for iterating on one stage (e.g. font/layout fixes) without re-invoking the LLM every time.

The resulting files are written under the configured `DIR` (e.g. `zh_tw/`), mirroring the structure of the original English workflow.

**Note**: The translation scripts require `curl` and `jq` to be available in the container. These tools are pre-installed in the derived image (`pandocker-with-tools:latest`) that is automatically built from the `Dockerfile` on first use.

### Conceptual Overview of the Workflow

- **Input layer**: `paper.md` (manuscript) + JSON/BibTeX bibliography files + CSL style.
- **Processing layer**:
  - Pandoc parses the Markdown and YAML metadata.
  - `--citeproc` resolves citations and generates the bibliography.
  - `pandoc-crossref` adds numbering and cross‑references.
  - Pandoc produces LaTeX, which is compiled by XeLaTeX.
- **Output layer**: A fully typeset PDF suitable for academic use.

The goal of this repository is to serve as a concrete, inspectable example of that workflow, showing how to build a sustainable, version‑controlled, and highly customizable academic writing environment entirely around plain‑text files.
