#!/usr/bin/env bash
set -euo pipefail

echo "==> Running standard-version..."
bunx standard-version

echo "==> Updating flake.lock..."
nix flake update

echo "==> Committing flake.lock update..."
git add flake.lock
git commit -m "chore: update flake.lock"

echo "==> Pushing..."
git push
git push --tags

echo "==> Release complete!"
