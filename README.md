## Markdown-Based Academic Writing Workflow

This repository is a self-contained, reproducible example of a modern plain‑text academic workflow built around **Markdown**, **Pandoc**, and **LaTeX**. The core idea is to separate content from presentation: you write the manuscript as plain text in `paper.md`, while formatting, typesetting, and output details are handled automatically by Pandoc, LaTeX, and a small set of configuration files.

The project demonstrates how to produce a fully typeset scholarly PDF—complete with citations, bibliography, tables, cross‑references, multilingual typesetting, and custom page layout—using version‑controlled text files and command‑line tools.

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
- **Zotero + Better BibTeX**: Manages bibliographic data and exports it automatically (e.g., `references.json`, `Graduate Paper.json`) for Pandoc to consume.
- **CSL styles**: A citation style definition (e.g., `chicago-author-date.csl`) controls how citations and the bibliography are rendered.
- **Pandoc filters**:
  - `--citeproc` for automated citation processing and bibliography generation.
  - `pandoc-crossref` for numbering and cross‑referencing figures, tables, and equations.

### Features Illustrated

- **YAML metadata block as control panel**: At the top of `paper.md`, a rich YAML header configures:
  - Document metadata (title, author, date, abstract).
  - Bibliography files and CSL style.
  - PDF engine (`xelatex`) and LaTeX header includes (`header-includes`).
  - Cross‑reference prefixes and formatting conventions.
  - Section numbering and page numbering behavior.
- **Automated citations**: In‑text citations use Pandoc’s syntax (e.g., `[@key]`, `@key`, `[-@key]`) and are resolved into a formatted bibliography.
- **Tables and cross‑references**: Semantic labels (e.g., `{#tbl:workbench}`, `{#fig:my-plot}`, `{#eq:relativity}`) plus `pandoc-crossref` enable automatic numbering and internal references like `@tbl:workbench`.
- **Multilingual typesetting**: Using XeLaTeX and CJK font settings allows high‑quality Traditional Chinese text alongside English in the same document.
- **Custom appearance and templates**: The text discusses how to hook Pandoc into LaTeX templates (e.g., Eisvogel) to control cover pages and layout variables entirely from YAML.

### Toolchain Requirements

- **Pandoc** (version **3.1.8** with built‑in `--citeproc`; on Linux, `make deps` will install or upgrade to this version).  
  This project relies on `pandoc-crossref` not only for figures, tables, and equations, but also for a **stable, reproducible layout of the Table of Contents, List of Figures, and List of Tables**.  
  Because `pandoc-crossref` is compiled against a specific Pandoc API version, we pin Pandoc to **3.1.8** so that cross‑references and the TOC/LoF/LoT layout remain consistent across machines.
- **LaTeX distribution** (e.g., TeX Live) with XeLaTeX and standard packages installed.
- **Zotero + Better BibTeX extension** for managing and exporting bibliographic data.
- **CSL style file** matching your preferred citation format (e.g., Chicago author‑date).
- A **plain‑text editor** and **Git** for version control.

### Basic Usage: Build the Example PDF

From the repository root, a typical direct Pandoc invocation (assuming all dependencies and referenced files exist and Pandoc **3.1.8** is installed) would look similar to:

```bash
pandoc paper.md \
  --citeproc \
  --filter pandoc-crossref \
  -o paper.pdf
```

In practice, the project is designed so that most configuration is embedded in the YAML metadata of `paper.md`, minimizing the need for long command lines. A `Makefile` or script can be added to wrap the exact command you prefer, making the build step as simple as:

```bash
make
```

depending on how you choose to automate the pipeline.

### Optional: Translate to Traditional Chinese (`zh_tw` target)

This project also demonstrates how to leverage an LLM-backed translation pipeline, driven entirely from the `Makefile`, to produce a Traditional Chinese version of the paper:

- **Source**: The original English manuscript in `paper.md` and the NTUST cover page in `ntust_cover_page.tex`.
- **LLM translation**: Make targets call OS-specific scripts (e.g., `tools/translate-linux.sh`) that invoke a large language model defined by `LLM_MODEL` (default `gemini-2.5-flash`) using an API key stored in `.api_key`. These scripts generate translated Markdown and LaTeX into the `zh_tw/` directory.
- **Post-processing and typesetting**: Additional scripts fix fonts and layout, then Pandoc and XeLaTeX compile the translated sources into fully typeset PDFs with cover pages.

To run the full translation and build the Traditional Chinese PDFs (including merged cover+paper):

```bash
make zh_tw
```

The resulting files are written under the `zh_tw/` directory, mirroring the structure of the original English workflow.

### Conceptual Overview of the Workflow

- **Input layer**: `paper.md` (manuscript) + JSON/BibTeX bibliography files + CSL style.
- **Processing layer**:
  - Pandoc parses the Markdown and YAML metadata.
  - `--citeproc` resolves citations and generates the bibliography.
  - `pandoc-crossref` adds numbering and cross‑references.
  - Pandoc produces LaTeX, which is compiled by XeLaTeX.
- **Output layer**: A fully typeset PDF suitable for academic use.

The goal of this repository is to serve as a concrete, inspectable example of that workflow, showing how to build a sustainable, version‑controlled, and highly customizable academic writing environment entirely around plain‑text files.


