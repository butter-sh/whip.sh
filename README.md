# whip.sh

Release cycle management for arty.sh projects with semantic versioning, changelog generation, git hooks, and monorepo support.

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
hammer.sh whip my-project
cd my-project
bash setup.sh
```

### Manual Installation

```bash
git clone <repository-url>
cd whip.sh
chmod +x whip.sh
```

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

## Requirements

- bash 4.0+
- git
- yq (YAML processor) - [Installation](https://github.com/mikefarah/yq)
- shellcheck (optional, for pre-commit hooks)

## License

MIT

## Author

{{author}}
