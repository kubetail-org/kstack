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

# shellcheck shell=bash
# kstack agent table — shared between install, uninstall, and test suite.
#
# Source this file; do not execute it.
# Requires $HOME to be set before agent_skills_dir_global is called.

KNOWN_AGENTS="claude codex opencode cursor factory slate kiro hermes pi"

# agent_cli: CLI binary to probe for auto-detect
agent_cli() {
  case "$1" in
    claude)   echo claude ;;
    codex)    echo codex ;;
    opencode) echo opencode ;;
    cursor)   echo cursor ;;
    factory)  echo droid ;;
    slate)    echo slate ;;
    kiro)     echo kiro-cli ;;
    hermes)   echo hermes ;;
    pi)       echo pi ;;
    *)        return 1 ;;
  esac
}

# agent_skills_dir_global: where the agent reads skills from (user-level)
agent_skills_dir_global() {
  case "$1" in
    claude)   echo "$HOME/.claude/skills" ;;
    codex)    echo "$HOME/.codex/skills" ;;
    opencode) echo "$HOME/.config/opencode/skills" ;;
    cursor)   echo "$HOME/.cursor/skills" ;;
    factory)  echo "$HOME/.factory/skills" ;;
    slate)    echo "$HOME/.slate/skills" ;;
    kiro)     echo "$HOME/.kiro/skills" ;;
    hermes)   echo "$HOME/.hermes/skills" ;;
    pi)       echo "$HOME/.pi/agent/skills" ;;
    *)        return 1 ;;
  esac
}

# agent_skills_dir_local: where the agent reads skills from (repo-level)
# Args: $1 = repo root, $2 = agent name
agent_skills_dir_local() {
  local root="$1"
  case "$2" in
    claude)   echo "$root/.claude/skills" ;;
    codex)    echo "$root/.codex/skills" ;;
    opencode) echo "$root/.config/opencode/skills" ;;
    cursor)   echo "$root/.cursor/skills" ;;
    factory)  echo "$root/.factory/skills" ;;
    slate)    echo "$root/.slate/skills" ;;
    kiro)     echo "$root/.kiro/skills" ;;
    hermes)   echo "$root/.hermes/skills" ;;
    pi)       echo "$root/.pi/skills" ;;
    *)        return 1 ;;
  esac
}

is_known_agent() {
  case " $KNOWN_AGENTS " in *" $1 "*) return 0 ;; esac
  return 1
}
