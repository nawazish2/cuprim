#!/usr/bin/env bash
# Dev build: package debug .app and launch.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export CONFIG=debug
export LAUNCH=1
exec "$ROOT/script/package_app.sh"
