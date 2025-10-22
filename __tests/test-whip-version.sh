#!/usr/bin/env bash
# Test suite for whip version management and semver operations

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WHIP_SH="${SCRIPT_DIR}/../whip.sh"

# Setup before each test
setup() {
  TEST_ENV_DIR=$(create_test_env)
  export WHIP_CONFIG_FILE="$TEST_ENV_DIR/arty.yml"
  cd "$TEST_ENV_DIR"
}

# Cleanup after each test
teardown() {
  cleanup_test_env
}

# Test: get_current_version reads from arty.yml
test_get_current_version() {
  setup

  cat >"$TEST_ENV_DIR/arty.yml" <<'EOF'
name: "test-project"
version: "1.2.3"
EOF

  cat >"$TEST_ENV_DIR/test_version.sh" <<'EOF'
#!/usr/bin/env bash
export WHIP_CONFIG="${1}"
source "${2}"
get_current_version
EOF

  output=$(bash "$TEST_ENV_DIR/test_version.sh" "$TEST_ENV_DIR/arty.yml" "$WHIP_SH")

  assert_equals "1.2.3" "$output" "Should read version from arty.yml"

  teardown
}

# Test: get_current_version returns 0.0.0 for missing file
test_get_current_version_missing() {
  setup

  cat >"$TEST_ENV_DIR/test_version.sh" <<'EOF'
#!/usr/bin/env bash
source "${1}"
get_current_version "nonexistent.yml"
EOF

  output=$(bash "$TEST_ENV_DIR/test_version.sh" "$WHIP_SH")

  assert_equals "0.0.0" "$output" "Should return 0.0.0 for missing file"

  teardown
}

# Test: get_current_version handles null version
test_get_current_version_null() {
  setup

  cat >"$TEST_ENV_DIR/arty.yml" <<'EOF'
name: "test-project"
version: null
EOF

  cat >"$TEST_ENV_DIR/test_version.sh" <<'EOF'
#!/usr/bin/env bash
export WHIP_CONFIG="${1}"
source "${2}"
get_current_version
EOF

  output=$(bash "$TEST_ENV_DIR/test_version.sh" "$TEST_ENV_DIR/arty.yml" "$WHIP_SH")

  assert_equals "0.0.0" "$output" "Should return 0.0.0 for null version"

  teardown
}

# Test: bump_version patch increments correctly
test_bump_patch() {
  setup

  cat >"$TEST_ENV_DIR/arty.yml" <<'EOF'
name: "test-project"
version: "1.2.3"
EOF

  output=$(bash "$WHIP_SH" --config "$TEST_ENV_DIR/arty.yml" bump patch 2>&1)

  assert_contains "$output" "1.2.4" "Should increment patch version"

  # Verify file was updated
  version=$(yq eval '.version' "$TEST_ENV_DIR/arty.yml")
  assert_equals "1.2.4" "$version" "Should update file"

  teardown
}

# Test: bump_version minor increments correctly and resets patch
test_bump_minor() {
  setup

  cat >"$TEST_ENV_DIR/arty.yml" <<'EOF'
name: "test-project"
version: "1.2.3"
EOF

  output=$(bash "$WHIP_SH" --config "$TEST_ENV_DIR/arty.yml" bump minor 2>&1)

  assert_contains "$output" "1.3.0" "Should increment minor and reset patch"

  teardown
}

# Test: bump_version major increments correctly and resets minor and patch
test_bump_major() {
  setup

  cat >"$TEST_ENV_DIR/arty.yml" <<'EOF'
name: "test-project"
version: "1.2.3"
EOF

  output=$(bash "$WHIP_SH" --config "$TEST_ENV_DIR/arty.yml" bump major 2>&1)

  assert_contains "$output" "2.0.0" "Should increment major and reset minor and patch"

  teardown
}

# Test: bump from 0.0.0
test_bump_from_zero() {
  setup

  cat >"$TEST_ENV_DIR/arty.yml" <<'EOF'
name: "test-project"
version: "0.0.0"
EOF

  output=$(bash "$WHIP_SH" --config "$TEST_ENV_DIR/arty.yml" bump patch 2>&1)
  assert_contains "$output" "0.0.1" "Should bump from 0.0.0 to 0.0.1"

  output=$(bash "$WHIP_SH" --config "$TEST_ENV_DIR/arty.yml" bump minor 2>&1)
  assert_contains "$output" "0.1.0" "Should bump to 0.1.0"

  output=$(bash "$WHIP_SH" --config "$TEST_ENV_DIR/arty.yml" bump major 2>&1)
  assert_contains "$output" "1.0.0" "Should bump to 1.0.0"

  teardown
}

# Test: parse_version handles valid versions
test_parse_version() {
  setup

  cat >"$TEST_ENV_DIR/test_parse.sh" <<'EOF'
#!/usr/bin/env bash
source "${1}"

major=0
minor=0
patch=0

if parse_version "1.2.3" major minor patch; then
    echo "$major.$minor.$patch"
else
    echo "failed"
fi
EOF

  output=$(bash "$TEST_ENV_DIR/test_parse.sh" "$WHIP_SH")

  assert_equals "1.2.3" "$output" "Should parse version correctly"

  teardown
}

