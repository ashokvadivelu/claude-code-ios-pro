---
description: Create an implementation plan for a feature using Opus + ultrathink — read-only, no code written
argument-hint: <feature-name>
allowed-tools: Read, Grep, Glob, Write, WebSearch
model: claude-opus-4-5-20250929
---

# Plan Feature: $ARGUMENTS

You are planning the implementation of: **$ARGUMENTS**

Use **ultrathink** for this. The output is a written plan, not code.

## Steps

1. **Read context**:
   - The project's `CLAUDE.md` (architecture, conventions)
   - `docs/PRD.md` if it exists
   - `docs/specs/$ARGUMENTS.md` if it exists
   - The existing module structure (`Glob` to map the codebase)
2. **Identify integration points**: which existing modules will this touch? What does it depend on? What new public API surfaces?
3. **Propose the implementation in phases**:
   - Phase 0: scaffolding (new files, target membership, dependencies)
   - Phase 1: data layer (models, persistence, networking)
   - Phase 2: domain layer (use cases, business logic)
   - Phase 3: presentation layer (views, viewmodels, navigation)
   - Phase 4: tests
   - Phase 5: integration with existing flows
4. **Call out risks and unknowns** — what could derail this? What needs a design decision?
5. **Estimate complexity** per phase (S / M / L / XL — not hours)

## Output

Write the plan to `docs/tasks/$ARGUMENTS-plan.md`:

```markdown
# Plan: $ARGUMENTS

**Status:** Draft
**Created:** <today>

## Goal
<one paragraph>

## Existing context
<files / modules that this touches>

## Phases
### Phase 0 — Scaffolding (S)
- [ ] ...

### Phase 1 — Data layer (M)
- [ ] ...

[continue …]

## Risks and unknowns
- ...

## Open decisions
- [ ] <decision needed and from whom>

## Done when
- [ ] all acceptance criteria from spec met
- [ ] tests pass with ≥80% coverage on new code
- [ ] no new SwiftLint violations
- [ ] no new force-unwraps
```

**Do not write any implementation code in this command. This is planning only.** When the plan is approved, the user will invoke the implementation in a separate session.
