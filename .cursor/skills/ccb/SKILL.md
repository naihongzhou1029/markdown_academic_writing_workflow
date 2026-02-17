---
name: ccb
description: Applies CCB (Concise, Conventional and Bilingual) commit message standards. Use when composing, preparing, or reviewing commit messages, or when the user asks to commit with "ccb" or follow commit conventions.
---

# Commit Message Conventions (CCB)

Apply these conventions to any commit message you generate or suggest. When committing on the user's behalf, write the message to `.git/COMMIT_EDITMSG` and run `git commit -F .git/COMMIT_EDITMSG` (or tell the user to run it).

## Conventional commits

- Types: `feat`, `fix`, `chore`, `docs`, `test`, `refactor`, `perf`, `build`, `ci`, `revert`, `style`
- Prefer scoped subjects when helpful, e.g. `feat(game): ...`, `fix(build): ...`

## Subject line

- Imperative mood (e.g., `add`, `fix`, `refactor`)
- Max 72 characters, no trailing period
- Capture the purpose of the change, not just the mechanical action

## Body

- Include a body when the change is non-trivial or alters behavior meaningfully.
- Explain what changed (high level), why (intent, bug, impact), and any risks or follow-ups.
- Avoid restating file lists that `git diff --stat` already shows.

## Bilingual output and export

When preparing or composing a commit message:

1. **Chat output**: First output the full message in Traditional Chinese, then a single blank line, then the full English duplicate (same structure and meaning).
2. **File export**: Write to `.git/COMMIT_EDITMSG` the same bilingual content (Traditional Chinese, blank line, English). The user can then run `git commit -F .git/COMMIT_EDITMSG`.

## Content hygiene

- Do not include IDE-specific deep links or protocol URLs (e.g. `cci://...`).
- Refer to files by plain names or inline code (e.g. `paper.md`).
- Avoid generic subjects like `update code` or `fix stuff`.

## When to use

- User asks to commit with "ccb" or "commit message conventions"
- Composing or preparing a commit message
- Reviewing or correcting commit message style
