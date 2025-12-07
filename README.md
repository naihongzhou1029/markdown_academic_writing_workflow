# Remarcademic(Researcher's Markdown Academic) Writing Framework

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
  - This ensures documents always reflect their build date without manual updates to `paper.md` or `ntust_cover_page.tex`.

### Toolchain Requirements

This project uses **Docker** to provide a consistent, reproducible build environment. All toolchains run inside the `dalibo/pandocker` container, which includes:

- **Pandoc** (with built‑in `--citeproc`) and **pandoc-crossref** filter
- **LaTeX distribution** (TeX Live) with XeLaTeX and standard packages
- **Make** and other build utilities
- All necessary fonts and dependencies

**Prerequisites:**
- **Docker** installed and running on your system
- **Zotero + Better BibTeX extension** for managing and exporting bibliographic data (runs on your host machine)
- **CSL style file** matching your preferred citation format (e.g., Chicago author‑date)
- A **plain‑text editor** and **Git** for version control

### Basic Usage: Build the Example PDF

This project uses Docker to ensure a consistent build environment. All toolchains (Pandoc, LaTeX, Make, etc.) run inside the `dalibo/pandocker` container.

**Using the Docker wrapper (recommended):**

- **Linux/macOS/WSL**: Use `./make-docker.sh`
- **Windows CMD**: Use `make-docker.bat`
- **Windows PowerShell**: Use `./make-docker.ps1`

```bash
# Linux/macOS/WSL
./make-docker.sh

# Windows CMD
make-docker.bat

# Windows PowerShell
./make-docker.ps1
```

This will:
1. Check for the base image `dalibo/pandocker:latest-full` and pull it if needed
2. Build a derived image `pandocker-with-tools:latest` (with `jq` and `curl` pre-installed) if it doesn't exist
3. Create an ephemeral Docker container from the derived image
4. Mount the current directory into the container
5. Run `make` inside the container
6. Automatically remove the container after the build completes

**Note**: The first run will build the derived image, which may take a few minutes. Subsequent runs will use the cached image, making builds faster.

**Note for WSL users**: If you encounter Docker credential errors (e.g., `docker-credential-desktop: executable file not found`), ensure Docker Desktop is running and properly configured for WSL integration. You may need to configure Docker credentials or use `docker login` if required.

**Direct Docker invocation:**

Alternatively, you can run make directly inside the container. First, build the derived image:

```bash
docker build -t pandocker-with-tools:latest -f Dockerfile .
```

Then run make:

```bash
docker run --rm \
    -u "$(id -u):$(id -g)" \
    -v "$(pwd)":/workspace \
    -w /workspace \
    pandocker-with-tools:latest \
    make
```

The `Makefile` handles all the Pandoc and LaTeX commands, with configuration embedded in the YAML metadata of `paper.md`. The default target builds `printed.pdf` (cover + paper merged).

### Optional: Translate to Traditional Chinese (`zh_tw` target)

This project also demonstrates how to leverage an LLM-backed translation pipeline, driven entirely from the `Makefile`, to produce a Traditional Chinese version of the paper:

- **Source**: The original English manuscript in `paper.md` and the NTUST cover page in `ntust_cover_page.tex`.
- **LLM translation**: Make targets call translation scripts (`tools/translate.sh`) that invoke a large language model defined by `LLM_MODEL` (default `gemini-2.5-flash`) using an API key stored in `.api_key`. These scripts generate translated Markdown and LaTeX into the `zh_tw/` directory.
- **AI-powered validation**: After initial translation, the `tools/validate-and-fix-translated-md.sh` script automatically reviews the translated Markdown for formatting errors (malformed tables, broken syntax, corrupted YAML) and fixes them while preserving the translated content.
- **Post-processing and typesetting**: Additional scripts fix fonts and layout, then Pandoc and XeLaTeX compile the translated sources into fully typeset PDFs with cover pages.

To run the full translation and build the Traditional Chinese PDFs (including merged cover+paper):

```bash
./make-docker.sh zh_tw
```

The resulting files are written under the `zh_tw/` directory, mirroring the structure of the original English workflow.

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


