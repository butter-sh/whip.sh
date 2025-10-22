#!/usr/bin/env bash
# Test suite for whip git tag operations

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WHIP_SH="${SCRIPT_DIR}/../whip.sh"

# Setup before each test
setup() {
  TEST_ENV_DIR=$(create_test_env)
  export WHIP_CONFIG_FILE="$TEST_ENV_DIR/arty.yml"
  cd "$TEST_ENV_DIR"

  # Initialize git repo
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"

  # Create initial commit
  echo "test" >file.txt
  git add file.txt
  git commit -m "Initial commit" -q
}

# Cleanup after each test
teardown() {
  cleanup_test_env
}

# Test: create_release_tag creates annotated tag
test_create_release_tag() {
  setup

  cat >"$TEST_ENV_DIR/test_tag.sh" <<'EOF'
#!/usr/bin/env bash
source "${1}"
create_release_tag "1.0.0" "Release version 1.0.0" "false"
EOF

  bash "$TEST_ENV_DIR/test_tag.sh" "$WHIP_SH" 2>&1

  # Check if tag exists
  git tag | grep -q "v1.0.0"
  assert_equals 0 $? "Tag should exist"

  # Check if it's annotated
  git cat-file -t v1.0.0 | grep -q "tag"
  assert_equals 0 $? "Tag should be annotated"

  teardown
}

# Test: create_release_tag with v prefix
test_create_release_tag_v_prefix() {
  setup

  cat >"$TEST_ENV_DIR/test_tag.sh" <<'EOF'
#!/usr/bin/env bash
source "${1}"
create_release_tag "2.0.0" "Release" "false"
EOF

  bash "$TEST_ENV_DIR/test_tag.sh" "$WHIP_SH" 2>&1

  # Should create v2.0.0 tag
  git tag | grep -q "v2.0.0"
  assert_equals 0 $? "Tag should have v prefix"

  teardown
}

# Test: create_release_tag fails for duplicate tag
test_create_release_tag_duplicate() {
  setup

  git tag v1.0.0

  cat >"$TEST_ENV_DIR/test_tag.sh" <<'EOF'
#!/usr/bin/env bash
source "${1}"
set +e
create_release_tag "1.0.0" "Release" "false" 2>&1
exit_code=$?
set -e
exit $exit_code
EOF

  set +e
  bash "$TEST_ENV_DIR/test_tag.sh" "$WHIP_SH" >/dev/null 2>&1
  exit_code=$?
  set -e

  assert_true "[[ $exit_code -ne 0 ]]" "Should fail for duplicate tag"

  teardown
}

# Test: create_release_tag includes message
test_create_release_tag_message() {
  setup

  cat >"$TEST_ENV_DIR/test_tag.sh" <<'EOF'
#!/usr/bin/env bash
source "${1}"
create_release_tag "1.0.0" "Custom release message" "false"
EOF

  bash "$TEST_ENV_DIR/test_tag.sh" "$WHIP_SH" 2>&1

  # Get tag message
  message=$(git tag -l --format='%(contents)' v1.0.0)

  assert_contains "$message" "Custom release message" "Tag should have custom message"

  teardown
}

# Test: tag command via CLI
test_tag_command_cli() {
  setup

  cat >"$TEST_ENV_DIR/arty.yml" <<'EOF'
name: "test-project"
version: "1.0.0"
EOF

  output=$(bash "$WHIP_SH" --config "$TEST_ENV_DIR/arty.yml" --no-push tag 1.0.0 2>&1)

  assert_contains "$output" "Created tag" "Should create tag"

  git tag | grep -q "v1.0.0"
  assert_equals 0 $? "Tag should exist"

  teardown
}

# Test: tag command with custom message
test_tag_command_custom_message() {
  setup

  cat >"$TEST_ENV_DIR/arty.yml" <<'EOF'
name: "test-project"
version: "1.0.0"
EOF

  output=$(bash "$WHIP_SH" --config "$TEST_ENV_DIR/arty.yml" --no-push tag 1.0.0 "My custom message" 2>&1)

  message=$(git tag -l --format='%(contents)' v1.0.0)
  assert_contains "$message" "My custom message" "Should use custom message"

  teardown
}

# Test: --no-push prevents pushing
test_no_push_flag() {
  setup

  cat >"$TEST_ENV_DIR/arty.yml" <<'EOF'
name: "test-project"
version: "1.0.0"
EOF

  # This should not fail even without a remote
  bash "$WHIP_SH" --config "$TEST_ENV_DIR/arty.yml" --no-push tag 1.0.0 2>&1

  git tag | grep -q "v1.0.0"
  assert_equals 0 $? "Tag should exist locally"

  teardown
}

# Run all tests
run_tests() {
  test_create_release_tag
  test_create_release_tag_v_prefix
  test_create_release_tag_duplicate
  test_create_release_tag_message
  test_tag_command_cli
  test_tag_command_custom_message
  test_no_push_flag
}

export -f run_tests
