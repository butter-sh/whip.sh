<div align="center">

# 🎯 whip.sh

**Release Cycle Management for arty.sh Projects**

[![Organization](https://img.shields.io/badge/org-butter--sh-4ade80?style=for-the-badge&logo=github&logoColor=white)](https://github.com/butter-sh)
[![License](https://img.shields.io/badge/license-MIT-86efac?style=for-the-badge)](LICENSE)
[![Build Status](https://img.shields.io/github/actions/workflow/status/butter-sh/whip.sh/test.yml?branch=main&style=flat-square&logo=github)](https://github.com/butter-sh/whip.sh/actions)
[![Version](https://img.shields.io/github/v/tag/butter-sh/whip.sh?style=flat-square&label=version&color=4ade80)](https://github.com/butter-sh/whip.sh/releases)
[![butter.sh](https://img.shields.io/badge/butter.sh-whip-22c55e?style=flat-square&logo=data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjQiIGhlaWdodD0iMjQiIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48cGF0aCBkPSJNMjEgMTZWOGEyIDIgMCAwIDAtMS0xLjczbC03LTRhMiAyIDAgMCAwLTIgMGwtNyA0QTIgMiAwIDAgMCAzIDh2OGEyIDIgMCAwIDAgMSAxLjczbDcgNGEyIDIgMCAwIDAgMiAwbDctNEEyIDIgMCAwIDAgMjEgMTZ6IiBzdHJva2U9IiM0YWRlODAiIHN0cm9rZS13aWR0aD0iMiIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2UtbGluZWpvaW49InJvdW5kIi8+PHBvbHlsaW5lIHBvaW50cz0iMy4yNyA2Ljk2IDEyIDEyLjAxIDIwLjczIDYuOTYiIHN0cm9rZT0iIzRhZGU4MCIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiLz48bGluZSB4MT0iMTIiIHkxPSIyMi4wOCIgeDI9IjEyIiB5Mj0iMTIiIHN0cm9rZT0iIzRhZGU4MCIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiLz48L3N2Zz4=)](https://butter-sh.github.io/whip.sh)

*Semantic versioning, changelog generation, git hooks, and monorepo support*

[Documentation](https://butter-sh.github.io/whip.sh) • [GitHub](https://github.com/butter-sh/whip.sh) • [butter.sh](https://github.com/butter-sh)

</div>

---

## Features

- **Semantic Versioning**: Automatic version bumping (major, minor, patch)
- **Changelog Generation**: Create changelogs from git commit history
- **Git Tag Management**: Create and push annotated git tags
- **Commit Hooks**: Install pluggable git hooks with bash validation
- **Monorepo Support**: Batch operations on multiple arty.yml projects
- **arty.yml Integration**: Seamlessly integrates with arty.sh ecosystem

## Installation

### Using hammer.sh

```bash
hammer whip my-project
cd my-project
bash setup.sh
```

### Using arty.sh

```bash
# Add to your arty.yml
references:
  - https://github.com/butter-sh/whip.sh.git

# Install dependencies
arty deps

# Use via arty
arty exec whip release
```

### Quick Install (curl)

```bash
curl -sSL https://raw.githubusercontent.com/butter-sh/whip.sh/main/whip.sh | sudo tee /usr/local/bin/whip > /dev/null
sudo chmod +x /usr/local/bin/whip
```

### Manual Installation

```bash
git clone https://github.com/butter-sh/whip.sh.git
cd whip.sh
chmod +x whip.sh
```

## Dependencies

- bash 4.0+
- git
- yq (YAML processor) - [Installation](https://github.com/mikefarah/yq)
- shellcheck (optional, for pre-commit hooks)

## Quick Start

```bash
# Initialize (if in existing project)
# Just ensure you have an arty.yml file

# Install commit hooks for code quality
./whip.sh hooks install

# Create a patch release (bumps 1.0.0 -> 1.0.1)
./whip.sh release

# Create a minor release (bumps 1.0.0 -> 1.1.0)
./whip.sh release minor

# Create a major release (bumps 1.0.0 -> 2.0.0)
./whip.sh release major
```

## Usage

### Release Commands

Create a full release with version bump, changelog update, and git tag:

```bash
# Patch release (default)
./whip.sh release

# Minor release
./whip.sh release minor

# Major release
./whip.sh release major

# Release without pushing
./whip.sh release --no-push
```

The release process:
1. Bumps version in arty.yml according to semver
2. Generates/updates CHANGELOG.md from git commits
3. Creates a git commit with version changes
4. Creates an annotated git tag (e.g., v1.2.3)
5. Pushes commits and tags to remote

### Version Management

```bash
# Show current version
./whip.sh version

# Bump version without release
./whip.sh bump patch
./whip.sh bump minor
./whip.sh bump major
```

### Changelog

```bash
# Generate changelog from all commits
./whip.sh changelog

# Generate changelog from specific tag
./whip.sh changelog v1.0.0

# Generate changelog for range
./whip.sh changelog v1.0.0 HEAD
```

### Git Hooks

Install commit hooks for automatic code validation:

```bash
# Install hooks
./whip.sh hooks install

# Uninstall hooks
./whip.sh hooks uninstall

# Create custom hooks template
./whip.sh hooks create
```

Built-in validations:
- **Bash syntax check**: Uses `bash -n` to validate syntax
- **ShellCheck**: Runs shellcheck if available (optional)
- **Pluggable**: Add custom hooks to `.whip/hooks/`

### Monorepo Support

Manage multiple arty.yml projects in a monorepo structure:

```bash
# List all arty.yml projects
./whip.sh mono list

# Show versions of all projects
./whip.sh mono version

# Bump version for all projects
./whip.sh mono bump patch

# Filter by glob pattern
./whip.sh mono version "lib-*"

# Show git status for all projects
./whip.sh mono status
```

Example monorepo structure:
```
monorepo/
├── lib-core/
│   └── arty.yml
├── lib-utils/
│   └── arty.yml
└── app-main/
    └── arty.yml
```

## Configuration

### Environment Variables

- `WHIP_CONFIG`: Config file path (default: `arty.yml`)
- `WHIP_CHANGELOG`: Changelog file path (default: `CHANGELOG.md`)

### Custom Config

```bash
# Use custom config file
./whip.sh --config myconfig.yml release

# Use custom changelog file
./whip.sh --changelog HISTORY.md release
```

## Integration with arty.sh

whip.sh is designed to work seamlessly with arty.sh:

```yaml
# arty.yml
name: "my-project"
version: "1.0.0"
description: "My awesome project"

scripts:
  release: "bash whip.sh release"
  release-major: "bash whip.sh release major"
  release-minor: "bash whip.sh release minor"
```

Then use via arty:

```bash
arty release        # Patch release
arty release-major  # Major release
arty release-minor  # Minor release
```

## Custom Hooks

Create custom hooks in `.whip/hooks/`:

```bash
# Create hooks directory
mkdir -p .whip/hooks

# Add custom pre-commit hook
cat > .whip/hooks/pre-commit << 'EOF'
#!/usr/bin/env bash
echo "Running custom checks..."
# Your custom validation logic here
EOF

chmod +x .whip/hooks/pre-commit

# Install hooks
./whip.sh hooks install
```

## Examples

### Simple Release Workflow

```bash
# Make changes and commit
git add .
git commit -m "feat: add new feature"

# Create release
./whip.sh release patch

# Output:
# [INFO] Starting release process
# [INFO] New version: 1.0.1
# [✓] Updated version to 1.0.1 in arty.yml
# [✓] Updated CHANGELOG.md
# [✓] Committed version changes
# [✓] Created tag: v1.0.1
# [✓] Pushed tag: v1.0.1
# [✓] Pushed commits
# [✓] Release 1.0.1 completed successfully!
```

### Monorepo Batch Operations

```bash
# Bump all library projects
./whip.sh mono bump minor "lib-*"

# Output:
# [→] Scanning for arty.yml projects in .
# [INFO] Found 2 project(s)
#
# ━━━ Processing: lib-core ━━━
# [✓] Updated version to 1.1.0 in arty.yml
# Bumped to: 1.1.0
#
# ━━━ Processing: lib-utils ━━━
# [✓] Updated version to 1.1.0 in arty.yml
# Bumped to: 1.1.0
#
# [✓] All projects processed successfully
```

### Complete Project Setup

```bash
# Generate project with hammer.sh
hammer arty my-library

# Add whip.sh for release management
cd my-library
arty install https://github.com/butter-sh/whip.sh.git

# Configure scripts in arty.yml
cat >> arty.yml << 'EOF'
scripts:
  release: "arty exec whip release"
  release-major: "arty exec whip release major"
  release-minor: "arty exec whip release minor"
EOF

# Install hooks
arty exec whip hooks install

# Make changes and release
git add .
git commit -m "feat: initial implementation"
arty release
```

## Integration with butter.sh

whip.sh works seamlessly with other butter.sh tools:

```bash
# Generate project with hammer.sh
hammer arty my-lib

# Add testing with judge.sh
cd my-lib
arty install https://github.com/butter-sh/judge.sh.git

# Add release management with whip.sh
arty install https://github.com/butter-sh/whip.sh.git

# Add documentation with leaf.sh
arty install https://github.com/butter-sh/leaf.sh.git

# Complete workflow
arty exec judge run           # Run tests
arty exec leaf .              # Generate docs
arty exec whip release minor  # Create release
```

## Related Projects

Part of the butter.sh ecosystem:

- **[arty.sh](https://github.com/butter-sh/arty.sh)** - Bash library dependency manager
- **[hammer.sh](https://github.com/butter-sh/hammer.sh)** - Project generator from templates
- **[judge.sh](https://github.com/butter-sh/judge.sh)** - Testing framework with assertions
- **[leaf.sh](https://github.com/butter-sh/leaf.sh)** - Documentation generator
- **[myst.sh](https://github.com/butter-sh/myst.sh)** - Templating engine

## License

MIT License - see [LICENSE](LICENSE) file for details

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Author

Created by [valknar](https://github.com/valknarogg)

---

<div align="center">

Part of the [butter.sh](https://github.com/butter-sh) ecosystem

**Unlimited. Independent. Fresh.**

</div>
