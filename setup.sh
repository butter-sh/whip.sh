#!/usr/bin/env bash
# Setup script for whip.sh

set -euo pipefail

echo "Setting up whip.sh..."

# Make whip.sh executable
chmod +x whip.sh

# Create .whip directory for hooks
mkdir -p .whip/hooks

echo "✓ Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Install git hooks: ./whip.sh hooks install"
echo "  2. Create a release: ./whip.sh release"
echo "  3. See help: ./whip.sh --help"
