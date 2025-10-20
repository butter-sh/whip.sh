#!/usr/bin/env bash
# Test configuration for whip.sh test suite
# This file is sourced by test files to set common configuration

export TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Test directory structure
export WHIP_SH_ROOT="$PWD"

# Test behavior flags
export WHIP_TEST_MODE=1

# Color output in tests (set to 0 to disable)
export WHIP_TEST_COLORS=1
