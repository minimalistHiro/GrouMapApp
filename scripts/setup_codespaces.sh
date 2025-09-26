#!/usr/bin/env bash
set -euo pipefail

echo "[setup] Flutter pub get"
cd /workspaces && cd $(ls -1 | head -n1) 2>/dev/null || cd /workspaces
if [ -f "/workspaces/pubspec.yaml" ]; then
  (cd /workspaces && flutter pub get) || true
elif [ -f "/workspace/pubspec.yaml" ]; then
  (cd /workspace && flutter pub get) || true
fi

echo "[setup] Install functions deps with pnpm if present"
if [ -f "/workspace/backend/functions/package.json" ]; then
  cd /workspace/backend/functions
  pnpm install || true
fi

echo "[setup] Done"