# Test: parse_version strips v prefix
test_parse_version_v_prefix() {
  setup

  cat >"$TEST_ENV_DIR/test_parse.sh" <<'EOF'
#!/usr/bin/env bash
source "${1}"

major=0
minor=0
patch=0

if parse_version "v1.2.3" major minor patch; then
    echo "$major.$minor.$patch"
else
    echo "failed"
fi
EOF

  output=$(bash "$TEST_ENV_DIR/test_parse.sh" "$WHIP_SH")

  assert_equals "1.2.3" "$output" "Should strip v prefix"

  teardown
}

# Test: parse_version rejects invalid versions
test_parse_version_invalid() {
  setup

  cat >"$TEST_ENV_DIR/test_parse.sh" <<'EOF'
#!/usr/bin/env bash
source "${1}"

major=0
minor=0
patch=0

if parse_version "invalid" major minor patch; then
    echo "success"
else
    echo "failed"
fi
EOF

  output=$(bash "$TEST_ENV_DIR/test_parse.sh" "$WHIP_SH")

  assert_equals "failed" "$output" "Should reject invalid version"

  teardown
}

# Test: update_version updates arty.yml
test_update_version() {
  setup

  cat >"$TEST_ENV_DIR/arty.yml" <<'EOF'
name: "test-project"
version: "1.0.0"
EOF

  cat >"$TEST_ENV_DIR/test_update.sh" <<'EOF'
#!/usr/bin/env bash
export WHIP_CONFIG="${1}"
source "${2}"
update_version "2.0.0" "${1}"
EOF

  bash "$TEST_ENV_DIR/test_update.sh" "$TEST_ENV_DIR/arty.yml" "$WHIP_SH" 2>&1

  version=$(yq eval '.version' "$TEST_ENV_DIR/arty.yml")
  assert_equals "2.0.0" "$version" "Should update version in file"

  teardown
}

# Test: update_version fails for missing config
test_update_version_missing_config() {
  setup

  cat >"$TEST_ENV_DIR/test_update.sh" <<'EOF'
#!/usr/bin/env bash
source "${1}"
update_version "2.0.0" "nonexistent.yml" 2>&1 || echo "failed"
EOF

  output=$(bash "$TEST_ENV_DIR/test_update.sh" "$WHIP_SH")

  assert_contains "$output" "Config file not found" "Should error on missing file"

  teardown
}

# Test: bump with invalid type fails
test_bump_invalid_type() {
  setup

  cat >"$TEST_ENV_DIR/arty.yml" <<'EOF'
name: "test-project"
version: "1.0.0"
EOF

  set +e
  output=$(bash "$WHIP_SH" bump invalid 2>&1)
  set -e

  # Check that error message is shown
  assert_contains "$output" "Invalid bump type" "Should show error message"

  teardown
}

# Test: bump handles large version numbers
test_bump_large_numbers() {
  setup

  cat >"$TEST_ENV_DIR/arty.yml" <<'EOF'
name: "test-project"
version: "99.99.99"
EOF

  output=$(bash "$WHIP_SH" --config "$TEST_ENV_DIR/arty.yml" bump patch 2>&1)
  assert_contains "$output" "99.99.100" "Should handle large patch"

  cat >"$TEST_ENV_DIR/arty.yml" <<'EOF'
name: "test-project"
version: "99.99.99"
EOF

  output=$(bash "$WHIP_SH" --config "$TEST_ENV_DIR/arty.yml" bump minor 2>&1)
  assert_contains "$output" "99.100.0" "Should handle large minor"

  cat >"$TEST_ENV_DIR/arty.yml" <<'EOF'
name: "test-project"
version: "99.99.99"
EOF

  output=$(bash "$WHIP_SH" --config "$TEST_ENV_DIR/arty.yml" bump major 2>&1)
  assert_contains "$output" "100.0.0" "Should handle large major"

  teardown
}

# Test: consecutive bumps work correctly
test_consecutive_bumps() {
  setup

  cat >"$TEST_ENV_DIR/arty.yml" <<'EOF'
name: "test-project"
version: "1.0.0"
EOF

  bash "$WHIP_SH" --config "$TEST_ENV_DIR/arty.yml" bump patch 2>&1 >/dev/null
  bash "$WHIP_SH" --config "$TEST_ENV_DIR/arty.yml" bump patch 2>&1 >/dev/null
  bash "$WHIP_SH" --config "$TEST_ENV_DIR/arty.yml" bump patch 2>&1 >/dev/null

  version=$(yq eval '.version' "$TEST_ENV_DIR/arty.yml")
  assert_equals "1.0.3" "$version" "Should handle consecutive bumps"

  teardown
}

# Run all tests
run_tests() {
  test_get_current_version
  test_get_current_version_missing
  test_get_current_version_null
  test_bump_patch
  test_bump_minor
  test_bump_major
  test_bump_from_zero
  test_parse_version
  test_parse_version_v_prefix
  test_parse_version_invalid
  test_update_version
  test_update_version_missing_config
  test_bump_invalid_type
  test_bump_large_numbers
  test_consecutive_bumps
}

export -f run_tests
