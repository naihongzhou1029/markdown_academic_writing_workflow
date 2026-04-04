# Remarcademic(Researcher's Markdown Academic) Writing Framework

This repository is a self-contained, reproducible example of a modern plain‑text academic workflow built around **Markdown**, **Pandoc**, and **LaTeX**. The core idea is to separate content from presentation: you write the manuscript as plain text in `paper.md`, while formatting, typesetting, and output details are handled automatically by Pandoc, LaTeX, and a small set of configuration files.

The project demonstrates how to produce a fully typeset scholarly PDF—complete with citations, bibliography, tables, cross‑references, multilingual typesetting, and custom page layout—using version‑controlled text files and command‑line tools.

### Project Goals

- **Sustainable Academic Workflow**: Demonstrate a reliable, plain-text academic writing process using `paper.md`, Pandoc, LaTeX, Zotero/Better BibTeX, and a containerized build pipeline.
- **Multilingual Support**: Show how to translate manuscripts (e.g., to Traditional Chinese) using LLM-based scripts and rebuild typeset PDFs from the translated sources.
- **Reproducibility**: Use Docker to provide a consistent environment where the same source always produces the same output.

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
- **Zotero + Better BibTeX**: Manages bibliographic data and exports it automatically (e.g., `references.json`, `bibliography.bib`) for Pandoc to consume.
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
 - **Mermaid diagram rendering**: Fenced code blocks with language `mermaid` are preprocessed into high‑resolution PNG images using `@mermaid-js/mermaid-cli` inside the Docker container, so diagrams appear as crisp figures in the final PDFs for both English and Traditional Chinese builds.

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

### Project Structure

- **`README.md`**: High-level description of the workflow, toolchain, and build commands.
- **`AGENTS.md`**: Technical constraints and instructions specifically for AI agents.
- **`paper.md`**: The primary English manuscript. Contains YAML metadata for document configuration.
- **`devops.sh`**: Unified development operations script for running the Dockerized build pipeline.
- **`tools/`**: Helper scripts for translation, font detection, validation, and post-processing.
  - **`validate-and-fix-translated-md.sh`**: AI-powered validation to fix formatting errors in translated Markdown.
  - **`process-mermaid.sh`**: Preprocesses Markdown sources to turn Mermaid code blocks into PNG images before Pandoc runs.
- **`Dockerfile`**: Defines the `pandocker-with-tools:latest` image used for builds.
- **`devops.ps1`**: PowerShell implementation for Windows, mirrors `devops.sh`.

### Cursor Development Environment

