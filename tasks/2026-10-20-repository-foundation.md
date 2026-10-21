# Repository foundation

## Summary

Preserved the existing move into `v0/` and adapted Travel Plan's repository workflow for native iOS development. Added specifications, an implementation plan with a source review, agent instructions, signing/build exclusions, and pinned documentation formatting CI. Replaced prototype-era release claims with the actual implementation boundary.

## Verification

- Compared every moved file with `git show HEAD:<original path>`: byte-for-byte identical.
- App build/tests are deferred until the implementation PR; the foundation adds no new runtime code.
- `npx --yes prettier@3.8.3 --check '**/*.md' '.github/**/*.yml' .prettierrc`: passed.
- `git diff --check`: passed.
