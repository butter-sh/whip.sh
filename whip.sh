#!/usr/bin/env bash

# whip.sh - Release cycle management for arty.sh projects
# Handles semver versioning, changelogs, git tags, commit hooks, and monorepo operations
# Version: 1.0.0

set -euo pipefail

# Colors for output - only use colors if output is to a terminal or if FORCE_COLOR is set
export FORCE_COLOR=${FORCE_COLOR:-"1"}
if [[ "$FORCE_COLOR" = "0" ]]; then
  export RED=''
  export GREEN=''
  export YELLOW=''
  export BLUE=''
  export CYAN=''
  export MAGENTA=''
  export BOLD=''
  export NC=''
  else
  export RED='\033[0;31m'
  export GREEN='\033[0;32m'
  export YELLOW='\033[1;33m'
  export BLUE='\033[0;34m'
  export CYAN='\033[0;36m'
  export MAGENTA='\033[0;35m'
  export BOLD='\033[1m'
  export NC='\033[0m'
fi

# Configuration
WHIP_CONFIG="${WHIP_CONFIG:-arty.yml}"
WHIP_HOOKS_DIR=".whip/hooks"
WHIP_CHANGELOG="${WHIP_CHANGELOG:-CHANGELOG.md}"

# Logging functions
log_info() {
  echo -e "${BLUE}[INFO]${NC} $1" >&2
}

log_success() {
  echo -e "${GREEN}[✓]${NC} $1" >&2
}

log_warn() {
  echo -e "${YELLOW}[⚠]${NC} $1" >&2
}

log_error() {
  echo -e "${RED}[✗]${NC} $1" >&2
}

log_step() {
  echo -e "${CYAN}[→]${NC} $1" >&2
}

# Check if yq is installed
check_dependencies() {
  local missing=0

  if ! command -v yq &>/dev/null; then
    log_error "yq is not installed"
    missing=1
  fi

  if ! command -v git &>/dev/null; then
    log_error "git is not installed"
    missing=1
  fi

  if [[ $missing -eq 1 ]]; then
    log_error "Missing required dependencies"
    exit 1
  fi
}

# Get current version from arty.yml
get_current_version() {
  local config="${1:-$WHIP_CONFIG}"

  if [[ ! -f "$config" ]]; then
    echo "0.0.0"
    return
  fi

  local version=$(yq eval '.version' "$config" 2>/dev/null)
  if [[ -z "$version" ]] || [[ "$version" == "null" ]]; then
    echo "0.0.0"
    else
    echo "$version"
  fi
}

# Update version in arty.yml
update_version() {
  local new_version="$1"
  local config="${2:-$WHIP_CONFIG}"

  if [[ ! -f "$config" ]]; then
    log_error "Config file not found: $config"
    return 1
  fi

  yq eval ".version = \"$new_version\"" -i "$config"
  log_success "Updated version to $new_version in $config"
}

# Parse semver components
parse_version() {
  local version="$1"
  local -n major_ref=$2
  local -n minor_ref=$3
  local -n patch_ref=$4

  # Remove 'v' prefix if present
  version="${version#v}"

  if [[ "$version" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
    major_ref="${BASH_REMATCH[1]}"
    minor_ref="${BASH_REMATCH[2]}"
    patch_ref="${BASH_REMATCH[3]}"
    return 0
    else
    return 1
  fi
}

# Bump version (major, minor, or patch)
bump_version() {
  local bump_type="$1"
  local config="${2:-$WHIP_CONFIG}"

  local current_version=$(get_current_version "$config")
  local major minor patch

  if ! parse_version "$current_version" major minor patch; then
    log_error "Invalid version format: $current_version"
    return 1
  fi

  case "$bump_type" in
  major)
  major=$((major + 1))
  minor=0
  patch=0
  ;;
  minor)
  minor=$((minor + 1))
  patch=0
  ;;
  patch)
  patch=$((patch + 1))
  ;;
  *)
  log_error "Invalid bump type: $bump_type (use major, minor, or patch)"
  return 1
  ;;
esac

local new_version="${major}.${minor}.${patch}"
echo "$new_version"
}

