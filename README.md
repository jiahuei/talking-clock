# Talking Clock

A native iOS alarm clock that announces the alarm time.

This foundation preserves the original interval-clock prototype in [`v0/`](v0/) and specifies a new SwiftUI app using iOS 26 AlarmKit. The new application is the next implementation milestone.

- [Product specification](docs/SPEC.md)
- [Implementation plan and v0 review](docs/implementation-plan.md)
- [Swift conventions](docs/CONVENTIONS.md)
- [Development guide](QUICKSTART.md)
- [Agent instructions](AGENTS.md)

The rewrite targets iOS 26+ and Xcode 26+. It will use system-managed alarms and generated spoken audio, without accounts, tracking, or purchases.
