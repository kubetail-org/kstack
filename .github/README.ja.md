# kstack

*K8s クラスターを超高度な知性で監視する Claude Code 向けスキルパック*

<a href="https://discord.gg/CmsmWAVkvX"><img src="https://img.shields.io/discord/1212031524216770650?logo=Discord&style=flat-square&logoColor=FFFFFF&labelColor=5B65F0&label=Discord&color=64B73A"></a>
[![Slack](https://img.shields.io/badge/Slack-kubetail-364954?logo=slack&labelColor=4D1C51)](https://kubernetes.slack.com/archives/C08SHG1GR37)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](CODE_OF_CONDUCT.md)
[![Contributor Resources](https://img.shields.io/badge/Contributor%20Resources-purple?style=flat-square)](https://github.com/kubetail-org)

[English](../README.md) | [简体中文](README.zh-CN.md) | 日本語 | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Español](README.es.md) | [Português](README.pt-BR.md) | [Français](README.fr.md)

## はじめに

<img width="350" alt="kstack" src="https://github.com/user-attachments/assets/cfe998de-a85a-44bb-8eb2-5f5efe7449ea" />
<br>
<br>

**Kstack** は Claude Code 向けのスキルパックで、K8s クラスターの監視、トラブルシューティング、監査タスクをスマートかつ効率的に実行するのを支援します。kubectl などの標準ツールの使用に加えて、[Kubetail](https://github.com/kubetail-org/kubetail)、[Helm](https://helm.sh)、[Trivy](https://github.com/aquasecurity/trivy)、[Pluto](https://github.com/FairwindsOps/pluto) などのツールにシェル作業を委託してから結果を Claude に送信することで、レスポンスを高速かつトークン効率よく保ちます。Kstack はクラスターで実行されているサービスを検出し、必要に応じてその専用ツール（例：[Cilium](https://cilium.io)、[Istio](https://istio.io)）を使用します。

kstack をインストールすると、Claude Code 内でこれらのスキルが利用できるようになります：

**監視**
* `/cluster-status` — クラスターの健全性スナップショット（Pod の再起動、ノードの状態、リソースの圧迫）
* `/events` — 最近のイベント、重大度順にランク付け

**トラブルシューティング**
* `/investigate` — イベント、ログ、関連リソースにわたるルートコーズ分析
* `/logs` — 自然言語をログ取得と分析に変換する共有 tmux セッション（[Kubetail](https://github.com/kubetail-org/kubetail) 経由）
* `/metrics` — Pod、ノード、ワークロードの CPU、メモリ、その他のリソースメトリクスを取得
* `/exec` — Pod、ノード、またはエフェメラルデバッグコンテナへの共有 tmux シェル

**監査**
* `/audit-security` — RBAC、Pod セキュリティポスチャー、権限の縮小
* `/audit-network` — NetworkPolicy、Service、Ingress、GatewayAPI、DNS、暗号化のチェック
* `/audit-cost` — リクエスト対使用量、過剰プロビジョニング、アイドル容量
* `/audit-outdated` — 古いサービス、既知の CVE、利用可能なバージョンアップ

**その他**
* `/cleanup` — クラスターからすべての kstack 所有のリソースを削除（デバッグコンテナ、Pod クローン、watcher ジョブ）
* `/forget` — kstack のローカルキャッシュをクリアし、学習したクラスター情報を破棄

私たちの目標は、AI の力をユーザーフレンドリーかつコスト効率よく K8s 監視にもたらし、あなたが制御を保てるようにすることです。バグに気づいたり提案がある場合は、GitHub Issue を作成するか、hello@kubetail.com にメールを送信してください！

## クイックスタート

kstack スキルをグローバルにインストールするには、このコマンドを実行します：

```console
curl -sS https://kstack.sh/install | bash
```

または、特定のプロジェクトディレクトリにローカルにインストールすることもできます：

```console
curl -sS https://kstack.sh/install | bash -s -- --local
```

インストール後、スキルはエージェントセッション内で利用可能になります：

```
───────────────────────────────────
❯ /kstack-cluster-status
───────────────────────────────────
```

デフォルトでは、スクリプトは kstack-* 名前空間プレフィックスでスキルをインストールしますが、--no-prefix フラグで無効にできます。また、利用可能なすべてのエージェント（例：Claude、Codex、OpenCode）にスキルをインストールしますが、--agent フラグで個々のエージェントを選択できます（[インストール](https://kstack.sh/concepts/installation)を参照）。

Kstack は認証にローカルの `kubeconfig` ファイルを使用するため、RBAC 権限を使用してあなたの代わりにアクションを実行できます。権限の問題が発生した場合は通知します。

## その他の AI エージェント

Kstack は Claude だけでなく、スキルをサポートする任意の AI エージェントで動作します。curl ブートストラップは `PATH` 上のエージェント CLI を自動検出し、それぞれにインストールします。`--agent <name>` で特定のエージェントを指定できます：

| エージェント      | フラグ             | グローバルインストールパス       |
|------------------|--------------------|-------------------------------|
| OpenAI Codex CLI | `--agent codex`    | `~/.codex/skills/`            |
| OpenCode         | `--agent opencode` | `~/.config/opencode/skills/`  |
| Cursor           | `--agent cursor`   | `~/.cursor/skills/`           |
| Factory Droid    | `--agent factory`  | `~/.factory/skills/`          |
| Slate            | `--agent slate`    | `~/.slate/skills/`            |
| Kiro             | `--agent kiro`     | `~/.kiro/skills/`             |
| Hermes           | `--agent hermes`   | `~/.hermes/skills/`           |
| Pi               | `--agent pi`       | `~/.pi/agent/skills/`         |

ローカルインストールはプロジェクトディレクトリ下でこの構造をミラーリングし（例：`<project>/.codex/skills/`）、そのディレクトリ内からエージェントを実行した場合のみ有効になります。 Pi だけは例外で、ローカルのスキルディレクトリは `<project>/.pi/skills/` です（`agent/` セグメントはありません）。

## スキルリファレンス

各スキルはエージェントセッション内で `/<name>` を使って呼び出します。すべてのスキルはデフォルトで読み取り専用です——クラスターの状態を変更するアクションには明示的な確認が必要です。スキルはローカルの `kubeconfig` コンテキストを尊重し、RBAC を尊重します。

**グローバルフラグ**（すべてのスキルでサポート）：

| フラグ            | 説明                                                                |
|-------------------|---------------------------------------------------------------------|
| `--context <ctx>` | 現在の kubeconfig コンテキストを上書き                               |
| `--namespace <n>` | 実行を単一の名前空間にスコープ（デフォルトはアクセス可能なすべて）    |
| `--json`          | 他のツールにパイプするための構造化出力を発行                          |
| `--help`          | ブラウザでスキルのリファレンスドキュメントを開く                      |

---

### 監視

<dl>
<dt>

#### `/cluster-status`

</dt>
<dd>

クラスターの密な健全性スナップショット——ノードの状態、Pod の集計、そして実際に重要な問題のランク付けリスト。

**チェック内容：** クラスターの ID（コンテキスト、Kubernetes バージョン、プラットフォーム）、ノードの `Ready`/`MemoryPressure`/`DiskPressure`/`PIDPressure` 状態と `SchedulingDisabled`、コントロールプレーンとワーカーの分割、すべての名前空間にわたる Pod のフェーズと `Ready` 状態、非ゼロ再起動カウントの Pod、トップ問題リスト（重大度順上位 5）。

**動作方法：** `kubectl version`、`kubectl get nodes -o json`、`kubectl get pods -A -o json` を並行してファンアウトし、それぞれをコンテキストごとのキャッシュ（`cluster.json`、`nodes.json`、`pods.json`）に書き込む。集計と重大度ランキングはクライアント側で行われる。フォローアップの質問（「Pod を一覧表示」、「<ノード>上の Pod」、「テイントされているノードはどれか」）はスキルを再呼び出しせずに `jq` でキャッシュを読み取ることで回答される。

**オプション：**
- `--refresh` — 最新データを取得し、キャッシュをバイパスして更新（デフォルト：`false`）
- `--ttl <duration>` — `<duration>` より古い場合のみキャッシュを更新（デフォルト：`15m`）

**リファレンス：** [kstack.sh/reference/skills/cluster-status](https://kstack.sh/reference/skills/cluster-status)

</dd>
<dt>

#### `/events`

</dt>
<dd>

最近のクラスターイベント、理由でグループ化され重大度でランク付け——`Pulled`/`Created`/`Started` のノイズにシグナルが埋もれないように。

**チェック内容：** すべての名前空間にわたる `Warning` イベント、`(reason, involvedObject.kind, namespace)` でグループ化；注目すべき `Normal` イベント（`Killing`、`Preempting`、`NodeNotReady`、`Rebooted`、`FailedScheduling`）、おしゃべりな理由（`Pulled`、`Created`、`Started`、`Scheduled`、`SuccessfulCreate`）はテール行に折りたたまれる。各グループにはカウント、最初/最後のタイムスタンプ、最新のメッセージ、関与したオブジェクトが含まれる。

**動作方法：** 単一の `kubectl get events --all-namespaces` 呼び出し（`events.k8s.io/v1` に対して、`lastTimestamp` でサーバー側ソート）、`events.json` としてコンテキストごとのキャッシュに書き込まれる。集計とランキングはクライアント側で行われる。フォローアップ（「payments のみ」、「pod/checkout-7c9 のイベント」、「抑制されたものを表示」）は `jq` でキャッシュを読み取ることで回答され——所有者を 1 レベル上（`Pod` → `ReplicaSet` → `Deployment`）まで辿るので、コントローラーが発火させたイベントが見逃されない。

**オプション：**
- `--refresh` — 最新データを取得し、キャッシュをバイパスして更新（デフォルト：`false`）
- `--ttl <duration>` — `<duration>` より古い場合のみキャッシュを更新（デフォルト：`5m`）

**リファレンス：** [kstack.sh/reference/skills/events](https://kstack.sh/reference/skills/events)

</dd>

---

### トラブルシューティング

<dl>
<dt>

#### `/investigate`

</dt>
<dd>

失敗したり疑わしいリソースのルートコーズ調査を開始します。スキルが呼び出されると、スクリプトを実行して初期データバンドルを収集し、エージェントにブリーフィングします。そこから、自然言語でフォローアップの質問ができ、エージェントは持っているものから回答するか、新しいものを取得するか、別のツールを使用するかを決定します。

**収集内容：** 問題のあるリソースの spec と status；それらのリソースとその所有者（`Pod` の `ReplicaSet` と `Deployment`、`Job` の `CronJob` など）のイベント；現在と以前のコンテナのログ（失敗を最も含む可能性の高い行に切り詰め）；明らかな関連リソース（バッキング `Service`、マウントされた `ConfigMap`/`Secret` 名、バインドされた `PVC`、参照された `ServiceAccount`）；関連する場合は Pod がスケジュールされているノード。

**動作方法：** スキルは Kubernetes API からバンドルをロードし、その読み方（終了コード、イベントの理由、一般的な状態の組み合わせ）、フォローアップが古いバンドルから推論するのではなく再取得すべき場合、[`/logs`](#logs)、[`/exec`](#exec)、または [`/metrics`](#metrics) にハンドオフする場合についてエージェントにブリーフィングする。

**引数：**
- `<target>` — `<kind>/<name>`（例：`pod/checkout-7c9`）または自然言語（`api デプロイメント`、`なぜ checkout がクラッシュしているか`）。オプション——省略するとスキルがプロンプト。

**オプション：** なし。プロンプトやフォローアップの自然言語でログ、時間窓、リソースをスコープ。

**リファレンス：** [kstack.sh/reference/skills/investigate](https://kstack.sh/reference/skills/investigate)

</dd>
<dt>

#### `/logs`

</dt>
<dd>

AI 駆動のログフェッチャー。自然言語で探しているものを説明すると、エージェントが正しい Pod を見つけ、時間窓を選び、重要な行のみを取得する grep フィルターを構築します。ストリームはあなたとエージェントの両方が接続している **tmux** ウィンドウ内で実行されます。

**動作方法：** エージェントはあなたの説明を Kubetail クエリに変換し、デタッチされた tmux セッション（例：`kstack-logs-api-server`）を開始し、それに接続した新しいターミナルウィンドウを開こうとし、フォールバックとしてチャットに `tmux attach` コマンドを出力します。あなたとエージェントは同じペインを共有します——スクロール、検索、またはライブテールを見ることができ、エージェントはトークンを節約するために控えめに読みます。

**要件：** エージェントの `$PATH` 上の `tmux`、および Kubetail がクラスターにインストールされていること（不足している場合、スキルは Helm 経由でのインストールを提案）。

**引数：**
- `<target>` — 取得するものの自然言語説明（`api`、`過去 1 時間の api のエラー`、`過去 15 分間の checkout の "timeout"`）。オプション——省略するとスキルがプロンプト。

**オプション：**
- `--attach` — 新しいセッションを開始する代わりに既存の kstack tmux セッションにエージェントを接続
- `--detach` — 新しいデタッチセッションを開始（ターミナルウィンドウは開かず、手動で接続）

**リファレンス：** [kstack.sh/reference/skills/logs](https://kstack.sh/reference/skills/logs)

</dd>
<dt>

#### `/metrics`

</dt>
<dd>

AI 駆動のメトリクスフェッチャー。見たいものを説明すると、エージェントが正しいターゲットを解決し、合理的な時間窓を選び、コンパクトなサマリーを返します。読み取り専用でクラスターの状態を変更しません。

**動作方法：** エージェントはあなたの説明を適切なソース（`metrics-server` または Prometheus）へのクエリに変換し、完全なシリーズをモデルにパイプするのではなくサマリー統計（p50、p95、最大値）を報告し、スコープが意図より広く見える場合は実行前に解決されたクエリを表示します。メトリクスが*なぜ*動いたかについては [`/logs`](#logs) にハンドオフ；ルートコーズコンテキストには [`/investigate`](#investigate)；完全なライトサイジングスイープには [`/audit-cost`](#audit-cost)。

**引数：**
- `<target>` — 自然言語説明（`api`、`過去 1 時間の checkout のメモリ`、`payments の CPU 別上位 Pod`）。オプション——省略するとスキルがプロンプト。

**オプション：** なし。プロンプトやフォローアップの自然言語でターゲット、メトリクス、時間窓をスコープ。

**リファレンス：** [kstack.sh/reference/skills/metrics](https://kstack.sh/reference/skills/metrics)

</dd>
<dt>

#### `/exec`

</dt>
<dd>

`kubectl exec` の AI 駆動版。自然言語でターゲットを説明すると、エージェントが正しいメカニズムを選択します：実行中のコンテナへの通常の `exec`、ターゲットに使用可能なシェルがない場合のエフェメラルデバッグコンテナ、またはノード上の特権シェル。セッションはあなたとエージェントの両方が接続している **tmux** ウィンドウ内で実行されます——どちらも入力でき、両方が出力を見ます。

**動作方法：** エージェントはデタッチされた tmux セッション（例：`kstack-exec-api-server`）を開始し、それに接続した新しいターミナルウィンドウを開こうとし、フォールバックとしてチャットに `tmux attach` コマンドを出力します。エージェントはトークンを節約するためにペインから控えめに読みます。終了するよう伝えると、tmux セッションを終了し作成した Pod を削除します。

**要件：** エージェントの `$PATH` 上の `tmux`。

**安全性：** `/exec` は `disable-model-invocation: true` で出荷——上記の特権モードを考慮して、エージェントは自らシェルを開始しません。あなたが `/exec` と入力したときのみ実行されます。

**引数：**
- `<target>` — 自然言語説明（`api`、`api/sidecar`、`node worker-3`、`debug api`）。オプション——省略するとスキルがプロンプト。

**オプション：**
- `--image <image>` — ノードとデバッグコンテナモードに使用するイメージ（デフォルト `netshoot`）
- `--attach` — 新しいセッションを開始する代わりに既存の kstack tmux セッションにエージェントを接続
- `--detach` — 新しいデタッチセッションを開始（ターミナルウィンドウは開かず、手動で接続）

**リファレンス：** [kstack.sh/reference/skills/exec](https://kstack.sh/reference/skills/exec)

</dd>
</dl>

---

### 監査

すべての監査スキルはランク付けされた発見リスト（重大度 + 証拠 + 推奨修正）を生成します。

<dl>
<dt>

#### `/audit-security`

</dt>
<dd>

RBAC レビュー、Pod セキュリティポスチャー、権限縮小の推奨。過剰権限の ID とワークロードを探します——使用している以上のアクセス権を持つ `ServiceAccount`、root として実行されたりホストレベルのエスケープを持つ Pod、名前空間スコープのロールで十分なところにクラスター全体の権限を付与するバインディング。

**動作方法：** Kubernetes API のみをクエリ；exec なし、ログアクセスなし。発見はブラスト半径でランク付け（クラスタースコープのワイルドカードが名前空間スコープより上、ホストエスケープが seccomp の欠如より上）。RBAC チェックは**静的**——`Role` が何を付与するかを見つけ、サブジェクトが実際に何を使うかではない；真に未使用の権限の検出には監査ログ分析が必要で、このスキルはそれを行わない。`Secret` は名前、名前空間、タイプのみで参照——内容は決して読まれない。

**引数：**
- `<scope>` — 自然言語スコープ（`rbac`、`kube-system の Pod`）。オプション——完全なスイープのために省略。

**オプション：** なし。プロンプトやフォローアップの自然言語でスコープ。

**リファレンス：** [kstack.sh/reference/skills/audit-security](https://kstack.sh/reference/skills/audit-security)

</dd>
<dt>

#### `/audit-network`

</dt>
<dd>

NetworkPolicy、Service、Ingress、Gateway API、DNS、暗号化のサニティチェック。壊れたまたは欠けているクラスターネットワーキングの部分を探します——何にもマッチしない `NetworkPolicy` インスタンス、エンドポイントのない `Service`、解決しない `Ingress` と Gateway API ルート、DNS の問題、メッシュが利用可能なのにプレーンテキストで通信するワークロード。

**動作方法：** Kubernetes API に加えて、存在する場合は CoreDNS メトリクスとメッシュ CRD をクエリ。TLS チェックは「RBAC により Secret の内容が読めない」と「期限切れ」を区別し、誤検知を報告しない。発見はワークフロー別にグループ化され、証拠（セレクター、エンドポイント、ConfigMap キー）を含む——判決だけでなく。

**引数：**
- `<scope>` — 自然言語スコープ（`policies`、`prod の ingress`）。オプション——完全なスイープのために省略。

**オプション：** なし。プロンプトやフォローアップの自然言語でスコープ。

**リファレンス：** [kstack.sh/reference/skills/audit-network](https://kstack.sh/reference/skills/audit-network)

</dd>
<dt>

#### `/audit-cost`

</dt>
<dd>

リソースの無駄とライトサイジングの推奨。過剰プロビジョニング、アイドル状態、または何も使用していないストレージとロードバランサーを抱えているワークロードを探します。

**動作方法：** 複数のワークフローを並行して実行し、`metrics-server` と Prometheus の読み取りを `Job`/`CronJob` ステータス、PV/PVC バインディング、`LoadBalancer` エンドポイントの Kubernetes API に対して結合する。発見は潜在的な影響でランク付け（大きなリクエスト対使用量のギャップとアイドルワークロードがマウントされていない PVC と `Released` PV より上）、実際に重要なリクエスト対使用量のギャップのみがフラグ——小さな差異はノイズ。ヘッダーは常にソース（ライブの `metrics-server`、履歴の Prometheus）と有効なルックバックを述べ、読者が推奨にどの程度の重みを与えるか判断できるようにする。

**引数：**
- `<scope>` — 自然言語スコープ（`requests`、`staging のアイドル`）。オプション——完全なスイープのために省略。

**オプション：** なし。プロンプトやフォローアップの自然言語でスコープ。

**リファレンス：** [kstack.sh/reference/skills/audit-cost](https://kstack.sh/reference/skills/audit-cost)

</dd>
<dt>

#### `/audit-outdated`

</dt>
<dd>

古いクラスターコンポーネント、既知の CVE、利用可能なバージョンアップ。コントロールプレーン、ノード、コンテナイメージ、Helm チャート、CRD、オペレーター、マニフェストがターゲットとする API サーフェスのバージョンドリフトを探します。

**動作方法：** Kubernetes API に加えて外部インデックス（リリーススケジュール、レジストリ、Helm リポジトリ、Trivy DB、CVE フィード）に対してワークフローを並行して実行する。発見はイメージダイジェストで重複排除——多くの Pod にまたがって共有される 1 つの古いイメージがレポートを支配しない。CVE エントリには利用可能な場合の重大度と CISA KEV ステータスが含まれる——KEV ヒットは既知の悪用のない CVSS-high 発見より上にランク付け。「サポートウィンドウ内のドリフト」は「EOL」とは別に報告——前者はルーティン、後者は緊急。サポートリスト外のレジストリについては、イメージをサイレントにスキップするのではなくスキルがそう述べる。

**引数：**
- `<scope>` — 自然言語スコープ（`images`、`kube-system の cves`）。オプション——完全なスイープのために省略。

**オプション：** なし。プロンプトやフォローアップの自然言語でスコープ。

**リファレンス：** [kstack.sh/reference/skills/audit-outdated](https://kstack.sh/reference/skills/audit-outdated)

</dd>
</dl>

---

### その他

<dl>
<dt>

#### `/cleanup`

</dt>
<dd>

kstack がクラスターに作成したすべてのリソースを削除します。ローカル状態をクリアする [`/forget`](#forget) の対応物。

**削除内容：** `kstack.kubetail.com/owned-by=kstack` とアノテーションされているもの——[`/exec`](#exec) からのエフェメラルデバッグコンテナと特権ノードシェル Pod、短命のツールボックス Pod、それらをサポートするために作成された一時的な RBAC や ConfigMap。アノテーションのないリソースは同じ名前空間にあっても決して触れない。

**動作方法：** エージェントは見つけたものすべてを名前空間と種類でグループ化してリストし、削除前に確認を求める。セット全体を承認するか、自然言語で特定のアイテムをスキップするよう伝えることができる。削除が失敗した場合——通常はファイナライザーまたは権限の問題——エージェントはどのリソースが残っていてその理由を報告し、盲目的に再試行しない。

**安全性：** `/cleanup` は `disable-model-invocation: true` で出荷——クラスターリソースを削除するため、エージェントは自らクリーンアップを開始しない。あなたが `/cleanup` と入力したときのみ実行されます。

**オプション：** なし。異なるクラスターをターゲットにするにはグローバル `--context <ctx>` フラグを使用。

**リファレンス：** [kstack.sh/reference/skills/cleanup](https://kstack.sh/reference/skills/cleanup)

</dd>
<dt>

#### `/forget`

</dt>
<dd>

マシン上の kstack のローカル状態を消去します。時間をかけて kstack はクラスターの作業メモリを構築します——最近のクエリ結果、検出された統合、リソースのフィンガープリント、異常を検出するために使用するベースライン。このスキルはクリーンスレートを強制します。クラスター自体には触れません；そのためには [`/cleanup`](#cleanup) を参照。

**クリア内容：** 状態は `~/.config/kstack/` 下に kubeconfig コンテキストごとにパーティション分割されて存在する。
- **キャッシュ**（`~/.config/kstack/cache/<context>/`）——最近のクエリ結果、ログバッファー、重複排除テーブル、進行中のウォッチャー状態。再構築コストが低い；自由にクリア。
- **学習済み状態**（`~/.config/kstack/state/<context>/`）——検出された統合、リソースのフィンガープリント、ベースライン、クラスターごとの設定。次の使用時に再構築されるが、完全に再形成するのに数回のインタラクションが必要な場合がある。

**動作方法：** デフォルトでは現在の kubeconfig コンテキストのキャッシュと学習済み状態をクリア——`staging` を忘れても `prod` には決して影響しない。異なるクラスターをターゲットにするにはグローバル `--context <ctx>` フラグを使用。クラスターが再構築または移行された後（kstack が古いフィンガープリントを信頼するのをやめるよう）、ベースラインが古く感じられるとき、以前のセッションが間違ったことを教えたとき、またはマシンを引き渡してクラスター固有の状態を残したくないときに実行する。

**安全性：** `/forget` は `disable-model-invocation: true` で出荷——キャッシュされたコンテキストが予期せず失われないよう、エージェントは自らローカル状態を消去しない。あなたが `/forget` と入力したときのみ実行されます。

**オプション：**
- `--all` — 現在のコンテキストだけでなく、すべてのコンテキストのキャッシュと学習済み状態をクリア。

**リファレンス：** [kstack.sh/reference/skills/forget](https://kstack.sh/reference/skills/forget)

</dd>
</dl>

## アップグレード

kstack スキルを実行すると、エージェントは新しい kstack リリースが利用可能かどうかを静かにチェックし、見つかった場合はレスポンスの先頭に 1 行の通知を表示します。**「upgrade kstack」** と言うだけでエージェントがあなたの代わりに kstack アップグレードスクリプトを実行します；**「dismiss」** と言うと次のリリースまで通知を非表示にします。これはグローバルインストールとローカルインストールの両方で同じように機能します。

ヘルパーを直接実行することもできます：

```console
# グローバルインストール
~/.config/kstack/bin/upgrade

# ローカルインストール（プロジェクトディレクトリから）
./.kstack/bin/upgrade
```

アップグレードは冪等で、いつでも安全に実行できます。

## アンインストール

インストールにバンドルされているアンインストールヘルパーを実行します：

```console
# グローバルインストール
~/.config/kstack/bin/uninstall

# ローカルインストール（プロジェクトディレクトリから）
./.kstack/bin/uninstall
```

両方のヘルパーは削除前にプロンプトを表示します。インストールルート（`~/.config/kstack` または `<project>/.kstack`）とすべての kstack 所有のスキルスロットをクリアし、同じエージェントディレクトリ内のユーザー作成スキルには触れません。

## 開発

インストーラーのペイロードは `src/`（スキル、ヘルパー、lib、スキーマ）の下にあります。開発ツール——`Makefile`、`scripts/`、`tests/`、CI——はリポジトリルートにあります。kstack をハックしている場合は、完全なコントリビューターガイドについて `CONTRIBUTING.md` を参照してください。

ルート `Makefile` を介した一般的なコントリビュータコマンド：

```console
make install      # 開発モードインストール——スキルを <repo>/.<agent>/skills/ にレンダリング
make test         # 高速 bats 層（ユニット + 統合）
make test-e2e     # クラスターバックアップ層（kind + docker）
make test-evals   # 評価ハーネス（ANTHROPIC_API_KEY または Claude CLI が必要）
make lint         # shellcheck
make clean        # 開発モードアーティファクトを削除
```

各ターゲットは直接実行可能な `scripts/` 下のスクリプトにシェルアウトします。

`make test` には bats-core が必要です（`brew install bats-core` / `apt install bats`）。テストは `tests/unit/`（ソース関数テスト）と `tests/integration/`（隔離された `$HOME` とローカルベア git リポジトリに対するエンドツーエンド CLI テスト）にあります。CI はすべての PR で Ubuntu、macOS、Windows の完全なスイートを実行します——`.github/workflows/ci.yml` を参照。

## 参加する

Kubetail では、Kubernetes 向けの最も**ユーザーフレンドリー**、**コスト効率**、**安全**なログプラットフォームを構築しており、あなたの貢献を歓迎します！貢献できる方法：

* UI/UX デザイン
* React フロントエンド開発
* 問題の報告と機能の提案

開発セットアップとガイドラインについては [CONTRIBUTING.md](CONTRIBUTING.md) を参照。hello@kubetail.com でお問い合わせいただくか、[Discord サーバー](https://discord.gg/CmsmWAVkvX) または [Slack チャンネル](https://join.slack.com/t/kubetail/shared_invite/zt-2cq01cbm8-e1kbLT3EmcLPpHSeoFYm1w) に参加してください。

## 注記

* Garry Tan の [gstack](https://github.com/garrytan/gstack) にインスパイアされました

イスタンブールで 🧿 を込めて制作
