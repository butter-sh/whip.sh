#!/usr/bin/env bash
# Test suite for whip full release workflow

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

  # Create initial commit
  echo "initial" >README.md
  git add README.md
  git commit -m "Initial commit" -q
}

# Cleanup after each test
teardown() {
  cleanup_test_env
}

# Test: release workflow with patch
test_release_patch() {
  setup

  cat >"$TEST_ENV_DIR/arty.yml" <<'EOF'
name: "test-project"
version: "1.0.0"
EOF

  git add arty.yml
  git commit -m "Add config" -q

  echo "feature" >feature.txt
  git add feature.txt
  git commit -m "feat: add feature" -q

  output=$(bash "$WHIP_SH" --config "$TEST_ENV_DIR/arty.yml" --no-push release patch 2>&1)

  assert_contains "$output" "Starting release process" "Should start release"
  assert_contains "$output" "1.0.1" "Should bump to 1.0.1"
  assert_contains "$output" "Committed version changes" "Should commit"
  assert_contains "$output" "Created tag" "Should create tag"
  assert_contains "$output" "Release" "Should complete"

  # Verify version was updated
  version=$(yq eval '.version' "$TEST_ENV_DIR/arty.yml")
  assert_equals "1.0.1" "$version" "Version should be updated"

  # Verify changelog was created
  assert_file_exists "$WHIP_CHANGELOG" "Changelog should exist"

  # Verify tag was created
  git tag | grep -q "v1.0.1"
  assert_equals 0 $? "Tag should exist"

  # Verify commit was made
  git log --oneline | grep -q "chore: release version 1.0.1"
  assert_equals 0 $? "Release commit should exist"

  teardown
}

# Test: release workflow with minor
test_release_minor() {
  setup

  cat >"$TEST_ENV_DIR/arty.yml" <<'EOF'
name: "test-project"
version: "1.2.3"
EOF

  git add arty.yml
  git commit -m "Add config" -q

  output=$(bash "$WHIP_SH" --config "$TEST_ENV_DIR/arty.yml" --no-push release minor 2>&1)

  assert_contains "$output" "1.3.0" "Should bump to 1.3.0"

  version=$(yq eval '.version' "$TEST_ENV_DIR/arty.yml")
  assert_equals "1.3.0" "$version" "Version should be 1.3.0"

  teardown
}

# Test: release workflow with major
test_release_major() {
  setup

  cat >"$TEST_ENV_DIR/arty.yml" <<'EOF'
name: "test-project"
version: "1.9.9"
EOF

  git add arty.yml
  git commit -m "Add config" -q

  output=$(bash "$WHIP_SH" --config "$TEST_ENV_DIR/arty.yml" --no-push release major 2>&1)

  assert_contains "$output" "2.0.0" "Should bump to 2.0.0"

  version=$(yq eval '.version' "$TEST_ENV_DIR/arty.yml")
  assert_equals "2.0.0" "$version" "Version should be 2.0.0"

  teardown
}

# Test: release default bump type is patch
test_release_default_patch() {
  setup

  cat >"$TEST_ENV_DIR/arty.yml" <<'EOF'
name: "test-project"
version: "1.0.0"
EOF

  git add arty.yml
  git commit -m "Add config" -q

  output=$(bash "$WHIP_SH" --no-push release 2>&1)

  assert_contains "$output" "1.0.1" "Should default to patch bump"

  teardown
}

# Test: release warns about uncommitted changes
test_release_uncommitted_changes() {
  setup

  cat >"$TEST_ENV_DIR/arty.yml" <<'EOF'
name: "test-project"
version: "1.0.0"
EOF

  git add arty.yml
  git commit -m "Add config" -q

  # Create uncommitted change
  echo "uncommitted" >uncommitted.txt

  # Simulate user declining
  output=$(echo "n" | bash "$WHIP_SH" --config "$TEST_ENV_DIR/arty.yml" --no-push release 2>&1)

  assert_contains "$output" "uncommitted changes" "Should warn about changes"
  assert_contains "$output" "cancelled" "Should show cancellation"

  teardown
}

# Test: release creates proper changelog entries
test_release_changelog_content() {
  setup

  cat >"$TEST_ENV_DIR/arty.yml" <<'EOF'
name: "test-project"
version: "1.0.0"
EOF

  git add arty.yml
  git commit -m "Add config" -q

  # Tag the initial version so we have a previous tag
  git tag v1.0.0

  echo "feature1" >feature1.txt
  git add feature1.txt
  git commit -m "feat: add feature 1" -q

  echo "fix1" >fix1.txt
  git add fix1.txt
  git commit -m "fix: resolve bug" -q

  # Now release - this should include commits since v1.0.0
  output=$(bash "$WHIP_SH" --config "$TEST_ENV_DIR/arty.yml" --no-push release 2>&1)

  if [[ ! -f "$WHIP_CHANGELOG" ]]; then
    echo "ERROR: Changelog not created!"
    echo "Output: $output"
    return 1
  fi

  changelog=$(cat "$WHIP_CHANGELOG")

  assert_contains "$changelog" "# Changelog" "Should have header"
  assert_contains "$changelog" "[1.0.1]" "Should have version"
  assert_contains "$changelog" "feat: add feature 1" "Should include feature"
  assert_contains "$changelog" "fix: resolve bug" "Should include fix"

  teardown
}

