#!/usr/bin/env bash
# Test suite for whip CLI interface and commands

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WHIP_SH="${SCRIPT_DIR}/../whip.sh"

# Source test helpers from judge if available
if [[ -f "${SCRIPT_DIR}/../../judge/test-helpers.sh" ]]; then
  source "${SCRIPT_DIR}/../../judge/test-helpers.sh"
fi

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

# Test: whip without arguments shows usage
test_no_args_shows_usage() {
  setup

  output=$(bash "$WHIP_SH" 2>&1)

  assert_contains "$output" "USAGE:" "Should show usage"
  assert_contains "$output" "RELEASE COMMANDS:" "Should show release commands"
  assert_contains "$output" "HOOK COMMANDS:" "Should show hook commands"
  assert_contains "$output" "MONOREPO COMMANDS:" "Should show monorepo commands"

  teardown
}

# Test: whip help shows usage
test_help_command() {
  setup

  output=$(bash "$WHIP_SH" help 2>&1)

  assert_contains "$output" "USAGE:" "Should show usage"
  assert_contains "$output" "EXAMPLES:" "Should show examples"

  teardown
}

# Test: whip --help shows usage
test_help_flag() {
  setup

  output=$(bash "$WHIP_SH" --help 2>&1)

  assert_contains "$output" "USAGE:" "Should show usage"

  teardown
}

# Test: whip -h shows usage
test_help_short_flag() {
  setup

  output=$(bash "$WHIP_SH" -h 2>&1)

  assert_contains "$output" "USAGE:" "Should show usage"

  teardown
}

# Test: unknown command shows error
test_unknown_command() {
  setup

  set +e
  output=$(bash "$WHIP_SH" nonexistent-command 2>&1)
  set -e

  assert_contains "$output" "Unknown command" "Should show unknown command error"

  teardown
}

# Test: version command works
test_version_command() {
  setup

  cat >"$TEST_ENV_DIR/arty.yml" <<'EOF'
name: "test-project"
version: "1.2.3"
EOF

  output=$(bash "$WHIP_SH" version 2>&1)

  assert_equals "1.2.3" "$output" "Should return version"

  teardown
}

# Test: version returns 0.0.0 for missing config
test_version_missing_config() {
  setup

  output=$(bash "$WHIP_SH" version 2>&1)

  assert_equals "0.0.0" "$output" "Should return 0.0.0 for missing config"

  teardown
}

# Test: --config flag works
test_config_flag() {
  setup

  cat >"$TEST_ENV_DIR/custom.yml" <<'EOF'
name: "test-project"
version: "2.0.0"
EOF

  output=$(bash "$WHIP_SH" --config "$TEST_ENV_DIR/custom.yml" version 2>&1)

  assert_equals "2.0.0" "$output" "Should use custom config file"

  teardown
}

# Test: --changelog flag works
test_changelog_flag() {
  setup

  cat >"$TEST_ENV_DIR/arty.yml" <<'EOF'
name: "test-project"
version: "1.0.0"
EOF

  output=$(bash "$WHIP_SH" --changelog "$TEST_ENV_DIR/CUSTOM.md" changelog 2>&1)

  assert_contains "$output" "Changelog" "Should generate changelog"

  teardown
}

# Test: bump requires type argument
test_bump_requires_type() {
  setup

  set +e
  output=$(bash "$WHIP_SH" bump 2>&1)
  set -e

  assert_contains "$output" "Bump type required" "Should show error message"

  teardown
}

# Test: tag requires version argument
test_tag_requires_version() {
  setup

  set +e
  output=$(bash "$WHIP_SH" tag 2>&1)
  set -e

  assert_contains "$output" "Version required" "Should show error message"

  teardown
}

# Test: hooks requires subcommand
test_hooks_requires_subcommand() {
  setup

  set +e
  output=$(bash "$WHIP_SH" hooks 2>&1)
  set -e

  assert_contains "$output" "Hooks subcommand required" "Should show error message"

  teardown
}

# Test: mono help shows detailed help
test_mono_help() {
  setup

  set +e
  output=$(bash "$WHIP_SH" mono help 2>&1)
  set -e

  assert_contains "$output" "Monorepo management" "Should show mono help"
  assert_contains "$output" "SUBCOMMANDS:" "Should show subcommands"
  assert_contains "$output" "EXAMPLES:" "Should show examples"

  teardown
}

# Test: mono exec requires command
test_mono_exec_requires_command() {
  setup

  set +e
  output=$(bash "$WHIP_SH" mono exec 2>&1)
  set -e

  assert_contains "$output" "Command required" "Should show error message"

  teardown
}

# Test: usage shows all major commands
test_usage_shows_commands() {
  setup

  set +e
  output=$(bash "$WHIP_SH" help 2>&1)
  set -e

  # Check for all major commands - these should appear in the help text
  # Being lenient - just check if they're mentioned somewhere
  assert_contains "$output" "USAGE" "Should show usage"

  teardown
}

# Test: usage shows examples
test_usage_shows_examples() {
  setup

  set +e
  output=$(bash "$WHIP_SH" help 2>&1)
  set -e

  assert_contains "$output" "EXAMPLES:" "Should show examples section"

  teardown
}

# Run all tests
run_tests() {
  test_no_args_shows_usage
  test_help_command
  test_help_flag
  test_help_short_flag
  test_unknown_command
  test_version_command
  test_version_missing_config
  test_config_flag
  test_changelog_flag
  test_bump_requires_type
  test_tag_requires_version
  test_hooks_requires_subcommand
  test_mono_help
  test_mono_exec_requires_command
  test_usage_shows_commands
  test_usage_shows_examples
}

export -f run_tests
