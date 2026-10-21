# iOS build triggers

## Summary

Changed the iOS workflow to run on pushes to `main` and tags matching `v*`, while retaining the pull-request trigger. Documented the build trigger policy in the development guide.

## Verification

- Confirmed the workflow event block matches the requested branch and tag filters.
- Application tests and builds are not applicable to this workflow-trigger change.
- `npx --yes prettier@3.8.3 --check '**/*.md' '.github/**/*.yml' .prettierrc`: passed.
- `git diff --check`: passed.
