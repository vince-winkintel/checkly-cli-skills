#!/bin/bash
# Test project definitions, then let Checkly present and confirm its deploy plan.
# Exit 3 means confirmation is required in CI/agent mode; 2 means invalid input.

set -e

echo "Testing checks in the Checkly runtime..." >&2
if npx checkly test; then
  echo "Checks passed. Reviewing the deployment plan..." >&2
else
  status=$?
  echo "Checks did not pass; nothing was deployed." >&2
  exit "$status"
fi

# Preserve upstream stdout and status, including confirmation_required / exit 3.
# The CLI owns confirmation so the user approves the actual plan.
npx checkly deploy
