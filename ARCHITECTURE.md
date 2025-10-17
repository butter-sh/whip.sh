# whip.sh in the hammer.sh Ecosystem

```
┌────────────────────────────────────────────────────────────────┐
│                         hammer.sh                               │
│                   Project Generator CLI                         │
└────────────────────────────────────────────────────────────────┘
                              │
                              │ generates projects from
                              │
         ┌────────────────────┼────────────────────┐
         │                    │                    │
         ▼                    ▼                    ▼
    ┌─────────┐          ┌─────────┐         ┌─────────┐
    │  arty   │          │  whip   │   ...   │  judge  │
    │ Library │          │ Release │         │ Testing │
    │ Manager │          │ Manager │         │Framework│
    └─────────┘          └─────────┘         └─────────┘
         │                    │                    │
         │                    │                    │
         │                    ▼                    │
         │            ┌──────────────┐            │
         │            │ whip.sh Core │            │
         │            └──────────────┘            │
         │                    │                    │
         │       ┌────────────┼────────────┐      │
         │       │            │            │      │
         │       ▼            ▼            ▼      │
         │  ┌─────────┐  ┌────────┐  ┌────────┐ │
         │  │ Version │  │Changelog│  │  Hooks │ │
         │  │  Mgmt   │  │  Gen    │  │  Mgmt  │ │
         │  └─────────┘  └────────┘  └────────┘ │
         │       │            │            │      │
         │       └────────────┼────────────┘      │
         │                    │                    │
         └────────────────────┼────────────────────┘
                              │
                              ▼
                     ┌────────────────┐
                     │  Monorepo      │
                     │  Support       │
                     └────────────────┘
                              │
              ┌───────────────┼───────────────┐
              │               │               │
              ▼               ▼               ▼
         ┌─────────┐     ┌─────────┐    ┌─────────┐
         │lib-core │     │lib-utils│    │app-main │
         │arty.yml │     │arty.yml │    │arty.yml │
         └─────────┘     └─────────┘    └─────────┘
```

## Workflow Diagram

```
Developer Workflow with whip.sh
═══════════════════════════════

1. Generate Project
   ┌─────────────────────────┐
   │ hammer whip my-project  │
   └─────────────────────────┘
              │
              ▼
   ┌─────────────────────────┐
   │   Generated Project     │
   │  with whip.sh inside    │
   └─────────────────────────┘
              │
              ▼
2. Development
   ┌─────────────────────────┐
   │  whip hooks install     │ ← Install pre-commit validation
   └─────────────────────────┘
              │
              ▼
   ┌─────────────────────────┐
   │   Write Code            │
   │   Make Changes          │
   └─────────────────────────┘
              │
              ▼
   ┌─────────────────────────┐
   │   git commit            │ ← Hooks validate automatically
   └─────────────────────────┘
              │
              ▼
3. Release
   ┌─────────────────────────┐
   │ whip release patch      │ ← One command
   └─────────────────────────┘
              │
      ┌───────┴───────┐
      │               │
      ▼               ▼
 ┌─────────┐    ┌──────────┐
 │ Version │    │Changelog │
 │ Bumped  │    │ Updated  │
 └─────────┘    └──────────┘
      │               │
      └───────┬───────┘
              ▼
      ┌──────────────┐
      │  Git Commit  │
      └──────────────┘
              │
              ▼
      ┌──────────────┐
      │   Git Tag    │
      │   v1.0.1     │
      └──────────────┘
              │
              ▼
      ┌──────────────┐
      │  Git Push    │
      │ (commits +   │
      │   tags)      │
      └──────────────┘
              │
              ▼
          ┌───────┐
          │ Done! │
          └───────┘
```

## Release Cycle Detail

```
whip.sh Release Process
═══════════════════════

Input: whip release [major|minor|patch]
   │
   ├─> Check Dependencies (yq, git)
   │
   ├─> Check Git Repository
   │
   ├─> Check Uncommitted Changes
   │
   ├─> Parse Current Version (arty.yml)
   │   Example: 1.2.3
   │
   ├─> Calculate New Version
   │   ├─ major: 2.0.0
   │   ├─ minor: 1.3.0
   │   └─ patch: 1.2.4
   │
   ├─> Update arty.yml
   │   Using: yq eval '.version = "X.Y.Z"' -i arty.yml
   │
   ├─> Generate Changelog
   │   ├─ Get previous tag
   │   ├─ Extract commits since tag
   │   ├─ Format in markdown
   │   └─ Prepend to CHANGELOG.md
   │
   ├─> Create Git Commit
   │   Message: "chore: release version X.Y.Z"
   │   Files: arty.yml, CHANGELOG.md
   │
   ├─> Create Annotated Tag
   │   Tag: vX.Y.Z
   │   Message: "Release version X.Y.Z"
   │
   ├─> Push to Remote
   │   ├─ git push (commits)
   │   └─ git push origin vX.Y.Z (tag)
   │
   └─> Success! 🎉
```

## Monorepo Structure

```
Project Structure with Monorepo Support
════════════════════════════════════════

monorepo/
├── whip.sh                    ← Master release tool
├── arty.yml                   ← Optional root config
│
├── lib-core/                  ← Project 1
│   ├── arty.yml              version: 1.0.0
│   ├── src/
│   └── tests/
│
├── lib-utils/                 ← Project 2
│   ├── arty.yml              version: 2.1.5
│   ├── src/
│   └── tests/
│
├── app-frontend/              ← Project 3
│   ├── arty.yml              version: 0.9.0
│   ├── src/
│   └── tests/
│
└── app-backend/               ← Project 4
    ├── arty.yml              version: 1.2.3
    ├── src/
    └── tests/

Commands:
─────────
whip mono list
  → lib-core
  → lib-utils
  → app-frontend
  → app-backend

whip mono version
  → lib-core: 1.0.0
  → lib-utils: 2.1.5
  → app-frontend: 0.9.0
  → app-backend: 1.2.3

whip mono bump patch "lib-*"
  → lib-core: 1.0.0 → 1.0.1
  → lib-utils: 2.1.5 → 2.1.6

whip mono status
  → Shows git status for each project
```