# Generate changelog from git commits
generate_changelog() {
  local from_tag="${1:-}"
  local to_ref="${2:-HEAD}"
  local title="${3:-Changelog}"

  local range
  if [[ -z "$from_tag" ]]; then
    # Get all commits if no from_tag
    range="$to_ref"
    else
    range="${from_tag}..${to_ref}"
  fi

  echo "# $title"
  echo ""
  echo "## Changes"
  echo ""

  git log "$range" --pretty=format:"- %s (%h)" --reverse 2>/dev/null || {
    echo "- Initial release"
  }
  echo ""
}

# Update CHANGELOG.md file
update_changelog_file() {
  local new_version="$1"
  local changelog_file="${2:-$WHIP_CHANGELOG}"

  local previous_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
  local date=$(date +%Y-%m-%d)

  local temp_file=$(mktemp)

  # Generate new version section
  {
    echo "# Changelog"
    echo ""
    echo "## [$new_version] - $date"
    echo ""

    if [[ -n "$previous_tag" ]]; then
      git log "${previous_tag}..HEAD" --pretty=format:"- %s" --reverse
      else
      echo "- Initial release"
    fi
    echo ""
    echo ""

    # Append existing changelog if it exists
    if [[ -f "$changelog_file" ]]; then
      # Skip the first "# Changelog" line and empty lines
      tail -n +2 "$changelog_file" | sed '/^$/d; 1s/^//'
    fi
  } >"$temp_file"

  mv "$temp_file" "$changelog_file"
  log_success "Updated $changelog_file"
}

# Create and push git tag
create_release_tag() {
  local version="$1"
  local message="${2:-Release version $version}"
  local push="${3:-true}"

  local tag="v${version}"

  # Check if tag already exists
  if git rev-parse "$tag" >/dev/null 2>&1; then
    log_warn "Tag $tag already exists"
    return 1
  fi

  # Create annotated tag
  git tag -a "$tag" -m "$message"
  log_success "Created tag: $tag"

  # Push tag if requested
  if [[ "$push" == "true" ]]; then
    git push origin "$tag"
    log_success "Pushed tag: $tag"
  fi
}

# Full release workflow
release() {
  local bump_type="${1:-patch}"
  local config="${2:-$WHIP_CONFIG}"
  local push="${3:-true}"

  check_dependencies

  # Check if we're in a git repository
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    log_error "Not a git repository"
    return 1
  fi

  # Check for uncommitted changes
  if [[ -n $(git status --porcelain) ]]; then
    log_warn "You have uncommitted changes"
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      log_info "Release cancelled"
      return 1
    fi
  fi

  log_step "Starting release process"

  # Bump version
  local new_version=$(bump_version "$bump_type" "$config")
  log_info "New version: $new_version"

  # Update version in config
  update_version "$new_version" "$config"

  # Update changelog
  update_changelog_file "$new_version"

  # Commit changes
  git add "$config" "$WHIP_CHANGELOG"
  git commit -m "chore: release version $new_version"
  log_success "Committed version changes"

  # Create and push tag
  create_release_tag "$new_version" "Release version $new_version" "$push"

  # Push commits if requested
  if [[ "$push" == "true" ]]; then
    git push
    log_success "Pushed commits"
  fi

  log_success "Release $new_version completed successfully!"
}

