# Repository guidelines and lint triggers

## Summary

Replaced the shortened agent guide with Travel Plan's full engineering workflow, retaining its PR title and description format, issue-closing rules, coding guidance, and code-review/refactoring guidelines. Adapted only project-specific layout, tooling, scope, and domain constraints for the iOS app. Lint now runs only on pushes, across all branches.

## Verification

- Compared the copied PR descriptions, closing issues, code comments, code-review guidelines, and general workflow subsections with Travel Plan's current `AGENTS.md`: unchanged.
- Confirmed lint has only the `push` event and no branch filter.
- `npx --yes prettier@3.8.3 --check '**/*.md' '.github/**/*.yml' .prettierrc`: passed.
- `git diff --check`: passed.
- Application tests and builds are not applicable to these documentation and lint-trigger changes.
