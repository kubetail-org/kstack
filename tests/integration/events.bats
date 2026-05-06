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

setup() {
  load '../test_helper.bash'
  common_setup
  export KSTACK_ROOT="$TMPDIR_TEST/kstack"
  mkdir -p "$KSTACK_ROOT/lib"
  cp "$SRC_ROOT/lib/response.sh"   "$KSTACK_ROOT/lib/"
  cp "$SRC_ROOT/lib/kube-cache.sh" "$KSTACK_ROOT/lib/"
  cp "$SRC_ROOT/lib/hash.sh"       "$KSTACK_ROOT/lib/"
  export KSTACK_KUBE_CONTEXT="test-ctx"
  export KSTACK_SKILL_NAME="events"
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Write a fixture events.json to the per-context cache dir so the kubectl
# stub isn't needed when testing rendering logic on a pre-seeded cache.
# The file's mtime is backdated 2 minutes so freshness detection is reliable
# (avoids same-second race between cp and snapshot_start).
seed_cache() {
  local json_file="$1"
  # shellcheck source=/dev/null
  . "$KSTACK_ROOT/lib/hash.sh"
  local sha cache_dir
  sha="$(hash::short_sha "$KSTACK_KUBE_CONTEXT")"
  cache_dir="$KSTACK_ROOT/cache/kube/$sha"
  mkdir -p "$cache_dir"
  cp "$json_file" "$cache_dir/events.json"
  # Backdate so mtime < snapshot_start in the script (same-second ambiguity fix)
  touch -t "$(date -d '2 minutes ago' '+%Y%m%d%H%M' 2>/dev/null \
    || date -v-2M '+%Y%m%d%H%M')" "$cache_dir/events.json" 2>/dev/null || true
}

# Return the per-context cache dir path.
cache_dir_for_ctx() {
  # shellcheck source=/dev/null
  . "$KSTACK_ROOT/lib/hash.sh"
  local sha
  sha="$(hash::short_sha "$KSTACK_KUBE_CONTEXT")"
  printf '%s/cache/kube/%s\n' "$KSTACK_ROOT" "$sha"
}

# ---------------------------------------------------------------------------
# Static checks
# ---------------------------------------------------------------------------

@test "main script exists and is executable" {
  [ -x "$SRC_ROOT/skills/events/scripts/main" ]
}

# ---------------------------------------------------------------------------
# Error paths — no kubectl needed
# ---------------------------------------------------------------------------

@test "main: rejects --context (entrypoint owns resolution)" {
  run "$SRC_ROOT/skills/events/scripts/main" --context=foo
  [ "$status" -eq 0 ]
  [[ "$output" == *'"status":"error"'* ]]
  [[ "$output" == *'"kind":"user"'* ]]
  [[ "$output" == *"Unknown flag"* ]]
}

@test "main: rejects unknown flag" {
  run "$SRC_ROOT/skills/events/scripts/main" --bogus
  [ "$status" -eq 0 ]
  [[ "$output" == *'"status":"error"'* ]]
  [[ "$output" == *'"kind":"user"'* ]]
  [[ "$output" == *"Unknown flag"* ]]
}

@test "main: requires KSTACK_KUBE_CONTEXT env var" {
  unset KSTACK_KUBE_CONTEXT
  run "$SRC_ROOT/skills/events/scripts/main"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"status":"error"'* ]]
  [[ "$output" == *'"kind":"infra"'* ]]
  [[ "$output" == *"KSTACK_KUBE_CONTEXT"* ]]
}

@test "main: --ttl requires a value" {
  run "$SRC_ROOT/skills/events/scripts/main" --ttl
  [ "$status" -eq 0 ]
  [[ "$output" == *'"status":"error"'* ]]
  [[ "$output" == *'"kind":"user"'* ]]
  [[ "$output" == *"--ttl requires a value"* ]]
}

@test "main: invalid --ttl returns user error" {
  use_mocks
  write_stub kubectl 'printf '"'"'{"items":[]}'"'"'\n'
  run "$SRC_ROOT/skills/events/scripts/main" --ttl=notaduration
  [ "$status" -eq 0 ]
  [[ "$output" == *'"status":"error"'* ]]
  [[ "$output" == *'"kind":"user"'* ]]
}

@test "main: kubectl failure returns infra error" {
  use_mocks
  write_stub kubectl 'exit 1'
  run "$SRC_ROOT/skills/events/scripts/main"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"status":"error"'* ]]
  [[ "$output" == *'"kind":"infra"'* ]]
  [[ "$output" == *"Unable to fetch events"* ]]
}

# ---------------------------------------------------------------------------
# Rendering — kubectl stub returns fixture JSON
# ---------------------------------------------------------------------------

@test "main: clean cluster emits ok/verbatim with 'none' summary" {
  local fixture="$TMPDIR_TEST/empty_events.json"
  printf '{"items":[]}\n' > "$fixture"
  use_mocks
  write_stub kubectl "cat '$fixture'"
  run "$SRC_ROOT/skills/events/scripts/main"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"status":"ok"'* ]]
  [[ "$output" == *'"render":"verbatim"'* ]]
  [[ "$output" == *'none'* ]]
}

@test "main: Warning events appear as WARN rows" {
  local fixture="$TMPDIR_TEST/warn_events.json"
  cat > "$fixture" << 'EOF'
{"items":[
  {"type":"Warning","reason":"BackOff",
   "involvedObject":{"kind":"Pod","name":"checkout-7c9"},
   "metadata":{"namespace":"payments"},
   "count":14,"lastTimestamp":"2026-01-01T10:00:00Z",
   "firstTimestamp":"2026-01-01T09:00:00Z",
   "message":"Back-off restarting failed container"}
]}
EOF
  use_mocks
  write_stub kubectl "cat '$fixture'"
  run "$SRC_ROOT/skills/events/scripts/main"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"status":"ok"'* ]]
  [[ "$output" == *'WARN'* ]]
  [[ "$output" == *'BackOff'* ]]
  [[ "$output" == *'payments'* ]]
  [[ "$output" == *'14'* ]]
  [[ "$output" == *'warning group'* ]]
}

@test "main: notable Normal events appear as NOTE rows" {
  local fixture="$TMPDIR_TEST/note_events.json"
  cat > "$fixture" << 'EOF'
{"items":[
  {"type":"Normal","reason":"NodeNotReady",
   "involvedObject":{"kind":"Node","name":"ip-10-0-3-14"},
   "metadata":{"namespace":"kube-system"},
   "count":1,"lastTimestamp":"2026-01-01T10:00:00Z",
   "firstTimestamp":"2026-01-01T10:00:00Z",
   "message":"Node ip-10-0-3-14 status is now: NodeNotReady"}
]}
EOF
  use_mocks
  write_stub kubectl "cat '$fixture'"
  run "$SRC_ROOT/skills/events/scripts/main"
  [ "$status" -eq 0 ]
  [[ "$output" == *'NOTE'* ]]
  [[ "$output" == *'NodeNotReady'* ]]
  [[ "$output" == *'1 notable'* ]]
}

@test "main: chatty Normal events are suppressed and counted" {
  local fixture="$TMPDIR_TEST/chatty_events.json"
  cat > "$fixture" << 'EOF'
{"items":[
  {"type":"Normal","reason":"Pulled",
   "involvedObject":{"kind":"Pod","name":"app-abc"},
   "metadata":{"namespace":"default"},
   "count":50,"lastTimestamp":"2026-01-01T10:00:00Z",
   "firstTimestamp":"2026-01-01T09:00:00Z",
   "message":"Successfully pulled image"},
  {"type":"Normal","reason":"Created",
   "involvedObject":{"kind":"Pod","name":"app-abc"},
   "metadata":{"namespace":"default"},
   "count":50,"lastTimestamp":"2026-01-01T10:00:00Z",
   "firstTimestamp":"2026-01-01T09:00:00Z",
   "message":"Created container app"},
  {"type":"Normal","reason":"Started",
   "involvedObject":{"kind":"Pod","name":"app-abc"},
   "metadata":{"namespace":"default"},
   "count":50,"lastTimestamp":"2026-01-01T10:00:00Z",
   "firstTimestamp":"2026-01-01T09:00:00Z",
   "message":"Started container app"}
]}
EOF
  use_mocks
  write_stub kubectl "cat '$fixture'"
  run "$SRC_ROOT/skills/events/scripts/main"
  [ "$status" -eq 0 ]
  [[ "$output" == *'suppressed'* ]]
  [[ "$output" == *'none'* ]]
  # No WARN or NOTE rows for chatty reasons
  [[ "$output" != *'"WARN"'* ]]
  [[ "$output" != *'"NOTE"'* ]]
}

@test "main: mixed events -- warn, note, and suppressed all appear" {
  local fixture="$TMPDIR_TEST/mixed_events.json"
  cat > "$fixture" << 'EOF'
{"items":[
  {"type":"Warning","reason":"BackOff",
   "involvedObject":{"kind":"Pod","name":"checkout-7c9"},
   "metadata":{"namespace":"payments"},
   "count":14,"lastTimestamp":"2026-01-01T10:00:00Z",
   "firstTimestamp":"2026-01-01T09:00:00Z",
   "message":"Back-off restarting failed container"},
  {"type":"Normal","reason":"NodeNotReady",
   "involvedObject":{"kind":"Node","name":"ip-10-0-3-14"},
   "metadata":{"namespace":"kube-system"},
   "count":1,"lastTimestamp":"2026-01-01T09:55:00Z",
   "firstTimestamp":"2026-01-01T09:55:00Z",
   "message":"Node ip-10-0-3-14 status is now: NodeNotReady"},
  {"type":"Normal","reason":"Pulled",
   "involvedObject":{"kind":"Pod","name":"app-abc"},
   "metadata":{"namespace":"default"},
   "count":200,"lastTimestamp":"2026-01-01T10:00:00Z",
   "firstTimestamp":"2026-01-01T08:00:00Z",
   "message":"Successfully pulled image"}
]}
EOF
  use_mocks
  write_stub kubectl "cat '$fixture'"
  run "$SRC_ROOT/skills/events/scripts/main"
  [ "$status" -eq 0 ]
  [[ "$output" == *'WARN'* ]]
  [[ "$output" == *'NOTE'* ]]
  [[ "$output" == *'suppressed'* ]]
  [[ "$output" == *'1 warning group'* ]]
  [[ "$output" == *'1 notable'* ]]
}

@test "main: envelope carries agent_context with cache_dir" {
  local fixture="$TMPDIR_TEST/empty_events.json"
  printf '{"items":[]}\n' > "$fixture"
  use_mocks
  write_stub kubectl "cat '$fixture'"
  run "$SRC_ROOT/skills/events/scripts/main"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"agent_context"'* ]]
  [[ "$output" == *'cache_dir'* ]]
}

@test "main: envelope carries kube_context" {
  local fixture="$TMPDIR_TEST/empty_events.json"
  printf '{"items":[]}\n' > "$fixture"
  use_mocks
  write_stub kubectl "cat '$fixture'"
  run "$SRC_ROOT/skills/events/scripts/main"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"kube_context"'* ]]
  [[ "$output" == *'test-ctx'* ]]
}

# ---------------------------------------------------------------------------
# Cache behavior
# ---------------------------------------------------------------------------

@test "main: reuses cached events.json within TTL (no kubectl call)" {
  # Pre-seed cache so kubectl won't be called
  local fixture="$TMPDIR_TEST/cached_events.json"
  printf '{"items":[]}\n' > "$fixture"
  seed_cache "$fixture"

  use_mocks
  local call_log="$TMPDIR_TEST/kubectl_calls"
  write_stub kubectl "echo called >> '$call_log'"

  run "$SRC_ROOT/skills/events/scripts/main" --ttl=1h
  [ "$status" -eq 0 ]
  [[ "$output" == *'"status":"ok"'* ]]
  # kubectl should not have been called since cache is fresh
  [ ! -f "$call_log" ]
}

@test "main: --refresh bypasses fresh cache and calls kubectl" {
  # Pre-seed a fresh cache
  local fixture="$TMPDIR_TEST/cached_events.json"
  printf '{"items":[]}\n' > "$fixture"
  seed_cache "$fixture"

  use_mocks
  local call_log="$TMPDIR_TEST/kubectl_calls"
  write_stub kubectl "
echo called >> '$call_log'
printf '{\"items\":[]}\n'
"

  run "$SRC_ROOT/skills/events/scripts/main" --refresh
  [ "$status" -eq 0 ]
  [[ "$output" == *'"status":"ok"'* ]]
  # kubectl must have been called despite fresh cache
  [ -f "$call_log" ]
}

@test "main: stale cache triggers re-fetch" {
  # Pre-seed a cache file with an old mtime
  local fixture="$TMPDIR_TEST/stale_events.json"
  printf '{"items":[]}\n' > "$fixture"
  seed_cache "$fixture"

  local cache_dir
  cache_dir="$(cache_dir_for_ctx)"
  # Force the mtime to be 10 minutes old so the default TTL=5m is exceeded
  touch -t "$(date -d '10 minutes ago' '+%Y%m%d%H%M' 2>/dev/null || date -v-10M '+%Y%m%d%H%M')" \
    "$cache_dir/events.json" 2>/dev/null || true

  use_mocks
  local call_log="$TMPDIR_TEST/kubectl_calls"
  write_stub kubectl "
echo called >> '$call_log'
printf '{\"items\":[]}\n'
"

  run "$SRC_ROOT/skills/events/scripts/main" --ttl=5m
  [ "$status" -eq 0 ]
  [ -f "$call_log" ]
}

@test "main: freshness line says 'Snapshot cached' on fresh fetch" {
  local fixture="$TMPDIR_TEST/empty_events.json"
  printf '{"items":[]}\n' > "$fixture"
  use_mocks
  write_stub kubectl "cat '$fixture'"
  run "$SRC_ROOT/skills/events/scripts/main"
  [ "$status" -eq 0 ]
  [[ "$output" == *'Snapshot cached'* ]]
}

@test "main: freshness line says 'Used cached snapshot' when cache was reused" {
  local fixture="$TMPDIR_TEST/cached_events.json"
  printf '{"items":[]}\n' > "$fixture"
  seed_cache "$fixture"

  run "$SRC_ROOT/skills/events/scripts/main" --ttl=1h
  [ "$status" -eq 0 ]
  [[ "$output" == *'Used cached snapshot'* ]]
}
