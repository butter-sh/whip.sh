# Quick Reference: whip.sh

## Generate Project
```bash
hammer.sh whip my-project
cd my-project
bash setup.sh
```

## Common Commands

### Release
```bash
./whip.sh release              # Patch: 1.0.0 → 1.0.1
./whip.sh release minor        # Minor: 1.0.0 → 1.1.0
./whip.sh release major        # Major: 1.0.0 → 2.0.0
./whip.sh release --no-push    # Don't push to remote
```

### Version
```bash
./whip.sh version              # Show current version
./whip.sh bump patch           # Bump without release
./whip.sh bump minor
./whip.sh bump major
```

### Hooks
```bash
./whip.sh hooks install        # Install pre-commit hooks
./whip.sh hooks uninstall      # Remove hooks
./whip.sh hooks create         # Create custom hooks
```

### Monorepo
```bash
./whip.sh mono list            # List all projects
./whip.sh mono version         # Show all versions
./whip.sh mono bump patch      # Bump all projects
./whip.sh mono status          # Git status all
./whip.sh mono version . "lib-*" # Filter by pattern

# Execute commands on all projects
./whip.sh mono exec "git status"
./whip.sh mono exec 'echo $WHIP_PROJECT_NAME'
./whip.sh mono exec 'git add . && git commit -m "update" && git push'
./whip.sh mono exec "npm test" . "lib-*"

./whip.sh mono help            # Detailed help
```

### Changelog
```bash
./whip.sh changelog            # Generate from all commits
./whip.sh changelog v1.0.0     # From specific tag
```

## Via arty.sh
```bash
arty release                   # Patch release
arty release-major             # Major release
arty release-minor             # Minor release
arty install                   # Install hooks
```

## Pre-commit Hook Features
- ✓ Bash syntax validation (`bash -n`)
- ✓ ShellCheck validation (if installed)
- ✓ Prevents commits with errors
- ✓ Pluggable custom hooks

## Monorepo Structure Example
```
monorepo/
├── lib-core/arty.yml
├── lib-utils/arty.yml
└── app-main/arty.yml
```

## Environment Variables
```bash
WHIP_CONFIG=/path/to/config.yml    # Custom config
WHIP_CHANGELOG=/path/to/CHANGES.md # Custom changelog
```

## Requirements
- bash 4.0+
- git
- yq (YAML processor)
- shellcheck (optional)