## Hook System

```
Git Hooks Architecture
══════════════════════

.whip/hooks/              ← Hook templates directory
├── pre-commit           ← Default pre-commit hook
├── pre-push             ← Custom pre-push hook
└── commit-msg           ← Custom commit-msg hook

    │
    │ whip hooks install
    │
    ▼

.git/hooks/              ← Active git hooks
├── pre-commit           ← Copied from .whip/hooks/
├── pre-push
└── commit-msg

Pre-commit Hook Flow:
─────────────────────

Developer: git commit -m "message"
    │
    ▼
┌────────────────────┐
│  pre-commit hook   │  ← Runs automatically
└────────────────────┘
    │
    ├─> Find staged .sh files
    │
    ├─> For each file:
    │   ├─> bash -n file.sh        ← Syntax check
    │   │   ├─ Pass: continue
    │   │   └─ Fail: show error
    │   │
    │   └─> shellcheck file.sh     ← Static analysis
    │       ├─ Available: run
    │       └─ Not available: skip
    │
    ├─> All checks passed?
    │   ├─ Yes: Allow commit ✓
    │   └─ No: Block commit ✗
    │
    └─> Result

Example Output:
───────────────
Running pre-commit checks...
Checking: script1.sh
Checking: script2.sh
ERROR: Syntax error in script2.sh
line 42: unexpected token 'fi'
Please fix the errors before committing
```

## Integration Points

```
whip.sh Integration with Ecosystem
═══════════════════════════════════

┌──────────────┐
│   hammer.sh  │  Generates whip projects
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   whip.sh    │
└──────┬───────┘
       │
       ├─────────> arty.yml     (reads/writes version)
       │
       ├─────────> git          (commits, tags, pushes)
       │
       ├─────────> yq           (YAML processing)
       │
       ├─────────> shellcheck   (optional validation)
       │
       └─────────> CHANGELOG.md (generates/updates)

Via arty.sh:
────────────
arty.yml defines:
  scripts:
    release: "bash whip.sh release"

Then use:
  $ arty release     ← Executes whip.sh

Complete Flow:
──────────────
Developer
    │
    ├─> Uses hammer.sh to generate project
    │   $ hammer whip my-app
    │
    ├─> Uses arty.sh to manage dependencies
    │   $ arty deps
    │
    ├─> Uses whip.sh to manage releases
    │   $ ./whip.sh release
    │   OR
    │   $ arty release
    │
    └─> Hooks automatically validate code
```

## Command Flow Diagram

```
whip.sh Command Structure
═════════════════════════

whip
 ├─ release [major|minor|patch]
 │   └─> Full release workflow
 │
 ├─ version
 │   └─> Show current version
 │
 ├─ bump <type>
 │   └─> Update version only
 │
 ├─ changelog [from] [to]
 │   └─> Generate changelog
 │
 ├─ tag <version>
 │   └─> Create git tag
 │
 ├─ hooks
 │   ├─ install
 │   │   └─> Copy hooks to .git/hooks/
 │   ├─ uninstall
 │   │   └─> Remove hooks from .git/hooks/
 │   └─ create
 │       └─> Create hook templates
 │
 └─ mono
     ├─ list [pattern]
     │   └─> Find arty.yml projects
     ├─ version [pattern]
     │   └─> Show all versions
     ├─ bump <type> [pattern]
     │   └─> Bump all versions
     └─ status [pattern]
         └─> Git status all projects
```

## Feature Comparison

```
whip.sh vs Manual Release Process
══════════════════════════════════

Manual Process:                 With whip.sh:
──────────────                 ─────────────

1. Edit arty.yml               whip release patch
   (update version)               │
   ↓                              ↓
2. Generate CHANGELOG          [All automated]
   (from git log)                 │
   ↓                              ↓
3. git add files               Done! 🎉
   ↓
4. git commit -m "..."
   ↓
5. git tag -a vX.Y.Z
   ↓
6. git push
   ↓
7. git push --tags
   ↓
8. Done!

Time: 5-10 minutes            Time: 5 seconds
Error-prone: Yes              Error-prone: No
Consistent: No                Consistent: Yes
```

## Use Cases

```
Common Use Cases for whip.sh
════════════════════════════

1. Single Project Release
   ──────────────────────
   my-project/
   ├── arty.yml
   └── whip.sh
   
   $ ./whip.sh release patch
   
   Result: v1.0.1 released

2. Library with Documentation
   ──────────────────────────
   my-lib/
   ├── arty.yml
   ├── whip.sh
   └── docs/
   
   $ ./whip.sh release minor
   $ ./whip.sh changelog > docs/HISTORY.md
   
   Result: v1.1.0 + docs updated

3. Monorepo Management
   ───────────────────
   monorepo/
   ├── lib-a/arty.yml
   ├── lib-b/arty.yml
   └── whip.sh
   
   $ ./whip.sh mono bump patch
   
   Result: All libs updated

4. CI/CD Pipeline
   ──────────────
   .github/workflows/release.yml:
     - run: whip release ${{ github.event.inputs.version }}
   
   Result: Automated releases

5. Pre-release Testing
   ───────────────────
   $ ./whip.sh release minor --no-push
   $ ./run-tests.sh
   $ git push && git push --tags
   
   Result: Test before publishing
```

This visual summary shows how whip.sh integrates into the hammer.sh ecosystem and provides comprehensive release management capabilities!
