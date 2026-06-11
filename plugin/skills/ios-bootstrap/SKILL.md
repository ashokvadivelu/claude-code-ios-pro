---
name: ios-bootstrap
description: Scaffolds a new iOS feature module following MVVM + @Observable conventions, with View, ViewModel, Coordinator, dependencies protocol, fixtures, and Swift Testing test target. Use when the user asks to "add a new feature", "scaffold X", "create a new module", or "set up a new screen".
license: MIT
---

# iOS Bootstrap

Generates a complete feature module skeleton ready for development.

## When to use

Triggered when the user wants to start a new feature and the codebase follows the conventions in `~/.claude/CLAUDE.md` (MVVM + `@Observable`, SwiftUI, Swift Testing). If the project uses a different pattern (TCA, MVC), match the project's pattern instead — read the existing module structure first.

## What it produces

For a feature called `Profile`, in a project structured as `Sources/Features/<FeatureName>/`:

```
Sources/Features/Profile/
├── ProfileView.swift           # SwiftUI view, previews, accessibility
├── ProfileViewModel.swift      # @Observable, async actions, dependency injection
├── ProfileCoordinator.swift    # Navigation surface (optional, when navigation is non-trivial)
├── ProfileDependencies.swift   # Protocol describing what the VM needs (auth, data, etc.)
├── ProfileModels.swift         # Local DTOs / view state types
└── Fixtures.swift              # Preview / test fixtures

Tests/FeaturesTests/Profile/
├── ProfileViewModelTests.swift # Swift Testing, parameterised where useful
└── MockProfileDependencies.swift
```

## Conventions to apply

- **View** is a `struct` with a `@Bindable var viewModel: ProfileViewModel`. Body extracts subviews when >80 lines. At least three previews: success, loading, error.
- **ViewModel** is `@Observable` `final class`. State exposed as published properties. Async actions as `func ... async`. No `@MainActor` on the class — let SwiftUI infer; mark actions explicitly if they hop actors.
- **Dependencies** is a `protocol` declaring exactly what the ViewModel needs. Production conforms in the composition root.
- **Models** are `Codable, Equatable, Sendable` structs.
- **Coordinator** owns navigation state (`NavigationPath`, sheet `Item?`). Only create one if navigation is non-trivial.
- **Tests** use Swift Testing. Inject a `Mock<FeatureName>Dependencies`. Cover at minimum: initial state, happy-path action, one error path, one edge case.

## Procedure

1. **Read the existing project structure.** Use `Glob` to locate other features. Match their directory layout, naming, and architectural style. Override the defaults in this skill if the project does something different.
2. **Confirm the feature name** with the user (PascalCase, no `View` suffix — the file gets `View` appended).
3. **Generate the files** with the templates below.
4. **Wire it into the navigation** — read the top-level `RootView` / `AppView` and surface the integration point (do not modify it without confirmation).
5. **Report** what was created and the next three things the developer should do (add to scheme, add fixtures for the new model, write the failing first test).

## File templates

See `assets/` directory in this skill (if present) for full templates. Inline summaries:

### `ProfileView.swift`

```swift
import SwiftUI

struct ProfileView: View {
    @Bindable var viewModel: ProfileViewModel

    var body: some View {
        content
            .navigationTitle("Profile")
            .task { await viewModel.onAppear() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading: ProgressView()
        case .loaded(let profile): loaded(profile)
        case .error(let message): errorView(message)
        }
    }

    private func loaded(_ profile: Profile) -> some View {
        // …
    }

    private func errorView(_ message: String) -> some View {
        ContentUnavailableView("Couldn't load profile", systemImage: "exclamationmark.triangle", description: Text(message))
    }
}

#Preview("Loaded") {
    NavigationStack { ProfileView(viewModel: .preview(.loaded(.fixture))) }
}

#Preview("Loading") {
    NavigationStack { ProfileView(viewModel: .preview(.loading)) }
}

#Preview("Error") {
    NavigationStack { ProfileView(viewModel: .preview(.error("Network unreachable"))) }
}
```

### `ProfileViewModel.swift`

```swift
import Foundation
import Observation

@Observable
final class ProfileViewModel {
    enum State: Equatable {
        case loading
        case loaded(Profile)
        case error(String)
    }

    private(set) var state: State = .loading
    private let dependencies: ProfileDependencies

    init(dependencies: ProfileDependencies) {
        self.dependencies = dependencies
    }

    func onAppear() async {
        state = .loading
        do {
            let profile = try await dependencies.fetchProfile()
            state = .loaded(profile)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}

// MARK: - Previews

extension ProfileViewModel {
    static func preview(_ state: State) -> ProfileViewModel {
        let vm = ProfileViewModel(dependencies: PreviewProfileDependencies())
        vm.state = state
        return vm
    }
}
```

### `ProfileDependencies.swift`

```swift
import Foundation

protocol ProfileDependencies: Sendable {
    func fetchProfile() async throws -> Profile
}

struct PreviewProfileDependencies: ProfileDependencies {
    func fetchProfile() async throws -> Profile { .fixture }
}
```

### `ProfileViewModelTests.swift`

```swift
import Testing
@testable import MyApp

@Suite("ProfileViewModel")
struct ProfileViewModelTests {
    @Test("onAppear loads profile on success")
    func loadsOnSuccess() async {
        let sut = ProfileViewModel(dependencies: MockProfileDependencies(result: .success(.fixture)))
        await sut.onAppear()
        #expect(sut.state == .loaded(.fixture))
    }

    @Test("onAppear surfaces error on failure")
    func surfacesErrorOnFailure() async {
        let sut = ProfileViewModel(dependencies: MockProfileDependencies(result: .failure(URLError(.notConnectedToInternet))))
        await sut.onAppear()
        if case .error = sut.state { /* ok */ } else { Issue.record("expected error state") }
    }
}
```

## After generation

Tell the developer to:

1. Add the new file group to the Xcode project (if not using Tuist / XcodeGen)
2. Update the navigation entry point to push/show the new view
3. Run the test suite to confirm the skeleton compiles and passes