# Test: release preserves existing changelog
test_release_preserves_changelog() {
  setup

  cat >"$TEST_ENV_DIR/arty.yml" <<'EOF'
name: "test-project"
version: "1.0.0"
EOF

  git add arty.yml
  git commit -m "Add config" -q
  git tag v1.0.0

  # Create existing changelog
  cat >"$WHIP_CHANGELOG" <<'EOF'
# Changelog

## [1.0.0] - 2024-01-01

- Initial release
EOF

  echo "feature" >feature.txt
  git add feature.txt CHANGELOG.md
  git commit -m "feat: new feature" -q

  bash "$WHIP_SH" --config "$TEST_ENV_DIR/arty.yml" --no-push release 2>&1 >/dev/null

  changelog=$(cat "$WHIP_CHANGELOG")

  assert_contains "$changelog" "[1.0.1]" "Should have new version"
  assert_contains "$changelog" "[1.0.0]" "Should preserve old version"
  assert_contains "$changelog" "Initial release" "Should preserve old content"

  teardown
}

# Test: release creates annotated tag with message
test_release_tag_message() {
  setup

  cat >"$TEST_ENV_DIR/arty.yml" <<'EOF'
name: "test-project"
version: "1.0.0"
EOF

  git add arty.yml
  git commit -m "Add config" -q

  bash "$WHIP_SH" --config "$TEST_ENV_DIR/arty.yml" --no-push release 2>&1 >/dev/null

  # Check tag message
  message=$(git tag -l --format='%(contents)' v1.0.1)

  assert_contains "$message" "Release version 1.0.1" "Tag should have proper message"

  teardown
}

# Test: release commits both config and changelog
test_release_commits_both_files() {
  setup

  cat >"$TEST_ENV_DIR/arty.yml" <<'EOF'
name: "test-project"
version: "1.0.0"
EOF

  git add arty.yml
  git commit -m "Add config" -q

  bash "$WHIP_SH" --config "$TEST_ENV_DIR/arty.yml" --no-push release 2>&1 >/dev/null

  # Check that both files were in the release commit
files=$(git show --name-only --format="" HEAD)

assert_contains "$files" "arty.yml" "Should commit arty.yml"
assert_contains "$files" "CHANGELOG.md" "Should commit CHANGELOG.md"

teardown
}

# Test: consecutive releases work correctly
test_consecutive_releases() {
  setup

  cat >"$TEST_ENV_DIR/arty.yml" <<'EOF'
name: "test-project"
version: "1.0.0"
EOF

  git add arty.yml
  git commit -m "Add config" -q

  # First release
  bash "$WHIP_SH" --config "$TEST_ENV_DIR/arty.yml" --no-push release patch 2>&1 >/dev/null

  echo "feature" >feature.txt
  git add feature.txt
  git commit -m "feat: add feature" -q

  # Second release
  bash "$WHIP_SH" --config "$TEST_ENV_DIR/arty.yml" --no-push release patch 2>&1 >/dev/null

  version=$(yq eval '.version' "$TEST_ENV_DIR/arty.yml")
  assert_equals "1.0.2" "$version" "Should be at 1.0.2"

  # Check both tags exist
  git tag | grep -q "v1.0.1"
  assert_equals 0 $? "First tag should exist"

  git tag | grep -q "v1.0.2"
  assert_equals 0 $? "Second tag should exist"

  teardown
}

# Test: release with custom config file
test_release_custom_config() {
  setup

  cat >"$TEST_ENV_DIR/custom.yml" <<'EOF'
name: "test-project"
version: "1.0.0"
EOF

  git add custom.yml
  git commit -m "Add config" -q

  output=$(bash "$WHIP_SH" --config "$TEST_ENV_DIR/custom.yml" --no-push release 2>&1)

  assert_contains "$output" "2.0.1" "Should use custom config"

  teardown
}

# Test: release with custom changelog file
test_release_custom_changelog() {
  setup

  cat >"$TEST_ENV_DIR/arty.yml" <<'EOF'
name: "test-project"
version: "1.0.0"
EOF

  git add arty.yml
  git commit -m "Add config" -q

  bash "$WHIP_SH" --config "$TEST_ENV_DIR/arty.yml" --changelog "$TEST_ENV_DIR/CUSTOM.md" --no-push release 2>&1 >/dev/null

  assert_file_exists "$TEST_ENV_DIR/CUSTOM.md" "Should create custom changelog"

  teardown
}

# Run all tests
run_tests() {
  test_release_patch
  test_release_minor
  test_release_major
  test_release_default_patch
  test_release_uncommitted_changes
  test_release_changelog_content
  test_release_preserves_changelog
  test_release_tag_message
  test_release_commits_both_files
  test_consecutive_releases
  test_release_custom_config
  test_release_custom_changelog
}

export -f run_tests