For developers who use [Cursor](https://cursor.com) as their primary editor, this repository provides rules and skills that the AI assistant follows to support the academic writing workflow.

**Rules and agent constraints**

- **`AGENTS.md`**: Defines constraints and conventions for AI agents (e.g. preserve `paper.md` YAML structure, use `./devops.sh` for builds, keep commit messages bilingual). The assistant reads this file automatically.

**Skills (Agent Skills)**

Project skills in `.cursor/skills/` teach the assistant specialized workflows:

| Skill | Invocation | Purpose |
|-------|------------|---------|
| **ccb** | `/ccb` or "commit with ccb" | Generate Conventional Commit messages with bilingual (Traditional Chinese + English) body; writes to `.git/COMMIT_EDITMSG` |
| **paste-crossref-image** | `/paste-crossref-image` | Save clipboard image to `images/`, describe it, rename by convention, and insert Pandoc figure markdown with `pandoc-crossref` label into the editing buffer |
| **convert-conversation-figure** | "replace conversation screenshot with blockquote" | Replace a conversation screenshot figure with a styled blockquote (User/AI), using OCR or vision to transcribe the content |

**How to use**

- Invoke a skill by name (e.g. `/ccb` in chat) when the assistant supports slash commands.
- Or describe the task in natural language (e.g. "replace this screenshot with a blockquote"); the assistant applies the matching skill when the description matches.

**Build tasks**

The `.vscode/tasks.json` file defines VS Code/Cursor tasks. Use **Run Build Task** (e.g. `Cmd+Shift+B`) to build; the default task builds the paper PDF via `./devops.sh pdf`.

### Basic Usage: Build the Example PDF

This project uses Docker to ensure a consistent build environment. All toolchains (Pandoc, LaTeX, etc.) run inside the `dalibo/pandocker` container.

**Using the devops script (recommended):**

- **Linux/macOS/WSL**: Use `./devops.sh`
- **Windows PowerShell**: Use `./devops.ps1` (invokes Docker from PowerShell)

```bash
# Linux/macOS/WSL
./devops.sh

# Windows PowerShell
./devops.ps1
```

These commands will:
1. Check for the base image `dalibo/pandocker:latest-full` and pull it if needed
2. Build a derived image `pandocker-with-tools:latest` (with `jq` and `curl` pre-installed) if it doesn't exist
3. Create an ephemeral Docker container from the derived image
4. Mount the current directory into the container
5. Run the appropriate build entrypoint inside the container (`devops.sh` on Linux/macOS/WSL, `devops.ps1` invokes `devops.sh` in container on Windows)
6. Automatically remove the container after the build completes

**Note**: The first run will build the derived image, which may take a few minutes. Subsequent runs will use the cached image, making builds faster.

**Note for WSL users**: If you encounter Docker credential errors (e.g., `docker-credential-desktop: executable file not found`), ensure Docker Desktop is running and properly configured for WSL integration. You may need to configure Docker credentials or use `docker login` if required.

**Direct Docker invocation:**

Alternatively, you can run the build directly inside the container. First, build the derived image:

```bash
docker build -t pandocker-with-tools:latest -f Dockerfile .
```

Then run the build:

```bash
docker run --rm \
    -u "$(id -u):$(id -g)" \
    -v "$(pwd)":/workspace \
    -w /workspace \
    pandocker-with-tools:latest \
    bash -lc "./devops.sh printed"
```

The build pipeline (as orchestrated by `devops.sh`) handles all the Pandoc and LaTeX commands, with configuration embedded in the YAML metadata of `paper.md`. The default target builds `Thesis-乃宏-FinalVersion.pdf` (cover + paper merged).

### Mermaid Diagram Support

Remarcademic can render Mermaid diagrams into the final PDFs without any manual pre-processing.

- **How to write diagrams**: Use fenced code blocks with language `mermaid` in `paper.md` (and translated Markdown). For example:

    ```mermaid
    flowchart LR
        A[Start] --> B[End]
    ```

- **What happens during the build**:
  - A helper script (`tools/process-mermaid.sh`) scans the Markdown for `mermaid` code blocks.
  - Each block is rendered to a high‑resolution PNG image (scale factor 3×) via `@mermaid-js/mermaid-cli` running inside the Docker container.
  - The original code block is replaced with an image reference (for example, `![Mermaid diagram](images/mermaid-1.png)`), so Pandoc and LaTeX treat the diagram as a normal figure.

- **Outputs and cleanup**:
  - Generated images are written under `images/mermaid-*.png`.
  - `./devops.sh clean` removes these generated images and intermediate Markdown files.

All standard build targets (`pdf`, `printed`, `zh_tw`, etc.) invoke the Mermaid processing step automatically; no extra commands are required.

### Alternative: Development Operations Center (`devops.sh` / `devops.ps1`)

For a streamlined development experience, the repository includes `devops.sh` (Linux/macOS/WSL) and `devops.ps1` (Windows PowerShell), unified scripts that consolidate the core Dockerized build operations into a single command-line interface. Both scripts accept the same targets.

**Features:**
- **Unified interface**: Single script for all build operations
- **Docker management**: Automatically handles image pulling and building
- **Color-coded output**: INFO (green), WARN (yellow), ERROR (red) for better readability
- **Smart builds**: Detects existing artifacts and builds dependencies as needed
- **No dependency checking**: Simplified workflow without Make's dependency graph

Available targets:

```bash
./devops.sh [target]

# Targets:
#   help      - Show usage information [default]
#   pdf       - Build the main paper PDF (paper.pdf)
#   pdf_date  - Build the paper PDF with date suffix
#   cover     - Build the cover page PDF
#   printed   - Build the printed version (cover + paper)
#   clean     - Remove all generated files
#   deps      - Show information about dependencies
```

**Examples:**

```bash
# Linux/macOS/WSL
./devops.sh           # Show help message (default)
./devops.sh pdf       # Build paper.pdf
./devops.sh pdf_date  # Build thesisYYYYMMDD.pdf
./devops.sh cover     # Build only the cover page
./devops.sh clean     # Clean all generated files
./devops.sh help      # Show help

# Windows PowerShell (same targets)
./devops.ps1
./devops.ps1 pdf
./devops.ps1 cover
./devops.ps1 clean
./devops.ps1 help
```

**When to use:**
- Use `devops.sh` for quick, iterative development and manual builds
- Use `devops.ps1` when invoking Dockerized builds from Windows PowerShell

**Note**: Both `devops.sh` and `devops.ps1` include the `zh_tw` (translation) target, so both English and Traditional Chinese pipelines are available via a single entrypoint.

### Optional: Translate to Traditional Chinese (`zh_tw` target)

This project also demonstrates how to leverage an LLM-backed translation pipeline, driven entirely from the translation scripts, to produce a Traditional Chinese version of the paper:

- **Source**: The original English manuscript in `paper.md` and the NTUST cover page in `cover_page.tex`.
- **LLM translation**: Make targets call translation scripts (`tools/translate.sh`) that invoke a large language model defined by `LLM_MODEL` (default `gemini-2.5-flash`) using an API key stored in `.api_key`. These scripts generate translated Markdown and LaTeX into the `zh_tw/` directory.
- **AI-powered validation**: After initial translation, the `tools/validate-and-fix-translated-md.sh` script automatically reviews the translated Markdown for formatting errors (malformed tables, broken syntax, corrupted YAML) and fixes them while preserving the translated content.
- **Post-processing and typesetting**: Additional scripts fix fonts and layout, then Pandoc and XeLaTeX compile the translated sources into fully typeset PDFs with cover pages.

To run the full translation and build the Traditional Chinese PDFs (including merged cover+paper):

```bash
# Linux/macOS/WSL
./devops.sh zh_tw

# Windows PowerShell
./devops.ps1 zh_tw
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


