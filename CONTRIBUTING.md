# Contributing

## Branches

Use `<type>/<short-description>`:

- `feat/` — new skills, agents, or capabilities
- `fix/` — corrections to existing config or prompts
- `docs/` — documentation-only changes
- `chore/` — dependency, model, or maintenance refreshes
- `refactor/` — restructuring without behavior change
- `test/` — test or validation changes

Keep the description lowercase and hyphenated, for example `feat/refresh-model-presets`.

## Pull requests

### Title

- Imperative, sentence case, no type prefix, no trailing period.
- Describe the whole change against the base branch, not the last commit.
- Examples: `Refresh November model presets and sync OpenCode V2 config`,
  `Add text-compress skill`.

### Description

Use [`.github/pull_request_template.md`](.github/pull_request_template.md). It must cover:

- **Summary** — what changed and why, in 1-3 sentences.
- **Changes** — grouped by area, describing the complete diff against the base
  branch.
- **Validation** — the exact commands or checks run and their results.
- **Notes** — risks, migration steps, follow-ups, or intentionally out-of-scope
  items.
- **Checklist** — complete it before requesting review.

Link related issues with `Closes #...` when the PR resolves them.

## Before opening a PR

- Run `bash setup.sh` when symlink behavior changes.
- Parse affected JSON and TOML files, and run `bash -n` on changed scripts.
- Keep secrets out of templates; use `{env:...}` or `${...}` placeholders.
- Do not add machine-specific absolute paths to tracked files.
- Keep model IDs and documentation aligned with the live catalog when a preset
  changes.
