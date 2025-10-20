#!/usr/bin/env bash
# Test suite for whip git hooks management

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WHIP_SH="${SCRIPT_DIR}/../whip.sh"

# Setup before each test
setup() {
    TEST_ENV_DIR=$(create_test_env)
    cd "$TEST_ENV_DIR"
    
    # Initialize git repo
    git init -q
    git config user.email "test@example.com"
    git config user.name "Test User"
}

# Cleanup after each test
teardown() {
    cleanup_test_env
}

# Test: hooks install creates hook files
test_hooks_install() {
    setup
    
    # Create hooks directory
    mkdir -p .whip/hooks
    
    # Create a sample hook
    cat > .whip/hooks/pre-commit << 'EOF'
#!/usr/bin/env bash
echo "Hook executed"
exit 0
EOF
    
    output=$(bash "$WHIP_SH" hooks install 2>&1)
    
    assert_contains "$output" "Installed: pre-commit" "Should install hook"
    assert_file_exists ".git/hooks/pre-commit" "Hook file should exist"
    
    # Check if executable
    [[ -x ".git/hooks/pre-commit" ]]
    assert_equals 0 $? "Hook should be executable"
    
    teardown
}

# Test: hooks install creates default hooks if directory missing
test_hooks_install_creates_defaults() {
    setup
    
    output=$(bash "$WHIP_SH" hooks install 2>&1)
    
    assert_contains "$output" "Creating default hooks" "Should create default hooks"
    assert_file_exists ".whip/hooks/pre-commit" "Should create pre-commit hook"
    assert_file_exists ".git/hooks/pre-commit" "Should install pre-commit hook"
    
    teardown
}

# Test: hooks install fails outside git repo
test_hooks_install_no_git() {
    setup
    
    rm -rf .git
    
    set +e
    output=$(bash "$WHIP_SH" hooks install 2>&1)
    exit_code=$?
    set -e
    
    assert_true "[[ $exit_code -ne 0 ]]" "Should fail outside git repo"
    assert_contains "$output" "Not a git repository" "Should show error"
    
    teardown
}

# Test: hooks uninstall removes hooks
test_hooks_uninstall() {
    setup
    
    # Create hook
    mkdir -p .git/hooks
    echo "#!/bin/bash" > .git/hooks/pre-commit
    echo "#!/bin/bash" > .git/hooks/pre-push
    
    output=$(bash "$WHIP_SH" hooks uninstall 2>&1)
    
    assert_contains "$output" "Removed: pre-commit" "Should remove pre-commit"
    assert_contains "$output" "Removed: pre-push" "Should remove pre-push"
    
    [[ ! -f ".git/hooks/pre-commit" ]]
    assert_equals 0 $? "Pre-commit hook should be removed"
    
    teardown
}

# Test: hooks uninstall with no hooks
test_hooks_uninstall_no_hooks() {
    setup
    
    output=$(bash "$WHIP_SH" hooks uninstall 2>&1)
    
    assert_contains "$output" "No hooks to remove" "Should show no hooks message"
    
    teardown
}

# Test: hooks create creates default templates
test_hooks_create() {
    setup
    
    output=$(bash "$WHIP_SH" hooks create 2>&1)
    
    assert_contains "$output" "Created default pre-commit hook" "Should create hook template"
    assert_file_exists ".whip/hooks/pre-commit" "Hook template should exist"
    
    # Check content
    content=$(cat .whip/hooks/pre-commit)
    assert_contains "$content" "#!/usr/bin/env bash" "Should have shebang"
    assert_contains "$content" "shellcheck" "Should mention shellcheck"
    
    teardown
}

# Test: default pre-commit hook validates bash syntax
test_default_precommit_validates_syntax() {
    setup
    
    bash "$WHIP_SH" hooks create 2>&1 > /dev/null
    bash "$WHIP_SH" hooks install 2>&1 > /dev/null
    
    # Create a valid script
    cat > test.sh << 'EOF'
#!/usr/bin/env bash
echo "valid"
EOF
    
    git add test.sh
    
    # Run pre-commit hook
    set +e
    .git/hooks/pre-commit 2>&1
    exit_code=$?
    set -e
    
    assert_equals 0 $exit_code "Should pass for valid script"
    
    teardown
}

# Test: default pre-commit hook fails on syntax errors
test_default_precommit_fails_invalid_syntax() {
    setup
    
    bash "$WHIP_SH" hooks create 2>&1 > /dev/null
    bash "$WHIP_SH" hooks install 2>&1 > /dev/null
    
    # Create an invalid script
    cat > test.sh << 'EOF'
#!/usr/bin/env bash
if [ true
echo "missing fi"
EOF
    
    git add test.sh
    
    # Run pre-commit hook
    set +e
    output=$(.git/hooks/pre-commit 2>&1)
    exit_code=$?
    set -e
    
    assert_true "[[ $exit_code -ne 0 ]]" "Should fail for invalid script"
    assert_contains "$output" "Syntax error" "Should report syntax error"
    
    teardown
}

# Test: hooks install with custom directory
test_hooks_install_custom_dir() {
    setup
    
    mkdir -p custom/hooks
    cat > custom/hooks/pre-push << 'EOF'
#!/usr/bin/env bash
echo "Custom hook"
EOF
    
    output=$(bash "$WHIP_SH" hooks install custom/hooks 2>&1)
    
    assert_contains "$output" "Installed: pre-push" "Should install from custom dir"
    assert_file_exists ".git/hooks/pre-push" "Should install hook"
    
    teardown
}

# Test: multiple hooks can be installed
test_hooks_install_multiple() {
    setup
    
    mkdir -p .whip/hooks
    echo "#!/bin/bash" > .whip/hooks/pre-commit
    echo "#!/bin/bash" > .whip/hooks/pre-push
    echo "#!/bin/bash" > .whip/hooks/commit-msg
    
    output=$(bash "$WHIP_SH" hooks install 2>&1)
    
    assert_contains "$output" "Installed 3 hook(s)" "Should install all hooks"
    
    teardown
}

# Test: hooks create is idempotent
test_hooks_create_idempotent() {
    setup
    
    bash "$WHIP_SH" hooks create 2>&1 > /dev/null
    bash "$WHIP_SH" hooks create 2>&1 > /dev/null
    
    # Should not fail
    assert_file_exists ".whip/hooks/pre-commit" "Hook should still exist"
    
    teardown
}

# Run all tests
run_tests() {
    test_hooks_install
    test_hooks_install_creates_defaults
    test_hooks_install_no_git
    test_hooks_uninstall
    test_hooks_uninstall_no_hooks
    test_hooks_create
    test_default_precommit_validates_syntax
    test_default_precommit_fails_invalid_syntax
    test_hooks_install_custom_dir
    test_hooks_install_multiple
    test_hooks_create_idempotent
}

export -f run_tests
