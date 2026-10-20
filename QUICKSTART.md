# Development

## Original prototype

On a Mac, open `v0/TalkingClock/TalkingClock.xcodeproj`. This is the archived interval clock, not the new alarm implementation. Its background speech claims were not validated; see the [review](docs/implementation-plan.md).

## New application

The foundation PR defines the new iOS 26+ application. Build/run instructions will land with its implementation. Development requires a Mac with Xcode 26+; physical-device tests are necessary for AlarmKit sound delivery.

## Formatting

```sh
npx --yes prettier@3.8.3 --write '**/*.md' '.github/**/*.yml' .prettierrc
npx --yes prettier@3.8.3 --check '**/*.md' '.github/**/*.yml' .prettierrc
git diff --check
```
