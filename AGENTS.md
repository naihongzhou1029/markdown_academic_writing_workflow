# Agent Guide for This Repository

This file provides guidance to AI agents (like Claude Code, Gemini CLI, etc.) when working with code in this repository.

## Project Overview

Remarcademic Writing Framework — a self-contained, reproducible academic writing pipeline. Write in Markdown (`paper.md`), build fully typeset PDFs with citations, bibliography, cross-references, and CJK support via Pandoc + XeLaTeX inside Docker.

The manuscript (`paper.md`) is a Traditional Chinese thesis on knowledge extraction from game design specs using generative AI.

## Build Commands

All builds run inside Docker (`pandocker-with-tools:latest`). Never call `pandoc` or `xelatex` directly.

```bash
./devops.sh              # Default: build printed version (cover + paper merged)
./devops.sh pdf          # Build main paper PDF only
./devops.sh cover        # Build cover page PDF only
./devops.sh printed      # Build merged cover + paper
./devops.sh zh_tw        # Translate to Traditional Chinese + build (requires .api_key)
./devops.sh ref-list     # Extract reference list from PDF and copy to clipboard
./devops.sh toc-list     # Extract Table of Contents from PDF and copy to clipboard
./devops.sh clean        # Remove all generated files
./devops.sh deps         # Show dependency info (local dev only)
```

Windows: use `./devops.ps1` with the same targets.

VS Code/Cursor: `Cmd+Shift+B` runs `devops.sh pdf` via `.vscode/tasks.json`.

## Architecture

### Build Pipeline

`paper.md` (Markdown + YAML) → Mermaid preprocessing → font detection → Pandoc (citeproc + pandoc-crossref) → LaTeX → CSL post-processing → XeLaTeX (2 passes) → PDF → optional cover merge

### Key Files

| File | Role |
|------|------|
| `paper.md` | Manuscript + all build config (YAML frontmatter is the single source of truth) |
| `devops.sh` / `devops.ps1` | Build orchestration (manages Docker, runs pipeline) |
| `Dockerfile` | Extends `dalibo/pandocker:latest-full` with jq, curl, Node.js, mermaid-cli |
| `bibliography.bib` | BibTeX bibliography (managed via Zotero + Better BibTeX) |
| `chicago-author-date.csl` | Citation style |
| `cover_page.tex` | LaTeX cover page |
| `tools/` | Helper scripts (mermaid rendering, translation, font detection, validation) |
| `wiki/` | Research notes, literature references, and PDFs |

### Translation Pipeline (`zh_tw` target)

Uses Gemini LLM (`LLM_MODEL` in `devops.sh`) with API key from `.api_key` file. Pipeline: translate → AI-powered validation/fix → font post-processing → same build pipeline → output in `zh_tw/`.

### PaddleOCR Subproject (`solutions/paddlepaddle/`)

Separate tool for OCR-based document analysis. Config in `profile.yaml`, scripts `segment.py` and `describe.py`.

## Featured Workflows

- **Mermaid Support**: Use `mermaid` code blocks in Markdown; the build pipeline automatically renders them to high-quality PNGs in the `images/` directory.
- **Automated Date Injection**: The date on the cover page and thesis is dynamically injected during the build process, eliminating the need for manual updates.
- **Cross-References**: Use `pandoc-crossref` syntax (e.g., `{#fig:id}` and `@fig:id` or `{#tbl:id}` and `@tbl:id`) to automatically handle figure and table numbering.

## Conventions

- `paper.md` YAML metadata is the single source of truth for document config. Do not restructure without explicit request.
- Preserve build target names (`pdf`, `cover`, `printed`, `zh_tw`, `deps`, `clean`).
- `.api_key` is a secret — never hardcode or log API keys.
- All scripts assume Linux/bash inside Docker.
- Commit messages: Conventional Commits, structured bodies with nested lists, bilingual (Traditional Chinese + English).
- Update `README.md` and `AGENTS.md` if changing build commands, translation behavior, or Docker requirements.
- When adding new language targets, follow the `zh_tw` pattern.

## Cursor Skills

| Skill | Purpose |
|-------|---------|
| `paste-crossref-image` | Save clipboard image to `images/`, insert Pandoc figure with `pandoc-crossref` label |
| `convert-conversation-figure` | Replace conversation screenshot with styled blockquote (OCR/vision transcription) |
