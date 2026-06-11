---
description: Nuke DerivedData and SPM caches for the current project — last resort for inexplicable build errors
allowed-tools: Bash, Read, Glob
---

# Clean Derived Data

When the error makes no sense and a clean build doesn't help, this is the "have you tried turning it off and on again" of Xcode.

## Steps

1. Confirm with the user before running — this *will* trigger a slow next build.
2. Identify the project name from `*.xcodeproj` or `*.xcworkspace` in the current directory.
3. Run:
   ```bash
   # Project-specific DerivedData
   rm -rf ~/Library/Developer/Xcode/DerivedData/<project>-*

   # SPM caches (if Package.swift or Package.resolved present)
   rm -rf ~/Library/Caches/org.swift.swiftpm
   rm -rf .build  # local SPM build dir

   # CocoaPods (if Podfile present)
   rm -rf Pods
   pod install
   ```
4. Report what was cleaned and recommend running `/build` next.

Do **not** clean global Xcode caches (`~/Library/Caches/com.apple.dt.Xcode`) unless the user explicitly asks — they're shared across all projects and you'll slow down everything else they're working on.
