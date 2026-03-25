#!/usr/bin/env bash
# Run this once after creating the GitHub repo to set description and topics.
# Requires: gh CLI (https://cli.github.com), authenticated with `gh auth login`

set -e

REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo 'YOUR_ORG/sei-code-examples')"

echo "Setting description and topics for $REPO ..."

gh repo edit "$REPO" \
  --description "Complete, runnable code examples from Sei EVM docs — structured for developers and AI" \
  --add-topic sei \
  --add-topic evm \
  --add-topic solidity \
  --add-topic blockchain \
  --add-topic web3 \
  --add-topic examples \
  --add-topic developer-tools \
  --add-topic smart-contracts \
  --add-topic defi

echo "Done."
echo ""
echo "Verify at: https://github.com/$REPO"
