# Enhanced: whip.sh Monorepo Features

## ✅ New Features Added

### 1. **`mono exec` Command**
Execute arbitrary bash commands across all matched projects in a monorepo.

#### Syntax
```bash
whip mono exec <command> [root] [pattern]
```

#### Features
- ✅ Execute any bash command or script
- ✅ Multi-line commands supported
- ✅ Pattern filtering with glob patterns
- ✅ Environment variables for project context
- ✅ Individual error handling
- ✅ Continues on failure (reports at end)

---

### 2. **Comprehensive `mono help`**
Dedicated help system for monorepo operations with extensive examples.

#### Access
```bash
whip mono help
```

#### Contents
- Complete command reference
- Available variables
- Real-world examples
- Pattern matching guide
- Project discovery explanation
- Error handling details
- Tips and best practices

---

## 🎯 Available Variables in `exec`

When using `mono exec`, these variables are available:

| Variable | Description | Example |
|----------|-------------|---------|
| `$WHIP_PROJECT_DIR` | Full path to project | `/path/to/monorepo/lib-core` |
| `$WHIP_PROJECT_NAME` | Project name (basename) | `lib-core` |
| `$PWD` | Current directory | Same as project dir (auto cd'd) |

---

## 📋 Usage Examples

### Simple Commands
```bash
# Show current directory
whip mono exec "pwd"

# Display project name
whip mono exec 'echo $WHIP_PROJECT_NAME'

# Git status
whip mono exec "git status"

# List files
whip mono exec "ls -la"
```

### Using Project Variables
```bash
# Show project info
whip mono exec 'echo "Project: $WHIP_PROJECT_NAME at $WHIP_PROJECT_DIR"'

# Create project-specific file
whip mono exec 'echo "# $WHIP_PROJECT_NAME" > STATUS.md'

# Log to file with project name
whip mono exec 'echo "$(date): Built $WHIP_PROJECT_NAME" >> build.log'
```

### Git Operations
```bash
# Commit and push
whip mono exec 'git add . && git commit -m "chore: streamline" && git push origin main'

# Create tags
whip mono exec 'git tag -a v1.0.0 -m "Release 1.0.0" && git push --tags'

# Sync with remote
whip mono exec 'git fetch && git pull origin main'

# Check for uncommitted changes
whip mono exec '[[ -n $(git status --porcelain) ]] && echo "Has changes" || echo "Clean"'
```

### Multi-Line Commands
```bash
# Complex build process
whip mono exec '
    echo "Cleaning $WHIP_PROJECT_NAME..."
    rm -rf dist build
    echo "Building..."
    make build
    echo "Done!"
'

# Conditional operations
whip mono exec '
    if [[ -f package.json ]]; then
        echo "Installing npm dependencies..."
        npm install
    fi
'
```

### With Pattern Filtering
```bash
# Run tests only on lib-* projects
whip mono exec "npm test" . "lib-*"

# Build only services
whip mono exec "make clean && make" . "*-service"

# Update dependencies for apps
whip mono exec "arty deps" . "app-*"

# Documentation for core modules
whip mono exec "leaf.sh ." . "*-core"
```

### Real-World Scenarios
```bash
# Update all dependencies
whip mono exec 'arty deps'

# Run tests
whip mono exec 'bash test.sh'

# Generate documentation
whip mono exec 'leaf.sh . && echo "Docs generated for $WHIP_PROJECT_NAME"'

# Lint code
whip mono exec 'shellcheck *.sh'

# Format code
whip mono exec 'shfmt -w *.sh'

# Clean build artifacts
whip mono exec 'rm -rf dist build node_modules'

# Install and test
whip mono exec 'npm install && npm test'
```

---

## 🎨 Pattern Matching

### Glob Patterns

| Pattern | Matches | Example |
|---------|---------|---------|
| `*` | All projects | All subdirectories |
| `lib-*` | Starts with "lib-" | `lib-core`, `lib-utils` |
| `*-core` | Ends with "-core" | `lib-core`, `app-core` |
| `app-*` | Starts with "app-" | `app-web`, `app-api` |
| `*-service` | Ends with "-service" | `api-service`, `web-service` |
| `test-*` | Starts with "test-" | `test-unit`, `test-integration` |

### Examples
```bash
# All libraries
whip mono exec "make build" . "lib-*"

# All core modules
whip mono exec "npm test" . "*-core"

# All services
whip mono exec "docker build ." . "*-service"

# All apps
whip mono exec "npm start" . "app-*"
```

---

## 🏗️ Project Discovery

whip searches for `arty.yml` files **up to 2 levels deep**:

```
monorepo/
├── lib-core/
│   └── arty.yml          ✓ Found (level 1)
├── services/
│   ├── api-service/
│   │   └── arty.yml      ✓ Found (level 2)
│   └── web-service/
│       └── arty.yml      ✓ Found (level 2)
└── tools/
    └── deep/
        └── nested/
            └── arty.yml  ✗ Too deep (level 3)
```

---

## ⚠️ Error Handling

### Behavior
- Individual project failures **don't stop** the batch
- Failed projects are **reported** at the end
- Exit code reflects **overall success/failure**
- Use `-e` in commands for **strict error handling**

### Example
```bash
# This continues even if some projects fail
whip mono exec 'make test'

# Strict mode - stops on first error
whip mono exec 'set -e; make test'
```

---

## 💡 Tips & Best Practices

### 1. **Quote Commands**
```bash
# Good - single quotes prevent expansion
whip mono exec 'echo $WHIP_PROJECT_NAME'

# Bad - double quotes expand too early
whip mono exec "echo $WHIP_PROJECT_NAME"
```

### 2. **Test First**
```bash
# Test on one project first
cd lib-core
git add . && git commit -m "test" && git push

# Then apply to all
cd ..
whip mono exec 'git add . && git commit -m "test" && git push'
```

### 3. **Use Pattern Matching**
```bash
# Limit scope to reduce risk
whip mono exec "risky-operation" . "test-*"
```

### 4. **Check Before Operations**
```bash
# Check status first
whip mono status

# Then proceed
whip mono exec 'git push'
```

### 5. **Combine with Other Commands**
```bash
# Bump versions
whip mono bump patch . "lib-*"

# Then commit and push
whip mono exec 'git add arty.yml && git commit -m "bump version" && git push'
```

---

## 📊 Comparison: Before vs After

### Before (Manual)
```bash
# Had to manually loop
for dir in lib-*/; do
  cd "$dir"
  git status
  cd ..
done
```

### After (With whip)
```bash
# One command
whip mono exec "git status" . "lib-*"
```

---

## 🎯 Use Cases

### CI/CD Integration
```bash
# Run all tests in pipeline
whip mono exec 'make test'

# Deploy all services
whip mono exec 'make deploy' . "*-service"
```

### Development Workflow
```bash
# Update all dependencies
whip mono exec 'arty deps'

# Check uncommitted changes
whip mono exec 'git status --short'

# Format all code
whip mono exec 'shfmt -w *.sh'
```

### Release Management
```bash
# Bump versions
whip mono bump minor . "lib-*"

# Generate changelogs
whip mono exec './whip.sh changelog' . "lib-*"

# Create tags
whip mono exec 'git tag -a v$(yq .version arty.yml) -m "Release"'
```

### Maintenance
```bash
# Clean build artifacts
whip mono exec 'rm -rf dist build'

# Update documentation
whip mono exec 'leaf.sh .'

# Archive logs
whip mono exec 'tar -czf logs-$(date +%Y%m%d).tar.gz logs/'
```

---

## 🔗 Integration with Other Tools

### With arty.sh
```bash
# Update dependencies
whip mono exec 'arty deps'

# Execute library scripts
whip mono exec 'arty exec mylib --version'
```

### With hammer.sh
```bash
# Generate documentation
whip mono exec 'hammer leaf docs'
```

### With judge.sh
```bash
# Run tests
whip mono exec 'judge test tests/*.sh'
```

### With leaf.sh
```bash
# Generate docs
whip mono exec 'leaf.sh . && echo "Docs for $WHIP_PROJECT_NAME complete"'
```

---

## 📚 Complete Command Reference

### Monorepo Commands
```bash
whip mono list [root] [pattern]          # List projects
whip mono version [root] [pattern]       # Show versions
whip mono bump <type> [root] [pattern]   # Bump versions
whip mono status [root] [pattern]        # Git status
whip mono exec <cmd> [root] [pattern]    # Execute command (NEW!)
whip mono help                           # Show help (NEW!)
```

### Arguments
- `root` - Root directory (default: `.`)
- `pattern` - Glob pattern (default: `*`)
- `type` - `major`, `minor`, or `patch`
- `cmd` - Bash command to execute

---

## ✨ Summary

The enhanced monorepo support in whip.sh now provides:

1. ✅ **Arbitrary command execution** across projects
2. ✅ **Comprehensive help system** with examples
3. ✅ **Environment variables** for project context
4. ✅ **Pattern filtering** for targeted operations
5. ✅ **Error handling** that doesn't stop the batch
6. ✅ **Real-world examples** for common tasks

This makes whip.sh a **powerful tool for monorepo management**, allowing you to automate complex workflows across multiple projects with a single command!

🎉 **Your monorepo operations just got supercharged!**
