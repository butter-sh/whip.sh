#!/usr/bin/env bash
# Test suite for whip changelog generation and management

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WHIP_SH="${SCRIPT_DIR}/../whip.sh"

# Setup before each test
setup() {
  TEST_ENV_DIR=$(create_test_env)
  export WHIP_CONFIG_FILE="$TEST_ENV_DIR/arty.yml"
  export WHIP_CHANGELOG="$TEST_ENV_DIR/CHANGELOG.md"
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

# Test: generate_changelog from all commits
test_generate_changelog_all() {
  setup

  # Create some commits
  echo "test" >file1.txt
  git add file1.txt
  git commit -m "feat: add feature" -q

  echo "test2" >file2.txt
  git add file2.txt
  git commit -m "fix: bug fix" -q

  cat >"$TEST_ENV_DIR/arty.yml" <<'EOF'
name: "test-project"
version: "1.0.0"
EOF

  output=$(bash "$WHIP_SH" --config "$TEST_ENV_DIR/arty.yml" changelog 2>&1)

  assert_contains "$output" "Changelog" "Should have changelog header"
  assert_contains "$output" "feat: add feature" "Should include first commit"
  assert_contains "$output" "fix: bug fix" "Should include second commit"

  teardown
}

# Test: generate_changelog with no commits
test_generate_changelog_no_commits() {
  setup

  cat >"$TEST_ENV_DIR/arty.yml" <<'EOF'
name: "test-project"
version: "1.0.0"
EOF

  output=$(bash "$WHIP_SH" --config "$TEST_ENV_DIR/arty.yml" changelog 2>&1)

  assert_contains "$output" "Initial release" "Should show initial release"

  teardown
}

# Test: generate_changelog from tag
test_generate_changelog_from_tag() {
  setup

  echo "test" >file1.txt
  git add file1.txt
  git commit -m "feat: initial" -q
  git tag v1.0.0

  echo "test2" >file2.txt
  git add file2.txt
  git commit -m "feat: new feature" -q

  cat >"$TEST_ENV_DIR/arty.yml" <<'EOF'
name: "test-project"
version: "1.1.0"
EOF

  cat >"$TEST_ENV_DIR/test_changelog.sh" <<'EOF'
#!/usr/bin/env bash
source "${1}"
generate_changelog "v1.0.0" "HEAD"
EOF

  output=$(bash "$TEST_ENV_DIR/test_changelog.sh" "$WHIP_SH")

  assert_contains "$output" "new feature" "Should include commit after tag"
  assert_not_contains "$output" "initial" "Should not include commit before tag"

  teardown
}

# Test: update_changelog_file creates new changelog
test_update_changelog_file_new() {
  setup

  echo "test" >file1.txt
  git add file1.txt
  git commit -m "feat: add feature" -q

  cat >"$TEST_ENV_DIR/arty.yml" <<'EOF'
name: "test-project"
version: "1.0.0"
EOF

  cat >"$TEST_ENV_DIR/test_update.sh" <<'EOF'
#!/usr/bin/env bash
export WHIP_CHANGELOG="${1}"
source "${2}"
update_changelog_file "1.0.0" "${1}"
EOF

  bash "$TEST_ENV_DIR/test_update.sh" "$WHIP_CHANGELOG" "$WHIP_SH" 2>&1

  assert_file_exists "$WHIP_CHANGELOG" "Should create changelog file"

  content=$(cat "$WHIP_CHANGELOG")
  assert_contains "$content" "# Changelog" "Should have header"
  assert_contains "$content" "[1.0.0]" "Should have version"

  teardown
}

# Test: update_changelog_file appends to existing
test_update_changelog_file_append() {
  setup

  echo "test" >file1.txt
  git add file1.txt
  git commit -m "feat: version 1" -q
  git tag v1.0.0

  echo "test2" >file2.txt
  git add file2.txt
  git commit -m "feat: version 2" -q

  cat >"$TEST_ENV_DIR/arty.yml" <<'EOF'
name: "test-project"
version: "2.0.0"
EOF

  # Create initial changelog
  cat >"$WHIP_CHANGELOG" <<'EOF'
# Changelog

## [1.0.0] - 2024-01-01

- feat: version 1
EOF

  cat >"$TEST_ENV_DIR/test_update.sh" <<'EOF'
#!/usr/bin/env bash
export WHIP_CHANGELOG="${1}"
source "${2}"
update_changelog_file "2.0.0" "${1}"
EOF

  bash "$TEST_ENV_DIR/test_update.sh" "$WHIP_CHANGELOG" "$WHIP_SH" 2>&1

  content=$(cat "$WHIP_CHANGELOG")
  assert_contains "$content" "[2.0.0]" "Should have new version"
  assert_contains "$content" "[1.0.0]" "Should preserve old version"

  teardown
}

# Test: update_changelog_file includes date
test_update_changelog_file_date() {
  setup

  echo "test" >file1.txt
  git add file1.txt
  git commit -m "feat: add feature" -q

  cat >"$TEST_ENV_DIR/arty.yml" <<'EOF'
name: "test-project"
version: "1.0.0"
EOF

  cat >"$TEST_ENV_DIR/test_update.sh" <<'EOF'
#!/usr/bin/env bash
export WHIP_CHANGELOG="${1}"
source "${2}"
update_changelog_file "1.0.0" "${1}"
EOF

  bash "$TEST_ENV_DIR/test_update.sh" "$WHIP_CHANGELOG" "$WHIP_SH" 2>&1

  content=$(cat "$WHIP_CHANGELOG")

  # Should include a date in YYYY-MM-DD format
  assert_contains "$content" "202" "Should include date"

  teardown
}

# Test: changelog with conventional commits
test_changelog_conventional_commits() {
  setup

  echo "test1" >file1.txt
  git add file1.txt
  git commit -m "feat: add new feature" -q

  echo "test2" >file2.txt
  git add file2.txt
  git commit -m "fix: resolve bug" -q

  echo "test3" >file3.txt
  git add file3.txt
  git commit -m "chore: update dependencies" -q

  echo "test4" >file4.txt
  git add file4.txt
  git commit -m "docs: update readme" -q

  cat >"$TEST_ENV_DIR/arty.yml" <<'EOF'
name: "test-project"
version: "1.0.0"
EOF

  output=$(bash "$WHIP_SH" --config "$TEST_ENV_DIR/arty.yml" changelog 2>&1)

  assert_contains "$output" "feat: add new feature" "Should include feat"
  assert_contains "$output" "fix: resolve bug" "Should include fix"
  assert_contains "$output" "chore: update dependencies" "Should include chore"
  assert_contains "$output" "docs: update readme" "Should include docs"

  teardown
}

# Test: changelog includes commit hashes
test_changelog_includes_hashes() {
  setup

  echo "test" >file1.txt
  git add file1.txt
  git commit -m "feat: add feature" -q

  cat >"$TEST_ENV_DIR/arty.yml" <<'EOF'
name: "test-project"
version: "1.0.0"
EOF

  output=$(bash "$WHIP_SH" --config "$TEST_ENV_DIR/arty.yml" changelog 2>&1)

  # Should include short hash in parentheses
  assert_contains "$output" "(" "Should include hash markers"

  teardown
}

# Test: changelog with multiline commits uses only first line
test_changelog_multiline_commits() {
  setup

  echo "test" >file1.txt
  git add file1.txt
  git commit -m "feat: add feature

This is a detailed description
that spans multiple lines" -q

  cat >"$TEST_ENV_DIR/arty.yml" <<'EOF'
name: "test-project"
version: "1.0.0"
EOF

  output=$(bash "$WHIP_SH" --config "$TEST_ENV_DIR/arty.yml" changelog 2>&1)

  assert_contains "$output" "feat: add feature" "Should include first line"
  assert_not_contains "$output" "detailed description" "Should not include body"

  teardown
}

# Run all tests
run_tests() {
  test_generate_changelog_all
  test_generate_changelog_no_commits
  test_generate_changelog_from_tag
  test_update_changelog_file_new
  test_update_changelog_file_append
  test_update_changelog_file_date
  test_changelog_conventional_commits
  test_changelog_includes_hashes
  test_changelog_multiline_commits
}

export -f run_tests
