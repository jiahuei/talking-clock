# Approach validation guidance and lint workflow

## Summary

- Added approach-validation and reviewer guidance to the complete iOS agent guide, preserving its project-specific instructions and alarm invariants.
- Aligned the existing push-only lint workflow with agent-game: pinned checkout/setup-node actions, Node 24, read-only permissions, cancellation of superseded runs, and a two-minute timeout.
- Retained the pinned Prettier 3.8.3 documentation/configuration check and the archived prototype exclusion.

## Verification

- `npx --yes prettier@3.8.3 --write AGENTS.md .github/workflows/lint.yml`: passed.
- `npx --yes prettier@3.8.3 --check '**/*.md' '.github/**/*.yml' .prettierrc`: passed.
- `npm exec --yes --package=node@24 --package=prettier@3.8.3 -- prettier --check '**/*.md' '.github/**/*.yml' .prettierrc`: passed under Node 24.
- An initial nested `npm exec --yes --package=node@24 -- npx --yes prettier@3.8.3 ...` attempt failed to resolve the executable; the explicit package invocation above passed.
- Python YAML/content assertions: passed; verified push-only triggering, branch coverage, permissions, timeout, Node version, formatter command, preservation of existing main-branch guidance, and no archive changes.
- `git diff --check` and `git diff --cached --check`: passed.
- `git diff --name-only --diff-filter=U`: empty; all merge conflicts resolved.
- Application tests/builds are not applicable to these guidance and workflow changes; the new app's implementation manifests do not exist yet.
