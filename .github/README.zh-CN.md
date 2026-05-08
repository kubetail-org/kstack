# kstack

*Claude Code 的技能包，帮助您以超智能的方式监控 K8s 集群*

<a href="https://discord.gg/CmsmWAVkvX"><img src="https://img.shields.io/discord/1212031524216770650?logo=Discord&style=flat-square&logoColor=FFFFFF&labelColor=5B65F0&label=Discord&color=64B73A"></a>
[![Slack](https://img.shields.io/badge/Slack-kubetail-364954?logo=slack&labelColor=4D1C51)](https://kubernetes.slack.com/archives/C08SHG1GR37)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](CODE_OF_CONDUCT.md)
[![Contributor Resources](https://img.shields.io/badge/Contributor%20Resources-purple?style=flat-square)](https://github.com/kubetail-org)

[English](../README.md) | 简体中文 | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Español](README.es.md) | [Português](README.pt-BR.md) | [Français](README.fr.md)

## 简介

<img width="350" alt="kstack" src="https://github.com/user-attachments/assets/cfe998de-a85a-44bb-8eb2-5f5efe7449ea" />
<br>
<br>

**Kstack** 是 Claude Code 的技能包，帮助您以智能高效的方式对 K8s 集群执行监控、故障排查和审计任务。除了使用 kubectl 等标准工具外，它还将 shell 工作交给 [Kubetail](https://github.com/kubetail-org/kubetail)、[Helm](https://helm.sh)、[Trivy](https://github.com/aquasecurity/trivy)、[Pluto](https://github.com/FairwindsOps/pluto) 等工具处理后再将结果发送给 Claude，保持响应快速且 token 高效。Kstack 还会检测集群中运行的服务，并在必要时使用其专用工具（例如 [Cilium](https://cilium.io)、[Istio](https://istio.io)）。

安装 kstack 后，您将在 Claude Code 中访问以下技能：

**监控**
* `/cluster-status` — 集群健康快照（Pod 重启、节点状况、资源压力）
* `/events` — 最近事件，按严重程度排序

**故障排查**
* `/investigate` — 跨事件、日志和相关资源的根因分析
* `/logs` — 共享 tmux 会话，将自然语言转换为日志获取和分析（通过 [Kubetail](https://github.com/kubetail-org/kubetail)）
* `/metrics` — 获取 Pod、节点和工作负载的 CPU、内存及其他资源指标
* `/exec` — 进入 Pod、节点或临时调试容器的共享 tmux shell

**审计**
* `/audit-security` — RBAC、Pod 安全态势、权限收紧
* `/audit-network` — NetworkPolicy、Service、Ingress、GatewayAPI、DNS 和加密检查
* `/audit-cost` — 请求与使用量对比、过度配置、空闲容量
* `/audit-outdated` — 过时服务、已知 CVE、可用版本升级

**其他**
* `/cleanup` — 从集群中删除所有 kstack 拥有的资源（调试容器、Pod 克隆、watcher 作业）
* `/forget` — 清除 kstack 的本地缓存，丢弃它已学习的集群信息

我们的目标是以用户友好且具有成本效益的方式将 AI 的力量带入 K8s 监控，同时让您保持控制。如果您发现 bug 或有建议，请创建 GitHub Issue 或发送电子邮件至 hello@kubetail.com！

## 快速开始

要全局安装 kstack 技能，请运行以下命令：

```console
curl -sS https://kstack.sh/install | bash
```

或者，您可以在特定项目目录中本地安装：

```console
curl -sS https://kstack.sh/install | bash -s -- --local
```

安装后，技能将在您的代理会话中可用：

```
───────────────────────────────────
❯ /kstack-cluster-status
───────────────────────────────────
```

默认情况下，脚本将使用 kstack-* 命名空间前缀安装技能，但您可以使用 --no-prefix 标志禁用此前缀。它还会为所有可用代理（例如 Claude、Codex、OpenCode）安装技能，但您可以使用 --agent 标志选择特定代理（参见[安装说明](https://kstack.sh/concepts/installation)）。

Kstack 使用您的本地 `kubeconfig` 文件进行身份验证，因此它可以使用您的 RBAC 权限代表您执行操作。如果遇到权限问题，它会通知您。

## 其他 AI 代理

Kstack 适用于任何支持技能的 AI 代理，不仅仅是 Claude。curl 引导程序会自动检测 `PATH` 上的代理 CLI 并为每个代理安装。您可以使用 `--agent <name>` 指定特定代理：

| 代理             | 标志               | 全局安装路径                    |
|------------------|--------------------|-------------------------------|
| OpenAI Codex CLI | `--agent codex`    | `~/.codex/skills/`            |
| OpenCode         | `--agent opencode` | `~/.config/opencode/skills/`  |
| Cursor           | `--agent cursor`   | `~/.cursor/skills/`           |
| Factory Droid    | `--agent factory`  | `~/.factory/skills/`          |
| Slate            | `--agent slate`    | `~/.slate/skills/`            |
| Kiro             | `--agent kiro`     | `~/.kiro/skills/`             |
| Hermes           | `--agent hermes`   | `~/.hermes/skills/`           |
| Pi               | `--agent pi`       | `~/.pi/agent/skills/`         |

本地安装在项目目录下镜像此结构（例如 `<project>/.codex/skills/`），仅在从该目录内运行代理时生效。 Pi 是唯一的例外 —— 其本地技能目录为 `<project>/.pi/skills/`（不含 `agent/` 段）。

## 技能参考

每个技能在代理会话中通过 `/<name>` 调用。所有技能默认为只读——任何改变集群状态的操作都需要明确确认。技能遵循您的本地 `kubeconfig` 上下文并尊重 RBAC。

**全局标志**（每个技能均支持）：

| 标志              | 描述                                                                |
|-------------------|---------------------------------------------------------------------|
| `--context <ctx>` | 覆盖当前 kubeconfig 上下文                                           |
| `--namespace <n>` | 将运行范围限定到单个命名空间（默认为所有可访问的）                     |
| `--json`          | 发出结构化输出以管道传输到其他工具                                    |
| `--help`          | 在浏览器中打开技能的参考文档                                          |

---

### 监控

<dl>
<dt>

#### `/cluster-status`

</dt>
<dd>

集群的密集健康快照——节点状况、Pod 聚合，以及真正重要问题的排名列表。

**检查内容：** 集群标识（上下文、Kubernetes 版本、平台）、节点 `Ready`/`MemoryPressure`/`DiskPressure`/`PIDPressure` 状况和 `SchedulingDisabled`、控制平面与工作节点分布、所有命名空间中的 Pod 阶段和 `Ready` 状态、具有非零重启计数的 Pod，以及排名靠前的问题列表（按严重程度排名前 5）。

**工作方式：** 并行展开 `kubectl version`、`kubectl get nodes -o json` 和 `kubectl get pods -A -o json`，将每个写入每个上下文的缓存（`cluster.json`、`nodes.json`、`pods.json`）。聚合和严重程度排名在客户端进行。后续问题（"列出 Pod"、"<节点>上的 Pod"、"哪些节点有污点"）通过使用 `jq` 读取缓存来回答，而不是重新调用技能。

**选项：**
- `--refresh` — 获取最新数据，绕过并刷新缓存（默认：`false`）
- `--ttl <duration>` — 仅在缓存比 `<duration>` 旧时更新（默认：`15m`）

**参考：** [kstack.sh/reference/skills/cluster-status](https://kstack.sh/reference/skills/cluster-status)

</dd>
<dt>

#### `/events`

</dt>
<dd>

最近的集群事件，按原因分组并按严重程度排名，使信号不被 `Pulled`/`Created`/`Started` 噪音淹没。

**检查内容：** 所有命名空间中的 `Warning` 事件，按 `(reason, involvedObject.kind, namespace)` 分组；值得注意的 `Normal` 事件（`Killing`、`Preempting`、`NodeNotReady`、`Rebooted`、`FailedScheduling`），聊天原因（`Pulled`、`Created`、`Started`、`Scheduled`、`SuccessfulCreate`）折叠为尾行。每个组包括计数、首次/最后时间戳、最新消息和涉及的对象。

**工作方式：** 单次 `kubectl get events --all-namespaces` 调用（针对 `events.k8s.io/v1`，服务器端按 `lastTimestamp` 排序），以 `events.json` 形式写入每个上下文的缓存。聚合和排名在客户端进行。后续问题（"仅支付"、"pod/checkout-7c9 上的事件"、"显示被抑制的"）通过使用 `jq` 读取缓存来回答——并向上遍历一级所有者（`Pod` → `ReplicaSet` → `Deployment`），确保不会遗漏控制器触发的事件。

**选项：**
- `--refresh` — 获取最新数据，绕过并刷新缓存（默认：`false`）
- `--ttl <duration>` — 仅在缓存比 `<duration>` 旧时更新（默认：`5m`）

**参考：** [kstack.sh/reference/skills/events](https://kstack.sh/reference/skills/events)

</dd>

---

### 故障排查

<dl>
<dt>

#### `/investigate`

</dt>
<dd>

对失败或可疑资源启动根因调查。调用技能时，它会运行脚本收集初始数据包并向代理汇报。从那里，您可以用自然语言提出后续问题，代理决定是从现有数据回答、获取新数据还是使用其他工具。

**收集内容：** 问题资源的规格和状态；这些资源及其所有者的事件（`Pod` 的 `ReplicaSet` 和 `Deployment`、`Job` 的 `CronJob` 等）；当前和以前容器的日志，截断为最可能包含失败的行；明显相关的资源（支持 `Service`、挂载的 `ConfigMap`/`Secret` 名称、绑定的 `PVC`、引用的 `ServiceAccount`）；以及相关时 Pod 调度到的节点。

**工作方式：** 技能从 Kubernetes API 加载数据包，并向代理说明如何读取（退出代码、事件原因、常见状态组合）、何时后续问题应重新获取而不是从陈旧数据包推理，以及何时移交给 [`/logs`](#logs)、[`/exec`](#exec) 或 [`/metrics`](#metrics)。

**参数：**
- `<target>` — `<kind>/<name>`（例如 `pod/checkout-7c9`）或自然语言（`api deployment`、`为什么 checkout 在崩溃`）。可选——如果省略，技能会提示。

**选项：** 无。通过提示或后续问题中的自然语言限定日志、时间窗口或资源范围。

**参考：** [kstack.sh/reference/skills/investigate](https://kstack.sh/reference/skills/investigate)

</dd>
<dt>

#### `/logs`

</dt>
<dd>

AI 驱动的日志获取器。用自然语言描述您要查找的内容，代理找到正确的 Pod、选择时间窗口，并构建 grep 过滤器以仅获取重要的行。流在 **tmux** 窗口内运行，您和代理都连接到该窗口。

**工作方式：** 代理将您的描述转换为 Kubetail 查询，启动一个分离的 tmux 会话（例如 `kstack-logs-api-server`），尝试打开一个连接到它的新终端窗口，并在聊天中打印 `tmux attach` 命令作为备选。您和代理共享同一个面板——您可以滚动、搜索或观看实时尾随；代理保守地读取以节省 token。

**要求：** 代理 `$PATH` 上的 `tmux`，以及集群中安装的 Kubetail（如果缺少，技能会提供通过 Helm 安装）。

**参数：**
- `<target>` — 要获取内容的自然语言描述（`api`、`过去一小时 api 的错误`、`checkout 中过去 15 分钟的 "timeout"`）。可选——如果省略，技能会提示。

**选项：**
- `--attach` — 将代理附加到现有 kstack tmux 会话而不是启动新会话
- `--detach` — 启动一个新的分离会话（不打开终端窗口，手动附加）

**参考：** [kstack.sh/reference/skills/logs](https://kstack.sh/reference/skills/logs)

</dd>
<dt>

#### `/metrics`

</dt>
<dd>

AI 驱动的指标获取器。描述您想查看的内容，代理解析正确的目标、选择合理的时间窗口并返回紧凑的摘要。只读，永不改变集群状态。

**工作方式：** 代理将您的描述转换为针对合适来源（`metrics-server` 或 Prometheus）的查询，报告摘要统计信息（p50、p95、最大值）而不是通过模型传输完整序列，并在范围看起来比预期更广时在运行前显示解析的查询。对于*为什么*指标发生变化，它移交给 [`/logs`](#logs)；对于根因上下文，移交给 [`/investigate`](#investigate)；对于完整的右侧调整扫描，移交给 [`/audit-cost`](#audit-cost)。

**参数：**
- `<target>` — 自然语言描述（`api`、`过去 1 小时 checkout 的内存`、`payments 中按 CPU 排名的顶级 Pod`）。可选——如果省略，技能会提示。

**选项：** 无。通过提示或后续问题中的自然语言限定目标、指标和时间窗口。

**参考：** [kstack.sh/reference/skills/metrics](https://kstack.sh/reference/skills/metrics)

</dd>
<dt>

#### `/exec`

</dt>
<dd>

`kubectl exec` 的 AI 驱动版本。用自然语言描述目标，代理选择正确的机制：对运行中容器的正常 `exec`、当目标没有可用 shell 时的临时调试容器，或节点上的特权 shell。会话在 **tmux** 窗口内运行，您和代理都连接到该窗口——您们任何一方都可以输入，双方都能看到输出。

**工作方式：** 代理启动一个分离的 tmux 会话（例如 `kstack-exec-api-server`），尝试打开一个连接到它的新终端窗口，并在聊天中打印 `tmux attach` 命令作为备选。代理保守地从面板读取以节省 token。告诉它关闭，它会终止 tmux 会话并删除它创建的任何 Pod。

**要求：** 代理 `$PATH` 上的 `tmux`。

**安全性：** `/exec` 附带 `disable-model-invocation: true`——代理永远不会自行启动 shell。它只在您输入 `/exec` 时运行，考虑到上述特权模式，这是故意的。

**参数：**
- `<target>` — 自然语言描述（`api`、`api/sidecar`、`node worker-3`、`debug api`）。可选——如果省略，技能会提示。

**选项：**
- `--image <image>` — 用于节点和调试容器模式的镜像（默认 `netshoot`）
- `--attach` — 将代理附加到现有 kstack tmux 会话而不是启动新会话
- `--detach` — 启动一个新的分离会话（不打开终端窗口，手动附加）

**参考：** [kstack.sh/reference/skills/exec](https://kstack.sh/reference/skills/exec)

</dd>
</dl>

---

### 审计

所有审计技能都会生成排名的发现列表（严重程度 + 证据 + 建议修复）。

<dl>
<dt>

#### `/audit-security`

</dt>
<dd>

RBAC 审查、Pod 安全态势和权限收紧建议。查找过度特权的身份和工作负载——拥有超出其使用权限的 `ServiceAccount`、以 root 身份运行或具有主机级逃逸的 Pod，以及在命名空间范围角色就足够的地方授予集群范围权限的绑定。

**工作方式：** 仅查询 Kubernetes API；无 exec，无日志访问。发现按影响范围排名（集群范围通配符高于命名空间范围，主机逃逸高于缺失 seccomp）。RBAC 检查是**静态的**——它们找到 `Role` 授予什么，而不是主体实际使用什么；检测真正未使用的权限需要审计日志分析，这不是此技能做的。`Secret` 仅按名称、命名空间和类型引用——内容永远不会被读取。

**参数：**
- `<scope>` — 自然语言范围（`rbac`、`kube-system 中的 Pod`）。可选——省略进行完整扫描。

**选项：** 无。通过提示或后续问题中的自然语言限定范围。

**参考：** [kstack.sh/reference/skills/audit-security](https://kstack.sh/reference/skills/audit-security)

</dd>
<dt>

#### `/audit-network`

</dt>
<dd>

NetworkPolicy、Service、Ingress、Gateway API、DNS 和加密健全性检查。查找集群网络中损坏或缺失的部分，例如不匹配任何内容的 `NetworkPolicy` 实例、没有端点的 `Service`、无法解析的 `Ingress` 和 Gateway API 路由、DNS 问题，以及在网格可用时以明文通信的工作负载。

**工作方式：** 查询 Kubernetes API 以及存在时的 CoreDNS 指标和网格 CRD。TLS 检查区分"由于 RBAC 无法读取 Secret 内容"和"已过期"，而不是报告误报。发现按工作流程分组，包括证据（选择器、端点、ConfigMap 键），而不仅仅是结论。

**参数：**
- `<scope>` — 自然语言范围（`policies`、`prod 中的 ingress`）。可选——省略进行完整扫描。

**选项：** 无。通过提示或后续问题中的自然语言限定范围。

**参考：** [kstack.sh/reference/skills/audit-network](https://kstack.sh/reference/skills/audit-network)

</dd>
<dt>

#### `/audit-cost`

</dt>
<dd>

资源浪费和右侧调整建议。查找过度配置、空闲或持有没有任何使用的存储和负载均衡器的工作负载。

**工作方式：** 并行运行多个工作流，将 `metrics-server` 和 Prometheus 读取与 Kubernetes API 连接，用于 `Job`/`CronJob` 状态、PV/PVC 绑定和 `LoadBalancer` 端点。发现按潜在影响排名（大的请求与使用量差距和空闲工作负载高于未挂载 PVC 和 `Released` PV），并且只有在实践中足够重要的请求与使用量差距才会被标记——小的差异是噪音。标题始终说明来源（实时的 `metrics-server` 或历史的 Prometheus）和有效回溯，以便读者可以判断给建议多大权重。

**参数：**
- `<scope>` — 自然语言范围（`requests`、`staging 中的空闲`）。可选——省略进行完整扫描。

**选项：** 无。通过提示或后续问题中的自然语言限定范围。

**参考：** [kstack.sh/reference/skills/audit-cost](https://kstack.sh/reference/skills/audit-cost)

</dd>
<dt>

#### `/audit-outdated`

</dt>
<dd>

过时的集群组件、已知 CVE 和可用版本升级。查找控制平面、节点、容器镜像、Helm chart、CRD、operator 以及您的清单所针对的 API 表面的版本漂移。

**工作方式：** 针对 Kubernetes API 以及外部索引（发布时间表、注册表、Helm 仓库、Trivy DB、CVE 源）并行运行工作流。发现按镜像摘要去重，因此跨多个 Pod 共享的一个过时镜像不会主导报告。CVE 条目包括可用时的严重性和 CISA KEV 状态——KEV 命中的排名高于没有已知利用的 CVSS-high 发现。"支持窗口内的漂移"与"EOL"分别报告——前者是例行事项，后者是紧急情况。对于支持列表之外的注册表，技能会说明而不是静默跳过镜像。

**参数：**
- `<scope>` — 自然语言范围（`images`、`kube-system 中的 cves`）。可选——省略进行完整扫描。

**选项：** 无。通过提示或后续问题中的自然语言限定范围。

**参考：** [kstack.sh/reference/skills/audit-outdated](https://kstack.sh/reference/skills/audit-outdated)

</dd>
</dl>

---

### 其他

<dl>
<dt>

#### `/cleanup`

</dt>
<dd>

删除 kstack 在集群中创建的每个资源。与清除本地状态的 [`/forget`](#forget) 相对应。

**删除内容：** 任何注释为 `kstack.kubetail.com/owned-by=kstack` 的内容——来自 [`/exec`](#exec) 的临时调试容器和特权节点 shell Pod、短暂的工具箱 Pod，以及为支持它们而创建的任何临时 RBAC 或 ConfigMap。没有注释的资源永远不会被触碰，即使它们与 kstack 资源在同一命名空间。

**工作方式：** 代理列出它找到的所有内容，按命名空间和类型分组，并在删除前请求您确认。您可以批准整个集合或用自然语言告诉它跳过特定项目。如果删除失败——通常是 finalizer 或权限问题——代理会报告哪些资源仍然存在以及原因，而不是盲目重试。

**安全性：** `/cleanup` 附带 `disable-model-invocation: true`——代理永远不会自行启动清理。它只在您输入 `/cleanup` 时运行，因为它会删除集群资源。

**选项：** 无。使用全局 `--context <ctx>` 标志指定不同的集群。

**参考：** [kstack.sh/reference/skills/cleanup](https://kstack.sh/reference/skills/cleanup)

</dd>
<dt>

#### `/forget`

</dt>
<dd>

清除 kstack 在您机器上的本地状态。随着时间推移，kstack 会建立您集群的工作记忆——最近的查询结果、检测到的集成、资源指纹，以及用于检测异常的基线。此技能强制从头开始。它不触碰集群本身；为此，请参见 [`/cleanup`](#cleanup)。

**清除内容：** 状态位于 `~/.config/kstack/` 下，按 kubeconfig 上下文分区。
- **缓存**（`~/.config/kstack/cache/<context>/`）——最近的查询结果、日志缓冲区、去重表、进行中的 watcher 状态。重建成本低；可自由清除。
- **已学习状态**（`~/.config/kstack/state/<context>/`）——检测到的集成、资源指纹、基线、每集群偏好。在下次使用时重建，但可能需要几次交互才能完全重新形成。

**工作方式：** 默认清除当前 kubeconfig 上下文的缓存和已学习状态——忘记 `staging` 永远不会影响 `prod`。使用全局 `--context <ctx>` 标志指定不同的集群。在集群重建或迁移后运行它（以便 kstack 停止信任陈旧指纹）、当基线感觉过时时、当较早的会话教给它错误的东西时，或者当您交接机器并希望不留下集群特定状态时。

**安全性：** `/forget` 附带 `disable-model-invocation: true`——代理永远不会自行清除本地状态。它只在您输入 `/forget` 时运行，因此不会意外丢失缓存的上下文。

**选项：**
- `--all` — 清除每个上下文的缓存和已学习状态，而不仅仅是当前上下文。

**参考：** [kstack.sh/reference/skills/forget](https://kstack.sh/reference/skills/forget)

</dd>
</dl>

## 升级

当您运行 kstack 技能时，代理会静默检查是否有更新的 kstack 版本可用，并在找到时在响应顶部显示一行通知。只需说**"upgrade kstack"**，代理就会代表您运行 kstack 升级脚本；说**"dismiss"**可隐藏通知直到下一个版本。这对全局和本地安装都适用。

您也可以直接运行助手：

```console
# 全局安装
~/.config/kstack/bin/upgrade

# 本地安装（从项目目录）
./.kstack/bin/upgrade
```

升级是幂等的，可以随时安全运行。

## 卸载

运行与您的安装捆绑的卸载助手：

```console
# 全局安装
~/.config/kstack/bin/uninstall

# 本地安装（从项目目录）
./.kstack/bin/uninstall
```

两个助手在删除前都会提示。它们清除安装根目录（`~/.config/kstack` 或 `<project>/.kstack`）和每个 kstack 拥有的技能槽，保持同一代理目录中用户编写的技能不受影响。

## 开发

安装程序有效负载位于 `src/`（技能、助手、lib、schema）下。开发工具——`Makefile`、`scripts/`、`tests/`、CI——位于仓库根目录。如果您正在开发 kstack，请参见 `CONTRIBUTING.md` 以获取完整的贡献者指南。

常用贡献者命令，通过根 `Makefile`：

```console
make install      # 开发模式安装——将技能渲染到 <repo>/.<agent>/skills/
make test         # 快速 bats 层（单元 + 集成）
make test-e2e     # 集群支持层（kind + docker）
make test-evals   # 评估框架（需要 ANTHROPIC_API_KEY 或 Claude CLI）
make lint         # shellcheck
make clean        # 删除开发模式工件
```

每个目标都会调用 `scripts/` 下的脚本，也可以直接运行。

`make test` 需要 bats-core（`brew install bats-core` / `apt install bats`）。测试位于 `tests/unit/`（源函数测试）和 `tests/integration/`（针对隔离 `$HOME` 和本地裸 git 仓库的端到端 CLI 测试）。CI 在每次 PR 的 Ubuntu、macOS 和 Windows 上运行完整套件——参见 `.github/workflows/ci.yml`。

## 参与贡献

在 Kubetail，我们正在构建最**用户友好**、**具有成本效益**和**安全**的 Kubernetes 日志平台，我们非常欢迎您的贡献！以下是您可以提供帮助的方式：

* UI/UX 设计
* React 前端开发
* 报告问题和建议功能

请参见 [CONTRIBUTING.md](CONTRIBUTING.md) 了解开发设置和指南。通过 hello@kubetail.com 联系我们，或加入我们的 [Discord 服务器](https://discord.gg/CmsmWAVkvX) 或 [Slack 频道](https://join.slack.com/t/kubetail/shared_invite/zt-2cq01cbm8-e1kbLT3EmcLPpHSeoFYm1w)。

## 注释

* 受 Garry Tan 的 [gstack](https://github.com/garrytan/gstack) 启发

用 🧿 制作于伊斯坦布尔
