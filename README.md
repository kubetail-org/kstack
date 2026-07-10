# kstack

*Skill pack for Claude Code that helps you monitor your K8s clusters superintelligently*

<a href="https://discord.gg/CmsmWAVkvX"><img src="https://img.shields.io/discord/1212031524216770650?logo=Discord&style=flat-square&logoColor=FFFFFF&labelColor=5B65F0&label=Discord&color=64B73A"></a>
[![Slack](https://img.shields.io/badge/Slack-kubetail-364954?logo=slack&labelColor=4D1C51)](https://kubernetes.slack.com/archives/C08SHG1GR37)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](CODE_OF_CONDUCT.md)
[![Contributor Resources](https://img.shields.io/badge/Contributor%20Resources-purple?style=flat-square)](https://github.com/kubetail-org)

English | [简体中文](.github/README.zh-CN.md) | [日本語](.github/README.ja.md) | [한국어](.github/README.ko.md) | [Deutsch](.github/README.de.md) | [Español](.github/README.es.md) | [Português](.github/README.pt-BR.md) | [Français](.github/README.fr.md)

## Introduction

<img width="350" alt="kstack" src="https://github.com/user-attachments/assets/cfe998de-a85a-44bb-8eb2-5f5efe7449ea" />
<br>
<br>

**Kstack** is a skill pack for Claude Code that helps you perform monitoring, troubleshooting and auditing tasks on your K8s clusters in a smart and efficient way. In addition to using standard tools like `kubectl`, it hands off shell work to tools like [Kubetail](https://github.com/kubetail-org/kubetail), [Helm](https://helm.sh), [Trivy](https://github.com/aquasecurity/trivy), [Pluto](https://github.com/FairwindsOps/pluto) before sending results to Claude, keeping reponses fast and token efficient. Kstack also detects the services running in your cluster and uses their specialized tooling when necessary (e.g. [Cilium](https://cilium.io), [Istio](https://istio.io)).

Once you install kstack you'll have access to these skills inside Claude Code:

**Monitoring**
* `/cluster-status` — Health snapshot (pod restarts, node conditions, resource pressure)
* `/events` — Recent events, ranked by severity

**Troubleshooting**
* `/investigate` — Root-cause analysis across events, logs, and related resources
* `/logs` — Shared tmux session that translates natural language into log fetches and analysis (via [Kubetail](https://github.com/kubetail-org/kubetail))
* `/metrics` — Fetch CPU, memory, and other resource metrics for pods, nodes, and workloads
* `/exec` — Shared tmux shell into a pod, node, or ephemeral debug container

**Audits**
* `/audit-security` — RBAC, pod security posture, privilege tightening
* `/audit-network` — NetworkPolicy, Service, Ingress, GatewayAPI, DNS and encryption checks
* `/audit-cost` — Requests vs. usage, over-provisioning, idle capacity
* `/audit-outdated` — Outdated services, known CVEs, available version bumps

**Autoscaling**
* `/karpenter` — Karpenter provisioning health, node-claim diagnosis, consolidation/cost efficiency

**Miscellaneous**
* `/cleanup` — Remove all kstack-owned resources from the cluster (debug containers, pod clones, watcher jobs)
* `/forget` — Clear kstack's local cache and discard what it learned about your cluster(s)

Our goal is to bring the power of AI to K8s monitoring in a user-friendly and cost-effective way that keeps you in control. If you notice a bug or have a suggestion please create a GitHub Issue or send us an email (hello@kubetail.com)!

## Quickstart

To install the kstack skills globally, run this command:

```console
curl -sS https://kstack.sh/install | bash
```

Alternatively, you can install them locally inside a specific project directory:

```console
curl -sS https://kstack.sh/install | bash -s -- --local
```

Once installed, the skills will be available inside your agent sessions:

```
───────────────────────────────────
❯ /kstack-cluster-status
───────────────────────────────────
```

By default, the script will install the skills with a kstack-* namespace prefix but you can disable this with the --no-prefix flag. It will also install the skills for all of your available agents (e.g. Claude, Codex, OpenCode) but you can choose to target individual agents with the --agent flag instead (see [Installation](https://kstack.sh/concepts/installation)).

Kstack uses your local `kubeconfig` file for authentication so it will be able to use your RBAC permissions to perform actions on your behalf. If it runs into permissions problems, it will let you know.

## Other AI Agents

Kstack works with any AI agent that supports skills, not just Claude. The curl bootstrap auto-detects which agent CLIs are on your `PATH` and installs for each. You can target a specific agent with `--agent <name>`:

| Agent            | Flag               | Global install path            |
|------------------|--------------------|--------------------------------|
| OpenAI Codex CLI | `--agent codex`    | `~/.codex/skills/`             |
| OpenCode         | `--agent opencode` | `~/.config/opencode/skills/`   |
| Cursor           | `--agent cursor`   | `~/.cursor/skills/`            |
| Factory Droid    | `--agent factory`  | `~/.factory/skills/`           |
| Slate            | `--agent slate`    | `~/.slate/skills/`             |
| Kiro             | `--agent kiro`     | `~/.kiro/skills/`              |
| Hermes           | `--agent hermes`   | `~/.hermes/skills/`            |
| Pi               | `--agent pi`       | `~/.pi/agent/skills/`          |

Local installs mirror this structure under the project directory (e.g. `<project>/.codex/skills/`) and are picked up only when the agent is run from inside that directory. Pi is the one exception — its local skills dir is `<project>/.pi/skills/` (no `agent/` segment).

## Skills Reference

Each skill is invoked with `/<name>` inside an agent session. All skills are read-only by default — any action that mutates cluster state requires explicit confirmation. Skills honor your local `kubeconfig` context and respect RBAC.

**Global flags** (supported by every skill):

| Flag              | Description                                                              |
|-------------------|--------------------------------------------------------------------------|
| `--context <ctx>` | Override the current kubeconfig context                                  |
| `--namespace <n>` | Scope the run to a single namespace (defaults to all accessible)         |
| `--json`          | Emit structured output for piping into other tools                       |
| `--help`          | Open the reference documentation for the skill in your browser           |

---

### Monitoring

<dl>
<dt>

#### `/cluster-status`

</dt>
<dd>

A dense health snapshot of the cluster — node conditions, pod aggregates, and a ranked list of the issues that actually matter.

**What it checks:** cluster identity (context, Kubernetes version, platform), node `Ready`/`MemoryPressure`/`DiskPressure`/`PIDPressure` conditions and `SchedulingDisabled`, control-plane vs. worker split, pod phase and `Ready` across all namespaces, pods with non-zero restart counts, and a ranked top-issues list (top 5 by severity).

**How it works:** fans out `kubectl version`, `kubectl get nodes -o json`, and `kubectl get pods -A -o json` in parallel, writing each to a per-context cache (`cluster.json`, `nodes.json`, `pods.json`). Aggregation and severity ranking happen client-side. Follow-up questions ("list pods", "pods on <node>", "which nodes are tainted") are answered by reading the cache with `jq` rather than re-invoking the skill.

**Options:**
- `--refresh` — fetch most recent data, bypassing and refreshing the cache (default: `false`)
- `--ttl <duration>` — only update the cache if older than `<duration>` (default: `15m`)

**Reference:** [kstack.sh/reference/skills/cluster-status](https://kstack.sh/reference/skills/cluster-status)

</dd>
<dt>

#### `/events`

</dt>
<dd>

Recent cluster events, grouped by reason and ranked by severity so the signal isn't drowned in `Pulled`/`Created`/`Started` noise.

**What it checks:** `Warning` events across all namespaces, grouped by `(reason, involvedObject.kind, namespace)`; notable `Normal` events (`Killing`, `Preempting`, `NodeNotReady`, `Rebooted`, `FailedScheduling`) with chatty reasons (`Pulled`, `Created`, `Started`, `Scheduled`, `SuccessfulCreate`) collapsed into a tail line. Each group includes count, first/last timestamp, the most recent message, and the involved objects.

**How it works:** a single `kubectl get events --all-namespaces` call (against `events.k8s.io/v1`, sorted server-side by `lastTimestamp`), written to a per-context cache as `events.json`. Aggregation and ranking happen client-side. Follow-ups ("only payments", "events on pod/checkout-7c9", "show suppressed") are answered by reading the cache with `jq` — and walk owners one level up (`Pod` → `ReplicaSet` → `Deployment`) so controller-fired events aren't missed.

**Options:**
- `--refresh` — fetch most recent data, bypassing and refreshing the cache (default: `false`)
- `--ttl <duration>` — only update the cache if older than `<duration>` (default: `5m`)

**Reference:** [kstack.sh/reference/skills/events](https://kstack.sh/reference/skills/events)

</dd>

---

### Troubleshooting

<dl>
<dt>

#### `/investigate`

</dt>
<dd>

Kick off a root-cause investigation on a failing or suspicious resource. When the skill is invoked, it runs a script to gather an initial data bundle and briefs the agent. From there, you can ask follow-up questions in natural language and the agent decides whether to answer from what it has, fetch something new, or reach for another tool.

**What it gathers:** spec and status of the problematic resources; events on those resources and their owners (a `Pod`'s `ReplicaSet` and `Deployment`, a `Job`'s `CronJob`, etc.); logs from current and previous containers, truncated to the lines most likely to contain the failure; obvious related resources (backing `Service`, mounted `ConfigMap`/`Secret` names, bound `PVC`s, referenced `ServiceAccount`); and the node the pods are scheduled on when relevant.

**How it works:** the skill loads the bundle from the Kubernetes API and briefs the agent on how to read it (exit codes, event reasons, common state combinations), when follow-ups should re-fetch rather than reason from the stale bundle, and when to hand off to [`/logs`](#logs), [`/exec`](#exec), or [`/metrics`](#metrics).

**Arguments:**
- `<target>` — `<kind>/<name>` (e.g. `pod/checkout-7c9`) or natural language (`the api deployment`, `why is checkout crashing`). Optional — the skill will prompt if omitted.

**Options:** none. Scope logs, time windows, or resources via natural language in the prompt or follow-ups.

**Reference:** [kstack.sh/reference/skills/investigate](https://kstack.sh/reference/skills/investigate)

</dd>
<dt>

#### `/logs`

</dt>
<dd>

An AI-powered log fetcher. Describe what you're looking for in natural language and the agent finds the right pods, picks the time window, and builds the grep filter to fetch only the lines that matter. The stream runs inside a **tmux** window that you and the agent are both attached to.

**How it works:** the agent translates your description into a Kubetail query, starts a detached tmux session (e.g. `kstack-logs-api-server`), tries to open a new terminal window attached to it, and prints the `tmux attach` command in chat as a fallback. You and the agent share the same pane — you can scroll, search, or watch the live tail; the agent reads conservatively to save tokens.

**Requirements:** `tmux` on the agent's `$PATH`, and Kubetail installed in the cluster (the skill offers to install it via Helm if missing).

**Arguments:**
- `<target>` — natural-language description of what to fetch (`api`, `errors from the last hour on api`, `checkout for "timeout" in last 15m`). Optional — the skill will prompt if omitted.

**Options:**
- `--attach` — attach the agent to an existing kstack tmux session instead of starting a new one
- `--detach` — start a new session detached (no terminal window opened, attach manually)

**Reference:** [kstack.sh/reference/skills/logs](https://kstack.sh/reference/skills/logs)

</dd>
<dt>

#### `/metrics`

</dt>
<dd>

An AI-powered metrics fetcher. Describe what you want to see and the agent resolves the right target, picks a sensible time window, and returns a compact summary. Read-only and never mutates cluster state.

**How it works:** the agent translates your description into a query against whichever source fits (`metrics-server` or Prometheus), reports summary statistics (p50, p95, max) rather than piping the full series through the model, and shows the resolved query before running it when the scope looks broader than intended. For *why* a metric moved, it hands off to [`/logs`](#logs); for root-cause context, [`/investigate`](#investigate); for a full right-sizing sweep, [`/audit-cost`](#audit-cost).

**Arguments:**
- `<target>` — natural-language description (`api`, `memory on checkout last 1h`, `top pods by cpu in payments`). Optional — the skill will prompt if omitted.

**Options:** none. Scope the target, metric, and time window via natural language in the prompt or follow-ups.

**Reference:** [kstack.sh/reference/skills/metrics](https://kstack.sh/reference/skills/metrics)

</dd>
<dt>

#### `/exec`

</dt>
<dd>

An AI-powered version of `kubectl exec`. Describe the target in natural language and the agent picks the right mechanism: a normal `exec` into a running container, an ephemeral debug container when the target has no usable shell, or a privileged shell on a node. The session runs inside a **tmux** window that you and the agent are both attached to — either of you can type, both see the output.

**How it works:** the agent starts a detached tmux session (e.g. `kstack-exec-api-server`), tries to open a new terminal window attached to it, and prints the `tmux attach` command in chat as a fallback. The agent reads from the pane conservatively to save tokens. Tell it to tear down and it kills the tmux session and deletes any pod it created.

**Requirements:** `tmux` on the agent's `$PATH`.

**Safety:** `/exec` ships with `disable-model-invocation: true` — the agent never starts a shell on its own. It only runs when you type `/exec`, deliberately, given the privileged modes above.

**Arguments:**
- `<target>` — natural-language description (`api`, `api/sidecar`, `node worker-3`, `debug api`). Optional — the skill will prompt if omitted.

**Options:**
- `--image <image>` — image to use for node and debug-container modes (default `netshoot`)
- `--attach` — attach the agent to an existing kstack tmux session instead of starting a new one
- `--detach` — start a new session detached (no terminal window opened, attach manually)

**Reference:** [kstack.sh/reference/skills/exec](https://kstack.sh/reference/skills/exec)

</dd>
</dl>

---

### Audits

All audit skills produce a ranked findings list (severity + evidence + suggested fix).

<dl>
<dt>

#### `/audit-security`

</dt>
<dd>

RBAC review, pod security posture, and privilege-tightening recommendations. Looks for over-privileged identities and workloads — `ServiceAccounts` with more access than they use, pods running as root or with host-level escapes, and bindings that grant cluster-wide power where a namespace-scoped role would do.

**How it works:** queries the Kubernetes API only; no exec, no log access. Findings are ranked by blast radius (cluster-scoped wildcards above namespace-scoped ones, host escapes above missing seccomp). RBAC checks are **static** — they find what `Roles` grant, not what subjects actually use; detecting truly unused permissions requires audit-log analysis, which this skill does not do. `Secrets` are referenced by name, namespace, and type only — contents are never read.

**Arguments:**
- `<scope>` — natural-language scope (`rbac`, `pods in kube-system`). Optional — omit for a full sweep.

**Options:** none. Scope via natural language in the prompt or follow-ups.

**Reference:** [kstack.sh/reference/skills/audit-security](https://kstack.sh/reference/skills/audit-security)

</dd>
<dt>

#### `/audit-network`

</dt>
<dd>

NetworkPolicy, Service, Ingress, Gateway API, DNS, and encryption sanity checks. Looks for broken or missing pieces in cluster networking such as `NetworkPolicy` instances that don't match anything, `Services` with no endpoints, `Ingress` and Gateway API routes that won't resolve, DNS problems, and workloads talking in plaintext when a mesh is available.

**How it works:** queries the Kubernetes API plus CoreDNS metrics and mesh CRDs when present. TLS checks distinguish "Secret contents not readable due to RBAC" from "expired" rather than reporting false positives. Findings are grouped by workflow and include the evidence (selectors, endpoints, ConfigMap keys), not just the verdict.

**Arguments:**
- `<scope>` — natural-language scope (`policies`, `ingress in prod`). Optional — omit for a full sweep.

**Options:** none. Scope via natural language in the prompt or follow-ups.

**Reference:** [kstack.sh/reference/skills/audit-network](https://kstack.sh/reference/skills/audit-network)

</dd>
<dt>

#### `/audit-cost`

</dt>
<dd>

Resource waste and right-sizing recommendations. Looks for workloads that are over-provisioned, idle, or holding storage and load balancers nothing is using.

**How it works:** runs several workflows in parallel, joining `metrics-server` and Prometheus reads against the Kubernetes API for `Job`/`CronJob` status, PV/PVC binding, and `LoadBalancer` endpoints. Findings are ranked by potential impact (large requests-vs-usage gaps and idle workloads above unmounted PVCs and `Released` PVs), and only requests-vs-usage gaps large enough to matter in practice are flagged — small deltas are noise. The header always states the source (`metrics-server` for live, Prometheus for history) and the effective lookback so the reader can judge how much weight to give the recommendations.

**Arguments:**
- `<scope>` — natural-language scope (`requests`, `idle in staging`). Optional — omit for a full sweep.

**Options:** none. Scope via natural language in the prompt or follow-ups.

**Reference:** [kstack.sh/reference/skills/audit-cost](https://kstack.sh/reference/skills/audit-cost)

</dd>
<dt>

#### `/audit-outdated`

</dt>
<dd>

Outdated cluster components, known CVEs, and available version bumps. Looks for version drift across control plane, nodes, container images, Helm charts, CRDs, operators, and the API surface your manifests target.

**How it works:** runs the workflows in parallel against the Kubernetes API plus external indexes (release schedules, registries, Helm repos, Trivy DB, CVE feeds). Findings are de-duplicated by image digest so one outdated image shared across many pods doesn't dominate the report. CVE entries include severity and CISA KEV status when available — KEV hits rank above CVSS-high findings without known exploitation. "Drift within the supported window" is reported distinctly from "EOL" — the first is routine, the second is urgent. For registries outside the supported list, the skill says so rather than silently skipping the image.

**Arguments:**
- `<scope>` — natural-language scope (`images`, `cves in kube-system`). Optional — omit for a full sweep.

**Options:** none. Scope via natural language in the prompt or follow-ups.

**Reference:** [kstack.sh/reference/skills/audit-outdated](https://kstack.sh/reference/skills/audit-outdated)

</dd>
<dt>

#### `/karpenter`

</dt>
<dd>

Karpenter node-autoscaling health, node-claim diagnosis, and consolidation/cost efficiency. Reports what Karpenter has provisioned, why nodes or pods are stuck, and where cheaper steady-state capacity is being left on the table.

**What it checks:** NodePools (`.spec.limits` vs `.status.resources` utilization, disruption policy and budgets, unbounded pools), NodeClaims (readiness across `Launched`/`Registered`/`Initialized`/`Ready`, spot vs on-demand mix, pending drift), stuck launches and unschedulable pods Karpenter should be handling, `EC2NodeClass` misconfiguration (unresolved subnets/security-groups/AMI/instance-profile), provisioning errors from controller events/logs (ICE, IAM, VPC limits), and cost levers — consolidation left off or throttled (`WhenEmpty` vs `WhenEmptyOrUnderutilized`, restrictive budgets, long `consolidateAfter`), on-demand where spot fits, narrow instance-type requirements, and idle nodes lingering.

**How it works:** detects the served Karpenter API version (`v1`/`v1beta1`/`v1alpha5`) up front, then fetches `nodepools`, `nodeclaims`, `ec2nodeclasses`, and `nodes` in one consolidated read reused across all workflows. Utilization joins Prometheus (7-day lookback) or `metrics-server` (live snapshot) against per-node pod requests; when neither is reachable, utilization findings are marked unavailable rather than dropped. AWS-primary (`EC2NodeClass` checks are best-effort and skipped on non-AWS providers). Read-only — Kubernetes API only, no node mutation. Every finding names the concrete object and the field/condition/event that proves it.

**Arguments:**
- `<scope>` — natural-language scope (`status`, `diagnose`, `cost`, `for nodepool default`). Optional — omit for a full sweep across all three workflows.

**Options:** none. Scope via natural language in the prompt or follow-ups.

**Reference:** [kstack.sh/reference/skills/karpenter](https://kstack.sh/reference/skills/karpenter)

</dd>
</dl>

---

### Miscellaneous

<dl>
<dt>

#### `/cleanup`

</dt>
<dd>

Remove every resource kstack has created in the cluster. The counterpart to [`/forget`](#forget), which clears local state.

**What it removes:** anything annotated `kstack.kubetail.com/owned-by=kstack` — ephemeral debug containers and privileged node-shell pods from [`/exec`](#exec), short-lived toolbox pods, and any temporary RBAC or ConfigMaps created to support them. Resources without the annotation are never touched, even if they live in the same namespace.

**How it works:** the agent lists everything it found, grouped by namespace and kind, and asks you to confirm before deleting. You can approve the whole set or tell it in natural language to skip specific items. If a delete fails — usually a finalizer or a permissions issue — the agent reports which resources remain and why, rather than retrying blindly.

**Safety:** `/cleanup` ships with `disable-model-invocation: true` — the agent never starts a cleanup on its own. It only runs when you type `/cleanup`, since it deletes cluster resources.

**Options:** none. Use the global `--context <ctx>` flag to target a different cluster.

**Reference:** [kstack.sh/reference/skills/cleanup](https://kstack.sh/reference/skills/cleanup)

</dd>
<dt>

#### `/forget`

</dt>
<dd>

Wipe kstack's local state on your machine. Over time kstack builds up a working memory of your clusters — recent query results, detected integrations, resource fingerprints, and baselines it uses to detect anomalies. This skill forces a clean slate. It does not touch the cluster itself; for that, see [`/cleanup`](#cleanup).

**What it clears:** state lives under `~/.config/kstack/`, partitioned per kubeconfig context.
- **Cache** (`~/.config/kstack/cache/<context>/`) — recent query results, log buffers, dedup tables, in-flight watcher state. Cheap to rebuild; cleared freely.
- **Learned state** (`~/.config/kstack/state/<context>/`) — detected integrations, resource fingerprints, baselines, per-cluster preferences. Rebuilt on next use, but may take a few interactions to fully re-form.

**How it works:** by default clears both cache and learned state for the current kubeconfig context — forgetting `staging` never affects `prod`. Use the global `--context <ctx>` flag to target a different cluster. Run it after a cluster is rebuilt or migrated (so kstack stops trusting stale fingerprints), when baselines feel stale, when an earlier session taught it something wrong, or when you're handing the machine off and want no cluster-specific state left behind.

**Safety:** `/forget` ships with `disable-model-invocation: true` — the agent never wipes local state on its own. It only runs when you type `/forget`, so cached context isn't lost unexpectedly.

**Options:**
- `--all` — Clear cache and learned state for every context, not just the current one.

**Reference:** [kstack.sh/reference/skills/forget](https://kstack.sh/reference/skills/forget)

</dd>
</dl>

## Upgrade

When you run a kstack skill, agent quietly checks whether a newer kstack release is available and surfaces a one-line notice at the top of its response when it finds one. Just say **"upgrade kstack"** and the agent will run the kstack upgrade script on your behalf; say **"dismiss"** to hide the notice until the next release. This works the same for both global and local installs.

You can also run the helper directly:

```console
# Global install
~/.config/kstack/bin/upgrade

# Local install (from the project directory)
./.kstack/bin/upgrade
```

Upgrades are idempotent and safe to run any time.

## Uninstall

Run the uninstall helper bundled with your install:

```console
# Global install
~/.config/kstack/bin/uninstall

# Local install (from the project directory)
./.kstack/bin/uninstall
```

Both helpers prompt before removing. They clear the install root (`~/.config/kstack` or `<project>/.kstack`) and every kstack-owned skill slot, leaving user-authored skills in the same agent dirs untouched.

## Development

The installer payload lives under `src/` (skills, helpers, lib, schemas). Dev tooling — the `Makefile`, `scripts/`, `tests/`, CI — sits at the repo root. If you're hacking on kstack, see `CONTRIBUTING.md` for the full contributor guide.

Common contributor commands, via the root `Makefile`:

```console
make install      # dev-mode install — renders skills into <repo>/.<agent>/skills/
make test         # fast bats tiers (unit + integration)
make test-e2e     # cluster-backed tier (kind + docker)
make test-evals   # eval harness (requires ANTHROPIC_API_KEY or Claude CLI)
make lint         # shellcheck
make clean        # remove dev-mode artifacts
```

Each target shells out to a script under `scripts/` that's also runnable directly.

`make test` requires bats-core (`brew install bats-core` / `apt install bats`). Tests live in `tests/unit/` (sourced-function tests) and `tests/integration/` (end-to-end CLI tests against isolated `$HOME` and local bare git repos). CI runs the full suite on Ubuntu, macOS, and Windows for every PR — see `.github/workflows/ci.yml`.

## Get Involved

At Kubetail, we're building the most **user-friendly**, **cost-effective**, and **secure** logging platform for Kubernetes and we'd love your contributions! Here's how you can help:

* UI/UX design
* React frontend development
* Reporting issues and suggesting features

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup and guidelines. Reach us at hello@kubetail.com, or join our [Discord server](https://discord.gg/CmsmWAVkvX) or [Slack channel](https://join.slack.com/t/kubetail/shared_invite/zt-2cq01cbm8-e1kbLT3EmcLPpHSeoFYm1w).

## Notes

* Inspired by Garry Tan's [gstack](https://github.com/garrytan/gstack)

Made with 🧿 in Istanbul
