<div align="center">

<img src="./icon.svg" width="100" height="100" alt="whip.sh">

# whip.sh

**Release Automation Tool**

[![Organization](https://img.shields.io/badge/org-butter--sh-4ade80?style=for-the-badge&logo=github&logoColor=white)](https://github.com/butter-sh)
[![License](https://img.shields.io/badge/license-MIT-86efac?style=for-the-badge)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.0.0-22c55e?style=for-the-badge)](https://github.com/butter-sh/whip.sh/releases)
[![butter.sh](https://img.shields.io/badge/butter.sh-whip-4ade80?style=for-the-badge)](https://butter-sh.github.io)

*Streamlined release management with semantic versioning, automated changelogs, and git workflow integration*

[Documentation](https://butter-sh.github.io/whip.sh) • [GitHub](https://github.com/butter-sh/whip.sh) • [butter.sh](https://github.com/butter-sh)

</div>

---

## Overview

whip.sh is a professional release management tool that automates version bumping, changelog generation, and git tagging for bash projects. With semantic versioning support and monorepo capabilities, it streamlines the entire release workflow.

### Key Features

- **Semantic Versioning** — Automatic version bumping (patch, minor, major)
- **Automated Changelogs** — Generate CHANGELOG.md from git commit history
- **Git Tag Creation** — Annotated tags with release metadata
- **Monorepo Support** — Manage releases across multiple projects
- **Git Hooks** — Pre-commit and pre-push validation
- **arty.yml Integration** — Reads and updates project configuration

---

## Installation

### Using arty.sh

```bash
arty install https://github.com/butter-sh/whip.sh.git
arty exec whip --help
```

### Manual Installation

```bash
git clone https://github.com/butter-sh/whip.sh.git
cd whip.sh
sudo cp whip.sh /usr/local/bin/whip
sudo chmod +x /usr/local/bin/whip
```

---

## Usage

### Version Bumping

```bash
# Bump patch version (1.0.0 -> 1.0.1)
whip bump patch

# Bump minor version (1.0.1 -> 1.1.0)
whip bump minor

# Bump major version (1.1.0 -> 2.0.0)
whip bump major

# Preview without committing
whip bump patch --dry-run
```

### Changelog Generation

```bash
# Generate CHANGELOG.md from git history
whip changelog

# Generate for specific version
whip changelog --version 1.2.0

# Update existing changelog
whip changelog --update
```

### Git Tags

```bash
# Create annotated tag for current version
whip tag

# Create tag with custom message
whip tag --message "Release v1.0.0"

# List all release tags
whip tag --list
```

### Monorepo Management

```bash
# Bump version in all projects
whip mono bump patch

# Generate changelogs for all projects
whip mono changelog

# Tag all projects
whip mono tag
```

### Git Hooks

```bash
# Install git hooks
whip hooks install

# Uninstall git hooks
whip hooks uninstall

# Show hook status
whip hooks status
```

---

## Semantic Versioning

whip.sh follows [Semantic Versioning 2.0.0](https://semver.org/):

- **MAJOR** — Incompatible API changes
- **MINOR** — Backward-compatible functionality
- **PATCH** — Backward-compatible bug fixes

### Version Format

```
MAJOR.MINOR.PATCH
  ↓     ↓     ↓
  1  .  2  .  3
```

### Bump Rules

```bash
# 1.0.0 -> 1.0.1 (bug fixes)
whip bump patch

# 1.0.1 -> 1.1.0 (new features)
whip bump minor

# 1.1.0 -> 2.0.0 (breaking changes)
whip bump major
```

---

## Changelog Generation

Automatically generates CHANGELOG.md from git commit messages:

### Commit Message Format

Use conventional commits for automatic categorization:

```
feat: add new feature
fix: resolve bug in component
docs: update README
refactor: improve code structure
test: add unit tests
chore: update dependencies
```

### Generated Changelog

```markdown
# Changelog

All notable changes to this project will be documented in this file.

## [1.2.0] - 2025-10-22

### Features
- add new authentication system
- implement caching layer

### Bug Fixes
- resolve memory leak in parser
- fix edge case in validation

### Documentation
- update installation guide
- add API reference
```

---

## Examples

### Example 1: Release Workflow

```bash
# 1. Make changes and commit
git add .
git commit -m "feat: add awesome feature"

# 2. Generate changelog
whip changelog

# 3. Bump version
whip bump minor  # 1.0.0 -> 1.1.0

# 4. Create git tag
whip tag

# 5. Push to remote
git push && git push --tags
```

### Example 2: Monorepo Release

```bash
# Release all projects
whip mono bump patch
whip mono changelog
whip mono tag

# Push everything
git push && git push --tags
```

### Example 3: Pre-Release Version

```bash
# Create pre-release
whip bump minor --pre alpha  # 1.0.0 -> 1.1.0-alpha.0

# Increment pre-release
whip bump prerelease         # 1.1.0-alpha.0 -> 1.1.0-alpha.1

# Graduate to stable
whip bump patch              # 1.1.0-alpha.1 -> 1.1.0
```

---

## Integration with arty.sh

Add whip.sh to your project:

```yaml
name: "my-project"
version: "1.0.0"

references:
  - https://github.com/butter-sh/whip.sh.git

scripts:
  release-patch: "arty exec whip bump patch && arty exec whip tag"
  release-minor: "arty exec whip bump minor && arty exec whip tag"
  release-major: "arty exec whip bump major && arty exec whip tag"
  changelog: "arty exec whip changelog"
```

Then run:

```bash
arty deps             # Install whip.sh
arty release-patch    # Create patch release
arty changelog        # Generate changelog
```

---

## Configuration

Configure whip.sh in `arty.yml`:

```yaml
whip:
  changelog:
    sections:
      feat: "Features"
      fix: "Bug Fixes"
      docs: "Documentation"
      refactor: "Refactoring"
      test: "Tests"
      chore: "Chores"

  tag:
    prefix: "v"
    message: "Release {{version}}"

  hooks:
    pre-commit:
      - lint
      - test
    pre-push:
      - test
```

---

## Git Hooks

whip.sh can install git hooks for quality control:

### Pre-Commit Hook

```bash
#!/usr/bin/env bash
# Runs before each commit

# Lint code
arty lint || exit 1

# Run tests
arty test || exit 1
```

### Pre-Push Hook

```bash
#!/usr/bin/env bash
# Runs before pushing

# Ensure version is tagged
whip tag --verify || exit 1

# Run full test suite
arty test --integration || exit 1
```

### Installation

```bash
# Install hooks
whip hooks install

# Hooks are created in .git/hooks/
# - pre-commit
# - pre-push
```

---

## Related Projects

Part of the [butter.sh](https://github.com/butter-sh) ecosystem:

- **[arty.sh](https://github.com/butter-sh/arty.sh)** — Dependency manager
- **[judge.sh](https://github.com/butter-sh/judge.sh)** — Testing framework
- **[myst.sh](https://github.com/butter-sh/myst.sh)** — Templating engine
- **[hammer.sh](https://github.com/butter-sh/hammer.sh)** — Project scaffolding
- **[leaf.sh](https://github.com/butter-sh/leaf.sh)** — Documentation generator
- **[clean.sh](https://github.com/butter-sh/clean.sh)** — Linter and formatter

---

## License

MIT License — see [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

<div align="center">

**Part of the [butter.sh](https://github.com/butter-sh) ecosystem**

*Unlimited. Independent. Fresh.*

Crafted by [Valknar](https://github.com/valknarogg)

</div>
