# {{PROJECT_NAME}}

> Replace `{{PROJECT_NAME}}` and the placeholders below with your project's actual values.
> This file lives at the repo root (`./CLAUDE.md`) and is committed to git. It overrides anything in `~/.claude/CLAUDE.md`.

## Quick reference

- **Platform:** iOS {{MIN_IOS_VERSION}}+ {{ADDITIONAL_PLATFORMS}}
- **Language:** Swift {{SWIFT_VERSION}} ({{CONCURRENCY_MODE}} concurrency)
- **UI framework:** {{UI_FRAMEWORK}} <!-- SwiftUI | UIKit | mixed -->
- **Architecture:** {{ARCHITECTURE}} <!-- MVVM-Observable | Clean Architecture | TCA | MVC -->
- **Persistence:** {{PERSISTENCE}} <!-- SwiftData | Core Data | Realm | none -->
- **Package manager:** {{PACKAGE_MANAGER}} <!-- SPM | CocoaPods | Carthage | mixed -->
- **CI:** {{CI_PLATFORM}} <!-- GitHub Actions | Bitrise | Xcode Cloud | etc. -->

## Project structure

```
{{PROJECT_NAME}}/
├── App/                       # App entry point, AppDelegate, SceneDelegate
├── Features/                  # Feature modules — one folder per feature
│   └── <FeatureName>/
│       ├── Views/             # SwiftUI views
│       ├── ViewModels/        # @Observable view models
│       ├── Models/            # Local DTOs / view state
│       └── Coordinator.swift  # Navigation (when non-trivial)
├── Core/                      # Cross-feature primitives
│   ├── Networking/
│   ├── Persistence/
│   ├── Logging/
│   └── Extensions/
├── DesignSystem/              # Reusable UI components, tokens
├── Resources/                 # Assets, Localizations, Info.plist
└── Tests/                     # Swift Testing tests, mirrors Features/
```

## Architecture decisions

<!-- Document the key decisions other devs (and Claude) need to know -->

### Navigation
{{NAVIGATION_PATTERN}}
<!-- Example: "NavigationStack with type-safe enum routes. Each feature owns a Coordinator that holds NavigationPath." -->

### State management
{{STATE_MANAGEMENT}}
<!-- Example: "Per-feature @Observable view models. Global state via App-level Environment for: AuthSession, FeatureFlags, AnalyticsClient." -->

### Networking
{{NETWORKING_APPROACH}}
<!-- Example: "URLSession + async/await. Each feature defines a Repository protocol in Domain, implemented in Data. JSON via Codable." -->

### Persistence
{{PERSISTENCE_APPROACH}}
<!-- Example: "SwiftData for user data, Keychain for credentials, UserDefaults for non-sensitive preferences only." -->

### Dependency injection
{{DI_APPROACH}}
<!-- Example: "Constructor injection. Composition root in AppDelegate creates one CompositionRoot that holds all dependencies." -->

## Coding standards

- Follow [Apple's Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
- SwiftLint config: `.swiftlint.yml` (enforced by hook)
- SwiftFormat config: `.swiftformat` (enforced by hook)
- File length soft-limit: 300 lines
- Function length soft-limit: 40 lines
- No force-unwraps (`!`) without a comment
- No `print()` — use `Logger` (`Core/Logging/Logger.swift`)

## Testing

- **Framework:** Swift Testing for new code, XCTest for legacy
- **Coverage target:** 80% on business logic (`Features/*/ViewModels/`, `Core/`)
- **No network in unit tests** — `URLProtocol` mocks live in `Tests/TestKit/MockURLProtocol.swift`
- **Snapshot tests** for design system components — `swift-snapshot-testing`
- **UI tests** only for critical journeys: {{CRITICAL_JOURNEYS}}

## Security

- Credentials → Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- High-value items → Keychain with `.biometryCurrentSet` access control
- Symmetric keys → Secure Enclave when feasible (`kSecAttrTokenIDSecureEnclave`)
- Production endpoints → certificate pinning (see `Core/Networking/Pinning.swift`)
- No PII in logs — use `os.Logger` with `.private(_)` modifier on sensitive fields
- App Transport Security: no domain exceptions in production builds

## Build and run

- Build: `/build` (uses XcodeBuildMCP)
- Test: `/test`
- Run on simulator: `/run`
- Review changes before PR: `/review`
- Security audit: `/security-audit` (before each release)

## Subagents available

All eight global subagents apply here. Additionally, this project defines:

<!-- Add any project-specific subagents in .claude/agents/ and list them here -->
- *(none yet)*

## Memory imports

<!--
Uncomment these once the referenced files exist in your repo.
Each @import loads that file's contents into context every turn, so use sparingly —
three to five focused docs is the sweet spot.
-->
<!-- @import docs/ARCHITECTURE.md -->
<!-- @import docs/CONVENTIONS.md -->
<!-- @import docs/API.md -->
<!-- @import docs/RELEASE_PROCESS.md -->

## DO NOT (this project specifically)

<!-- Project-specific don'ts. Examples: -->
- Do not introduce UIKit views in new code (we are SwiftUI-only)
- Do not add new dependencies without a discussion in #ios-eng
- Do not bypass the analytics wrapper — always go through `AnalyticsClient`
- {{PROJECT_SPECIFIC_DO_NOTS}}
