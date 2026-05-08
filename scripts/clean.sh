#!/usr/bin/env bash

# Copyright 2026 The Kubetail Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# scripts/clean.sh — wipe dev-mode install artifacts.
#
# For development. Removes the rendered skills directories, caches, and the
# legacy build dir from the kstack repo so you can re-run `make install`
# against a clean tree.
#
# Safe to run any time. Only touches paths that are gitignored.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Paths a dev-mode install (and older versions of it) can write into.
# Keep this list in sync with .gitignore.
PATHS="
  .claude
  .codex
  .config/opencode
  .cursor
  .factory
  .slate
  .kiro
  .hermes
  .pi/skills
  .kstack
  .build
"

main() {
  removed=0
  for p in $PATHS; do
    full="$REPO_ROOT/$p"
    if [ -e "$full" ]; then
      rm -rf "$full"
      echo "removed $p"
      removed=$((removed + 1))
    fi
  done

  if [ "$removed" -eq 0 ]; then
    echo "Nothing to clean."
  fi
}

if [ "${BASH_SOURCE[0]:-$0}" = "$0" ]; then
  main "$@"
fi