# Install git hooks
install_hooks() {
  local hooks_source_dir="${1:-$WHIP_HOOKS_DIR}"
  local git_hooks_dir=".git/hooks"

  if [[ ! -d "$git_hooks_dir" ]]; then
    log_error "Not a git repository"
    return 1
  fi

  if [[ ! -d "$hooks_source_dir" ]]; then
    log_warn "Hooks directory not found: $hooks_source_dir"
    log_info "Creating default hooks directory..."
    mkdir -p "$hooks_source_dir"
    create_default_hooks "$hooks_source_dir"
  fi

  log_step "Installing git hooks from $hooks_source_dir"

  local installed=0
  for hook_file in "$hooks_source_dir"/*; do
    if [[ -f "$hook_file" ]]; then
      local hook_name=$(basename "$hook_file")
      local target="$git_hooks_dir/$hook_name"

      cp "$hook_file" "$target"
      chmod +x "$target"
      log_success "Installed: $hook_name"
      installed=$((installed + 1))
    fi
  done

  if [[ $installed -eq 0 ]]; then
    log_warn "No hooks found in $hooks_source_dir"
    else
    log_success "Installed $installed hook(s)"
  fi
}

# Create default hooks with validation
create_default_hooks() {
  local hooks_dir="$1"

  mkdir -p "$hooks_dir"

  # Pre-commit hook with shellcheck and bash -n validation
  cat >"$hooks_dir/pre-commit" <<'EOF'
#!/usr/bin/env bash
# Pre-commit hook: validates bash scripts

set -e

echo "Running pre-commit checks..."

# Find all staged .sh files
staged_files=$(git diff --cached --name-only --diff-filter=ACM | grep '\.sh$' || true)

if [[ -z "$staged_files" ]]; then
    echo "No shell scripts to check"
    exit 0
fi

errors=0

# Check each file
for file in $staged_files; do
    if [[ ! -f "$file" ]]; then
        continue
    fi
    
    echo "Checking: $file"
    
    # Bash syntax check
    if ! bash -n "$file" 2>&1; then
        echo "ERROR: Syntax error in $file"
        errors=$((errors + 1))
    fi
    
    # ShellCheck if available
    if command -v shellcheck &> /dev/null; then
        if ! shellcheck "$file" 2>&1; then
            echo "WARNING: ShellCheck found issues in $file"
            # Don't fail on shellcheck warnings, just inform
        fi
    fi
done

if [[ $errors -gt 0 ]]; then
    echo "ERROR: $errors file(s) with syntax errors"
    echo "Please fix the errors before committing"
    exit 1
fi

echo "Pre-commit checks passed!"
exit 0
EOF

  chmod +x "$hooks_dir/pre-commit"
  log_success "Created default pre-commit hook"
}

# Uninstall git hooks
uninstall_hooks() {
  local git_hooks_dir=".git/hooks"

  if [[ ! -d "$git_hooks_dir" ]]; then
    log_error "Not a git repository"
    return 1
  fi

  log_step "Removing git hooks"

  # Remove hooks that were installed by whip
  local hooks=("pre-commit" "pre-push" "commit-msg")
  local removed=0

  for hook in "${hooks[@]}"; do
    local hook_file="$git_hooks_dir/$hook"
    if [[ -f "$hook_file" ]]; then
      rm "$hook_file"
      log_success "Removed: $hook"
      removed=$((removed + 1))
    fi
  done

  if [[ $removed -eq 0 ]]; then
    log_info "No hooks to remove"
    else
    log_success "Removed $removed hook(s)"
  fi
}

# Find arty.yml projects in subdirectories
find_arty_projects() {
  local root_dir="${1:-.}"
  local pattern="${2:-*}"

find "$root_dir" -maxdepth 2 -type f -name "arty.yml" | while read -r config; do
  local project_dir=$(dirname "$config")
  local project_name=$(basename "$project_dir")

    # Apply glob pattern filter
  if [[ "$project_name" == $pattern ]]; then
    echo "$project_dir"
  fi
done
}

# Execute bash command on monorepo projects
monorepo_exec() {
  local bash_cmd="$1"
  local root_dir="${2:-.}"
  local pattern="${3:-*}"

  if [[ -z "$bash_cmd" ]]; then
    log_error "Command required"
    return 1
  fi

  log_step "Scanning for arty.yml projects in $root_dir"

  local projects=()
  while IFS= read -r project_dir; do
    projects+=("$project_dir")
  done < <(find_arty_projects "$root_dir" "$pattern")

  if [[ ${#projects[@]} -eq 0 ]]; then
    log_warn "No arty.yml projects found matching pattern: $pattern"
    return 1
  fi

  log_info "Found ${#projects[@]} project(s)"
  log_info "Executing: $bash_cmd"
  echo

  local failed=0
  for project_dir in "${projects[@]}"; do
    local project_name=$(basename "$project_dir")
    echo -e "${CYAN}━━━ $project_name ━━━${NC}"

    (
      # Export variables for use in command
    export WHIP_PROJECT_DIR="$project_dir"
    export WHIP_PROJECT_NAME="$project_name"

    cd "$project_dir" || exit 1

      # Execute the bash command
    eval "$bash_cmd"
    ) || {
      log_error "Failed for $project_name"
      failed=$((failed + 1))
    }

    echo
  done

  if [[ $failed -gt 0 ]]; then
    log_warn "$failed project(s) failed"
    return 1
    else
    log_success "All projects processed successfully"
  fi
}

# Batch operation on monorepo projects
monorepo_batch() {
  local command="$1"
  local root_dir="${2:-.}"
  local pattern="${3:-*}"

  log_step "Scanning for arty.yml projects in $root_dir"

  local projects=()
  while IFS= read -r project_dir; do
    projects+=("$project_dir")
  done < <(find_arty_projects "$root_dir" "$pattern")

  if [[ ${#projects[@]} -eq 0 ]]; then
    log_warn "No arty.yml projects found matching pattern: $pattern"
    return 1
  fi

  log_info "Found ${#projects[@]} project(s)"
  echo

  local failed=0
  for project_dir in "${projects[@]}"; do
    local project_name=$(basename "$project_dir")
    echo -e "${CYAN}━━━ Processing: $project_name ━━━${NC}"

    (
    cd "$project_dir"

    case "$command" in
    version)
    local version=$(get_current_version)
    echo "Version: $version"
    ;;
    bump)
    local bump_type="${4:-patch}"
    local new_version=$(bump_version "$bump_type")
    update_version "$new_version"
    echo "Bumped to: $new_version"
    ;;
    status)
    if git rev-parse --git-dir >/dev/null 2>&1; then
      git status --short
      else
      echo "Not a git repository"
    fi
    ;;
    *)
    log_error "Unknown command: $command"
    return 1
    ;;
  esac
  ) || {
    log_error "Failed for $project_name"
    failed=$((failed + 1))
  }

  echo
done

if [[ $failed -gt 0 ]]; then
  log_warn "$failed project(s) failed"
  return 1
  else
  log_success "All projects processed successfully"
fi
}

# Show comprehensive mono help
show_mono_help() {
  cat <<'EOF'
whip.sh mono - Monorepo management commands

USAGE:
    whip mono <subcommand> [options] [pattern]

SUBCOMMANDS:
    list [root] [pattern]              List all arty.yml projects
    version [root] [pattern]           Show version of all projects  
    bump <type> [root] [pattern]       Bump version (major|minor|patch)
    status [root] [pattern]            Show git status for all projects
    exec <command> [root] [pattern]    Execute bash command on all projects
    help                               Show this help message

ARGUMENTS:
    root        Root directory to search (default: current directory)
    pattern     Glob pattern to filter projects (default: *)
    type        Version bump type: major, minor, or patch
    command     Bash command or script to execute

AVAILABLE VARIABLES (in exec):
    $WHIP_PROJECT_DIR     Full path to project directory
    $WHIP_PROJECT_NAME    Project name (basename)
    $PWD                  Current directory (already cd'd into project)

EXAMPLES:

  Basic Operations:
    whip mono list                    # List all projects in current dir
    whip mono list ../monorepo        # List projects in specific dir
    whip mono list . "lib-*"          # List only lib-* projects
    whip mono version                 # Show all project versions
    whip mono status                  # Git status for all projects

  Version Management:
    whip mono bump patch              # Bump patch version for all
    whip mono bump minor "lib-*"      # Bump minor for lib-* projects
    whip mono bump major . "*-core"   # Bump major for *-core projects

  Executing Commands:
    # Simple commands
    whip mono exec "pwd"
    whip mono exec "echo \$WHIP_PROJECT_NAME"
    whip mono exec "git status"
    
    # Using project variables
    whip mono exec 'echo "Project: $WHIP_PROJECT_NAME at $WHIP_PROJECT_DIR"'
    
    # Multi-line commands (use quotes)
    whip mono exec 'git add . && git commit -m "chore: update" && git push'
    
    # Conditional execution
    whip mono exec 'if [[ -f package.json ]]; then npm install; fi'
    
    # Complex operations
    whip mono exec '
        echo "Cleaning $WHIP_PROJECT_NAME..."
        rm -rf node_modules dist
        echo "Building..."
        npm run build
    '
    
    # With pattern filtering
    whip mono exec "npm test" . "lib-*"
    whip mono exec "make clean && make" . "*-service"

  Real-World Scenarios:
    # Commit and push all projects
    whip mono exec 'git add . && git commit -m "chore: streamline" && git push origin main'
    
    # Update dependencies
    whip mono exec 'arty deps'
    
    # Run tests
    whip mono exec 'bash test.sh'
    
    # Create git tags
    whip mono exec 'git tag -a v1.0.0 -m "Release 1.0.0" && git push --tags'
    
    # Check for uncommitted changes
    whip mono exec '[[ -n $(git status --porcelain) ]] && echo "Has changes" || echo "Clean"'
    
    # Generate documentation
    whip mono exec 'leaf.sh . && echo "Docs generated"'
    
    # Sync with remote
    whip mono exec 'git fetch && git pull origin main'

PATTERN MATCHING:
    Glob patterns filter which projects to process:
    
    *           All projects (default)
    lib-*       Projects starting with "lib-"
    *-core      Projects ending with "-core"
    app-*       Projects starting with "app-"
    *-service   Projects ending with "-service"
    test-*      Projects starting with "test-"

PROJECT DISCOVERY:
    whip searches for arty.yml files up to 2 levels deep:
    
    monorepo/
    ├── lib-core/
    │   └── arty.yml          ✓ Found
    ├── services/
    │   ├── api-service/
    │   │   └── arty.yml      ✓ Found
    │   └── web-service/
    │       └── arty.yml      ✓ Found
    └── tools/
        └── deep/
            └── nested/
                └── arty.yml  ✗ Too deep (>2 levels)

ERROR HANDLING:
    - Individual project failures don't stop the batch
    - Failed projects are reported at the end
    - Exit code reflects overall success/failure
    - Use -e in commands for strict error handling

TIPS:
    - Quote commands with special characters
    - Use single quotes to prevent variable expansion
    - Test commands on one project first
    - Use pattern matching to limit scope
    - Check for uncommitted changes before operations
    - Combine with other whip commands for workflows

SEE ALSO:
    whip --help              Main help
    whip release --help      Release workflow help
    whip hooks --help        Git hooks help

EOF
}

# Show usage
show_usage() {
  cat <<'EOF'
whip.sh - Release cycle management for arty.sh projects

USAGE:
    whip <command> [options]

RELEASE COMMANDS:
    release [major|minor|patch]   Full release workflow (default: patch)
                                  - Bumps version in arty.yml
                                  - Updates CHANGELOG.md from git history
                                  - Creates git commit
                                  - Creates and pushes git tag
    
    version                       Show current version from arty.yml
    bump <major|minor|patch>      Bump version in arty.yml (no commit/tag)
    changelog                     Generate changelog from git history
    tag <version>                 Create and push git tag

HOOK COMMANDS:
    hooks install                 Install git commit hooks
                                  - Includes shellcheck validation
                                  - Includes bash -n syntax check
    hooks uninstall              Remove git commit hooks
    hooks create                 Create default hook templates

MONOREPO COMMANDS:
    mono list [root] [pattern]          List arty.yml projects
    mono version [root] [pattern]       Show versions of all projects
    mono bump <type> [root] [pattern]   Bump version for all projects
    mono status [root] [pattern]        Show git status for all projects
    mono exec <cmd> [root] [pattern]    Execute bash command on all projects
    mono help                           Show detailed mono help

OPTIONS:
    --no-push                    Don't push commits/tags (for release)
    --config <file>              Use custom config file (default: arty.yml)
    --changelog <file>           Use custom changelog file (default: CHANGELOG.md)
    -h, --help                   Show this help message

EXAMPLES:
    # Full release workflow (patch)
    whip release

    # Major version release
    whip release major

    # Just bump version without release
    whip bump minor

    # Install commit hooks
    whip hooks install

    # Monorepo: list all projects
    whip mono list

    # Monorepo: bump patch version for all projects matching "lib-*"
    whip mono bump patch . "lib-*"

    # Monorepo: execute command on all projects
    whip mono exec "git status"
    whip mono exec 'git add . && git commit -m "update" && git push' . "lib-*"

    # Release without pushing
    whip release --no-push

    # Get detailed monorepo help
    whip mono help

HOOKS:
    whip installs pluggable git hooks for code quality:
    
    pre-commit:
    - Validates bash syntax with 'bash -n'
    - Runs shellcheck if available
    - Prevents commits with syntax errors

    Custom hooks can be added to .whip/hooks/

MONOREPO SUPPORT:
    whip can manage multiple arty.yml projects in a monorepo structure:
    
    monorepo/
    ├── lib-core/
    │   └── arty.yml
    ├── lib-utils/
    │   └── arty.yml
    └── app-main/
        └── arty.yml
    
    Use glob patterns to filter projects:
    - "lib-*"    Match all projects starting with "lib-"
    - "*-core"   Match all projects ending with "-core"
    - "*"        Match all projects (default)
    
    Execute arbitrary bash commands:
    - Access project info via $WHIP_PROJECT_NAME and $WHIP_PROJECT_DIR
    - Commands run in project directory (already cd'd)
    - Quote commands with special characters

EOF
}

# Main function
main() {
  if [[ $# -eq 0 ]]; then
    show_usage
    exit 0
  fi

  # Parse global options
  local push=true
  local config="$WHIP_CONFIG"
  local changelog="$WHIP_CHANGELOG"

  while [[ $# -gt 0 ]]; do
    case $1 in
    --no-push)
    push=false
    shift
    ;;
    --config)
    config="$2"
    WHIP_CONFIG="$config"
    shift 2
    ;;
    --changelog)
    changelog="$2"
    WHIP_CHANGELOG="$changelog"
    shift 2
    ;;
    -h | --help)
    show_usage
    exit 0
    ;;
    *)
    break
    ;;
  esac
done

if [[ $# -eq 0 ]]; then
  show_usage
  exit 0
fi

local command="$1"
shift

case "$command" in
release)
local bump_type="${1:-patch}"
release "$bump_type" "$config" "$push"
;;
version)
get_current_version "$config"
;;
bump)
if [[ $# -eq 0 ]]; then
  log_error "Bump type required (major, minor, or patch)"
  exit 1
fi
local new_version=$(bump_version "$1" "$config")
update_version "$new_version" "$config"
echo "$new_version"
;;
changelog)
generate_changelog "${1:-}" "${2:-HEAD}"
;;
tag)
if [[ $# -eq 0 ]]; then
  log_error "Version required"
  exit 1
fi
create_release_tag "$1" "${2:-Release version $1}" "$push"
;;
hooks)
if [[ $# -eq 0 ]]; then
  log_error "Hooks subcommand required (install, uninstall, create)"
  exit 1
fi
local subcommand="$1"
shift
case "$subcommand" in
install)
install_hooks "${1:-$WHIP_HOOKS_DIR}"
;;
uninstall)
uninstall_hooks
;;
create)
create_default_hooks "${1:-$WHIP_HOOKS_DIR}"
;;
*)
log_error "Unknown hooks subcommand: $subcommand"
exit 1
;;
esac
;;
mono | monorepo)
if [[ $# -eq 0 ]]; then
  log_error "Monorepo subcommand required"
  show_mono_help
  exit 1
fi
local subcommand="$1"
shift
case "$subcommand" in
help | --help | -h)
show_mono_help
;;
list)
find_arty_projects "${1:-.}" "${2:-*}"
;;
version | bump | status)
monorepo_batch "$subcommand" "${1:-.}" "${2:-*}" "${3:-}"
;;
exec)
if [[ $# -eq 0 ]]; then
  log_error "Command required for exec"
  echo "Usage: whip mono exec <command> [root] [pattern]"
  echo "Example: whip mono exec 'git status' . 'lib-*'"
  exit 1
fi
local cmd="$1"
shift
monorepo_exec "$cmd" "${1:-.}" "${2:-*}"
;;
*)
log_error "Unknown monorepo subcommand: $subcommand"
echo "Run 'whip mono help' for detailed usage"
exit 1
;;
esac
;;
*)
log_error "Unknown command: $command"
show_usage
exit 1
;;
esac
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
