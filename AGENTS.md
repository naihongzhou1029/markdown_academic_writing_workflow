## Agent Guide for This Repository

This file provides specific instructions and constraints for AI agents (like yourself) working on this repository. For general project information, goals, and build instructions, always refer to `README.md` first.

### Constraints and Conventions

- **Single Source of Truth**: Do not change the overall structure of `paper.md`’s YAML metadata or its role as the single source of truth for document configuration, unless explicitly asked.
- **Makefile Preservation**: Preserve target names and roles in the `Makefile` (`pdf`, `cover`, `printed`, `zh_tw`, `deps`, `clean`) to avoid breaking existing workflows.
- **Consistency**: Keep `README.md` and this `AGENTS.md` updated if you change:
  - Build commands or primary targets.
  - Translation pipeline behavior (`zh_tw` directory, `LLM_MODEL`, `.api_key` usage).
  - Docker container usage and requirements.
- **Secrets Management**: Treat `.api_key` as a secret. Never hardcode keys or log them in outputs.
- **Environment**: All scripts are designed to run inside the Docker container (`pandocker-with-tools`). Ensure any new or modified scripts use Linux-compatible commands (bash, standard Unix utilities).
- **Validation Pipeline**: The translation pipeline includes an AI-powered validation step (`tools/validate-and-fix-translated-md.sh`). When modified, ensure it continues to detect and fix formatting errors while preserving translation content.
- **Plan Persistence**: When using multi-step tasks or plan-style workflows, sync the plan’s current state into a relevant Markdown file (e.g., under a `plans/` directory) to record progress persistently.

### Commit Message Conventions

- **Structured Bodies**: Use nested lists in commit messages. Structure the body with top-level bullets for major changes and indented sub-bullets for details or rationale to improve scannability.
**Bilingual Messages**: Attach traditional Chinese after the original one.

### Operational Guidance

Builds: Always prefer ./devops.sh for builds on Linux/macOS/WSL, or ./devops.ps1 on Windows PowerShell (default target is help). This ensures all work runs inside the pandocker-with-tools Docker image.
- **Dependencies**: Remind users that the toolchain is containerized. The `make deps` target is for local development only and should not be recommended for standard usage.
- **Expansion**: When adding support for new languages or targets, follow the pattern established by the `zh_tw` directory and its associated Make targets and scripts.

### Cursor Agent CLI Skills

- **Convert conversation figure**: Use the skill in `.cursor/skills/convert-conversation-figure/` when asked to replace a conversation screenshot with a styled blockquote in Markdown. The full workflow is also documented in `.agent/workflows/convert-conversation-figure.md`.
