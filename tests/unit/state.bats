#!/usr/bin/env bats

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

# Unit tests for src/lib/state.sh.

setup() {
  load '../test_helper.bash'
  common_setup
  export KSTACK_ROOT="$TMPDIR_TEST/kstack"
  mkdir -p "$KSTACK_ROOT"
  export KSTACK_KUBE_CONTEXT="test-ctx"
  # shellcheck source=../../lib/state.sh
  . "$SRC_ROOT/lib/state.sh"
}

@test "init: creates state dir under KSTACK_ROOT" {
  state::init
  [ "$STATE_DIR" = "$KSTACK_ROOT/state" ]
  [ -d "$STATE_DIR" ]
}

@test "init: errors when KSTACK_ROOT is unset" {
  unset KSTACK_ROOT
  state::init && rc=0 || rc=$?
  [ "$rc" -ne 0 ]
  [ "$STATE_ERROR_KIND" = "infra" ]
  [[ "$STATE_ERROR" == *"KSTACK_ROOT"* ]]
}

@test "init_context: creates per-context subdir" {
  state::init_context
  [ -n "$STATE_CONTEXT_DIR" ]
  [ -d "$STATE_CONTEXT_DIR" ]
  [[ "$STATE_CONTEXT_DIR" == "$KSTACK_ROOT/state/contexts/"* ]]
}

@test "init_context: same context -> same dir" {
  state::init_context
  local first="$STATE_CONTEXT_DIR"
  state::init_context
  [ "$STATE_CONTEXT_DIR" = "$first" ]
}

@test "init_context: different context -> different dir" {
  state::init_context
  local first="$STATE_CONTEXT_DIR"
  export KSTACK_KUBE_CONTEXT="other-ctx"
  state::init_context
  [ "$STATE_CONTEXT_DIR" != "$first" ]
}

@test "init_context: errors when KSTACK_KUBE_CONTEXT is unset" {
  unset KSTACK_KUBE_CONTEXT
  state::init_context && rc=0 || rc=$?
  [ "$rc" -ne 0 ]
  [ "$STATE_ERROR_KIND" = "infra" ]
  [[ "$STATE_ERROR" == *"KSTACK_KUBE_CONTEXT"* ]]
}

@test "set + get: round-trip global scope" {
  state::init
  state::set global mykey myvalue
  [ "$(state::get global mykey)" = "myvalue" ]
}

@test "set + get: round-trip context scope" {
  state::init_context
  state::set context mykey myvalue
  [ "$(state::get context mykey)" = "myvalue" ]
}

@test "set: namespaced keys create subdirs" {
  state::init
  state::set global audit-outdated/deprecated-apis-backend pluto
  [ -f "$STATE_DIR/audit-outdated/deprecated-apis-backend" ]
  [ "$(state::get global audit-outdated/deprecated-apis-backend)" = "pluto" ]
}

@test "get: returns empty string for unset key" {
  state::init
  run state::get global nope
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "has: returns true when key exists, false otherwise" {
  state::init
  state::set global exists yes
  state::has global exists
  ! state::has global missing
}

@test "get: reads only the first line of a multi-line file" {
  state::init
  printf 'first\nsecond\n' > "$STATE_DIR/multi"
  [ "$(state::get global multi)" = "first" ]
}

@test "set: atomic write (no .tmp left behind on success)" {
  state::init
  state::set global atomic val
  [ ! -e "$STATE_DIR/atomic.tmp" ]
  [ -f "$STATE_DIR/atomic" ]
}

@test "set: overwrites existing value" {
  state::init
  state::set global k first
  state::set global k second
  [ "$(state::get global k)" = "second" ]
}

@test "unset: removes a key" {
  state::init
  state::set global gone now
  state::unset global gone
  ! state::has global gone
}

@test "unset: succeeds when key does not exist" {
  state::init
  run state::unset global never-was
  [ "$status" -eq 0 ]
}

@test "scope isolation: global and context don't collide" {
  state::init_context
  state::set global shared g-value
  state::set context shared c-value
  [ "$(state::get global shared)" = "g-value" ]
  [ "$(state::get context shared)" = "c-value" ]
}

@test "get: rejects unknown scope" {
  state::init
  run state::get bogus key
  [ "$status" -ne 0 ]
}

@test "set: rejects context scope before init_context" {
  state::init
  run state::set context k v
  [ "$status" -ne 0 ]
}

@test "init_context: calling state::init afterward doesn't wipe context state" {
  state::init_context
  state::set context k v
  state::init  # global-only re-init
  [ "$(state::get context k)" = "v" ]
}
