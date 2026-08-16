## Agent Guide for This Repository

This project is a worked example of a Markdown → Pandoc → LaTeX academic writing workflow with an optional LLM-powered translation pipeline. The **primary conceptual and user-facing documentation is in `README.md`**; always read that file first to understand the workflow, tools, and operations.

### Project Intent

- **Main goal**: Demonstrate a sustainable, plain-text academic workflow using `paper.md`, Pandoc, LaTeX, Zotero/BBT, and a `devops.sh`/`devops.ps1`-driven build. The `main` branch's `paper.md` is itself a tutorial paper arguing for and illustrating this methodology, rather than a live thesis manuscript.
- **Secondary goal**: Show how to translate the manuscript and cover into other languages using LLM-based scripts, driven by a single INI config file, and rebuild PDFs from the translated sources.
- **Note**: The author's actual completed thesis, built with an earlier iteration of this tooling, is archived on the `M11326915` branch rather than kept on `main`.

### Key Entry Points

- **`README.md`**: High-level description of the workflow, toolchain, build operations (`./devops.sh printed`, `./devops.sh translate`), and the translation pipeline.
- **`paper.md`**: Primary English manuscript; contains YAML metadata that configures Pandoc, citations, cross-references, and typesetting options.
- **`devops.sh`** / **`devops.ps1`**: The single build entry point (replaces the old `Makefile` + `make-docker.*` wrapper pair). `devops.sh` runs on Linux/macOS/WSL and does all the Docker orchestration and build logic; `devops.ps1` is a thin Windows wrapper that delegates to `bash ./devops.sh`. Operations: `pdf`, `pdf_date`, `cover`, `printed`, `translate [step]`, `tags`, `ref-list`, `toc-list`, `clean`, `deps`.
- **`zh-tw.ini`**: Single INI config file at the repo root for the translation pipeline (`DIR`, `FROM`, `TO`, `MODEL`, optional `FIGURE_LABEL`/`TABLE_LABEL`). See the comments in that file for the full key list.
- **`tools/` scripts**: Linux-based helpers for font detection, translation, validation, post-processing, logo download, PDF merging, and dependency installation. All scripts run inside the Docker container.
  - **`validate-and-fix-translated-md.sh`**: AI-powered validation that reviews translated Markdown files for formatting errors (malformed tables, broken syntax, corrupted YAML) and automatically fixes them.
  - **`postprocess-translated-md.sh`**: Fixes CJK font references and (optionally) pandoc-crossref figure/table labels.

### Constraints and Conventions for Agents

- **Default build target**: When the user requests a build or compilation without specifying a target operation, always default to the `pdf` target for `devops.sh` or `devops.ps1` (`./devops.sh pdf` or `./devops.ps1 pdf`).
- **Do not change the overall structure** of `paper.md`’s YAML metadata or its role as the single source of truth for document configuration, unless explicitly asked.
- **Preserve operation names and roles** in `devops.sh`/`devops.ps1` (`pdf`, `pdf_date`, `cover`, `printed`, `translate`, `tags`, `ref-list`, `toc-list`, `clean`, `deps`) to avoid breaking existing workflows or documentation.
- **Keep `README.md` and `AGENTS.md` consistent** with any changes to:
  - Build commands and primary operations (use `./devops.sh`/`./devops.ps1` for Docker-based builds).
  - Translation pipeline behavior (`zh-tw.ini`'s `DIR`/`FROM`/`TO`/`MODEL`, `.api_key` usage).
  - Docker container usage and requirements.
- As a rule of thumb: **if you add or change `devops.sh` operations, translation scripts/profiles, API key usage, or primary documentation**, update this file accordingly.
- **Be cautious with translation scripts**:
  - Treat `.api_key` as a secret; don't hardcode keys or log them.
  - Keep language directions and font/label assumptions (e.g., CJK fonts, `FIGURE_LABEL`/`TABLE_LABEL`) driven by `zh-tw.ini` — don't hardcode a specific target language back into `devops.sh` or the `tools/` scripts.
  - All scripts run inside the Docker container; ensure they use Linux-compatible commands (bash, standard Unix utilities).
  - The translation pipeline includes automatic validation: after initial translation, the system uses AI to detect and fix formatting errors in the translated content while preserving the translation itself.
 - **Sync plan progress to Markdown plan files**: When using plan-style workflows or multi-step tasks, always include a final step to sync the plan’s current state into the relevant Markdown plan file (e.g., under a `plans/` directory), so that progress is persistently recorded outside the transient agent context.

### Commit Message Conventions for Agents

- **Use nested lists in commit messages**: When generating commit messages, structure the body as nested lists (e.g., top-level bullets for major changes, indented sub-bullets for details or rationale) to keep the "what" and "why" clear and scannable.

### How to Help Users

- For **build questions**, point users to `./devops.sh printed` (or `./devops.ps1 printed` on Windows) for the English workflow and `./devops.sh translate` for the Traditional Chinese workflow, and reference the relevant sections in `README.md`. All builds run inside the Docker container.
- For **workflow changes**, favor solutions that:
  - Maintain plain-text, Git-friendly files.
  - Keep configuration in YAML and `zh-tw.ini` rather than ad-hoc shell commands.
- For **dependency and version questions**, explain that:
  - All toolchains (Pandoc, LaTeX, etc.) are provided by the `dalibo/pandocker` Docker container.
  - A derived image (`pandocker-with-tools:latest`) is automatically built from `Dockerfile` on first use, adding `jq` and `curl` for translation scripts.
  - No local installation is required; Docker handles all dependencies.
  - The `./devops.sh deps` operation is only for local development/testing and is not needed when using Docker.
  - The container images include all necessary tools pre-configured and ready to use.
- For **new languages or targets**, edit `zh-tw.ini`'s values (or replace the file, keeping the same key names) rather than editing `devops.sh` itself, and update both `README.md` and this `AGENTS.md` accordingly if the interface changes.


