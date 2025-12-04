## Agent Guide for This Repository

This project is a worked example of a Markdown → Pandoc → LaTeX academic writing workflow with an optional LLM-powered translation pipeline. The **primary conceptual and user-facing documentation is in `README.md`**; always read that file first to understand the workflow, tools, and targets.

### Project Intent

- **Main goal**: Demonstrate a sustainable, plain-text academic workflow using `paper.md`, Pandoc, LaTeX, Zotero/BBT, and a `Makefile`-driven build.
- **Secondary goal**: Show how to translate the manuscript and cover into Traditional Chinese using LLM-based scripts and rebuild PDFs from the translated sources.

### Key Entry Points

- **`README.md`**: High-level description of the workflow, toolchain, build commands (`make`, `make zh_tw`), and the translation pipeline.
- **`paper.md`**: Primary English manuscript; contains YAML metadata that configures Pandoc, citations, cross-references, and typesetting options.
- **`Makefile`**:
  - Default target: `printed` (English cover + paper merged for printing).
  - Translation target: `zh_tw` (translates and builds the Traditional Chinese PDFs under `zh_tw/`).
- **`tools/` scripts**: OS-specific helpers for font detection, translation, post-processing, logo download, PDF merging, and dependency installation.

### Constraints and Conventions for Agents

- **Do not change the overall structure** of `paper.md`’s YAML metadata or its role as the single source of truth for document configuration, unless explicitly asked.
- **Preserve target names and roles** in the `Makefile` (`pdf`, `cover`, `printed`, `zh_tw`, `deps`, `clean`) to avoid breaking existing workflows or documentation.
- **Keep `README.md` and `AGENTS.md` consistent** with any changes to:
  - Build commands and primary targets.
  - Translation pipeline behavior (`zh_tw` directory, `LLM_MODEL`, `.api_key` usage).
- As a rule of thumb: **if you add or change Make targets, translation scripts, API key usage, or primary documentation**, update this file accordingly.
- **Be cautious with translation scripts**:
  - Treat `.api_key` as a secret; don’t hardcode keys or log them.
  - Keep language directions and font assumptions (e.g., Traditional Chinese fonts) correct when modifying scripts.
 - **Sync plan progress to Markdown plan files**: When using plan-style workflows or multi-step tasks, always include a final step to sync the plan’s current state into the relevant Markdown plan file (e.g., under a `plans/` directory), so that progress is persistently recorded outside the transient agent context.

### Commit Message Conventions for Agents

- **Use nested lists in commit messages**: When generating commit messages, structure the body as nested lists (e.g., top-level bullets for major changes, indented sub-bullets for details or rationale) to keep the "what" and "why" clear and scannable.

### How to Help Users

- For **build questions**, point users to `make` for the English workflow and `make zh_tw` for the Traditional Chinese workflow, and reference the relevant sections in `README.md`.
- For **workflow changes**, favor solutions that:
  - Maintain plain-text, Git-friendly files.
  - Keep configuration in YAML and Make targets rather than ad-hoc shell commands.
- For **dependency and version questions on Linux**, explain that:
  - `make deps` will ensure required CLI tools are installed.
  - `tools/deps-linux.sh` will **pin Pandoc to version 3.1.8** (via an official `.deb` for the current architecture) so it stays aligned with the `pandoc-crossref` filter used in this workflow.
  - This pin is specifically to guarantee **correct cross‑referencing and page layout for the Table of Contents, List of Figures, and List of Tables**, which depend on `pandoc-crossref` behaving consistently with the Pandoc API.
  - Changes to the pinned Pandoc version or filter expectations must be reflected in `README.md` and this guide.
- For **new languages or targets**, mirror the existing `zh_tw` pattern (directory layout, Make targets, translation/post-processing steps) and update both `README.md` and this `AGENTS.md` accordingly.


