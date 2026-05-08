# kstack

*Pacote de habilidades para o Claude Code que ajuda você a monitorar seus clusters K8s de forma superinteligente*

<a href="https://discord.gg/CmsmWAVkvX"><img src="https://img.shields.io/discord/1212031524216770650?logo=Discord&style=flat-square&logoColor=FFFFFF&labelColor=5B65F0&label=Discord&color=64B73A"></a>
[![Slack](https://img.shields.io/badge/Slack-kubetail-364954?logo=slack&labelColor=4D1C51)](https://kubernetes.slack.com/archives/C08SHG1GR37)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](CODE_OF_CONDUCT.md)
[![Contributor Resources](https://img.shields.io/badge/Contributor%20Resources-purple?style=flat-square)](https://github.com/kubetail-org)

[English](../README.md) | [简体中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Español](README.es.md) | Português | [Français](README.fr.md)

## Introdução

<img width="350" alt="kstack" src="https://github.com/user-attachments/assets/cfe998de-a85a-44bb-8eb2-5f5efe7449ea" />
<br>
<br>

**Kstack** é um pacote de habilidades para o Claude Code que ajuda você a realizar tarefas de monitoramento, resolução de problemas e auditoria em seus clusters K8s de forma inteligente e eficiente. Além de usar ferramentas padrão como kubectl, ele delega trabalho de shell para ferramentas como [Kubetail](https://github.com/kubetail-org/kubetail), [Helm](https://helm.sh), [Trivy](https://github.com/aquasecurity/trivy), [Pluto](https://github.com/FairwindsOps/pluto) antes de enviar os resultados ao Claude, mantendo as respostas rápidas e eficientes em tokens. O Kstack também detecta os serviços em execução no seu cluster e usa suas ferramentas especializadas quando necessário (p. ex., [Cilium](https://cilium.io), [Istio](https://istio.io)).

Após instalar o kstack, você terá acesso a estas habilidades dentro do Claude Code:

**Monitoramento**
* `/cluster-status` — Instantâneo de saúde do cluster (reinicializações de Pod, condições de nós, pressão de recursos)
* `/events` — Eventos recentes, classificados por severidade

**Resolução de problemas**
* `/investigate` — Análise de causa raiz em eventos, logs e recursos relacionados
* `/logs` — Sessão tmux compartilhada que traduz linguagem natural em buscas e análises de logs (via [Kubetail](https://github.com/kubetail-org/kubetail))
* `/metrics` — Buscar métricas de CPU, memória e outros recursos para pods, nós e workloads
* `/exec` — Shell tmux compartilhado em um pod, nó ou contêiner de depuração efêmero

**Auditorias**
* `/audit-security` — RBAC, postura de segurança de pods, redução de privilégios
* `/audit-network` — NetworkPolicy, Service, Ingress, GatewayAPI, DNS e verificações de criptografia
* `/audit-cost` — Solicitações vs. uso, superprovisionamento, capacidade ociosa
* `/audit-outdated` — Serviços desatualizados, CVEs conhecidos, atualizações de versão disponíveis

**Diversos**
* `/cleanup` — Remover todos os recursos de propriedade do kstack do cluster (contêineres de depuração, clones de pods, jobs watcher)
* `/forget` — Limpar o cache local do kstack e descartar o que ele aprendeu sobre seus clusters

Nosso objetivo é levar o poder da IA ao monitoramento de K8s de uma forma amigável ao usuário e econômica que mantém você no controle. Se você notar um bug ou tiver uma sugestão, crie um Issue no GitHub ou envie um e-mail (hello@kubetail.com)!

## Início rápido

Para instalar as habilidades do kstack globalmente, execute este comando:

```console
curl -sS https://kstack.sh/install | bash
```

Alternativamente, você pode instalá-las localmente dentro de um diretório de projeto específico:

```console
curl -sS https://kstack.sh/install | bash -s -- --local
```

Após a instalação, as habilidades estarão disponíveis dentro das suas sessões de agente:

```
───────────────────────────────────
❯ /kstack-cluster-status
───────────────────────────────────
```

Por padrão, o script instalará as habilidades com um prefixo de namespace kstack-*, mas você pode desabilitar isso com o flag --no-prefix. Ele também instalará as habilidades para todos os seus agentes disponíveis (p. ex., Claude, Codex, OpenCode), mas você pode escolher agentes individuais com o flag --agent (veja [Instalação](https://kstack.sh/concepts/installation)).

O Kstack usa seu arquivo `kubeconfig` local para autenticação, portanto poderá usar suas permissões RBAC para realizar ações em seu nome. Se encontrar problemas de permissão, ele vai te avisar.

## Outros agentes de IA

O Kstack funciona com qualquer agente de IA que suporte habilidades, não apenas o Claude. O bootstrap do curl detecta automaticamente quais CLIs de agentes estão no seu `PATH` e instala para cada um. Você pode direcionar a um agente específico com `--agent <name>`:

| Agente           | Flag               | Caminho de instalação global   |
|------------------|--------------------|--------------------------------|
| OpenAI Codex CLI | `--agent codex`    | `~/.codex/skills/`             |
| OpenCode         | `--agent opencode` | `~/.config/opencode/skills/`   |
| Cursor           | `--agent cursor`   | `~/.cursor/skills/`            |
| Factory Droid    | `--agent factory`  | `~/.factory/skills/`           |
| Slate            | `--agent slate`    | `~/.slate/skills/`             |
| Kiro             | `--agent kiro`     | `~/.kiro/skills/`              |
| Hermes           | `--agent hermes`   | `~/.hermes/skills/`            |
| Pi               | `--agent pi`       | `~/.pi/agent/skills/`          |

As instalações locais espelham essa estrutura sob o diretório do projeto (p. ex., `<project>/.codex/skills/`) e são detectadas apenas quando o agente é executado de dentro desse diretório. O Pi é a única exceção — seu diretório local de skills é `<project>/.pi/skills/` (sem o segmento `agent/`).

## Referência de habilidades

Cada habilidade é invocada com `/<name>` dentro de uma sessão de agente. Todas as habilidades são somente leitura por padrão — qualquer ação que mute o estado do cluster requer confirmação explícita. As habilidades respeitam seu contexto local de `kubeconfig` e o RBAC.

**Flags globais** (suportados por cada habilidade):

| Flag              | Descrição                                                                |
|-------------------|--------------------------------------------------------------------------|
| `--context <ctx>` | Substituir o contexto atual do kubeconfig                                |
| `--namespace <n>` | Limitar a execução a um único namespace (padrão: todos os acessíveis)    |
| `--json`          | Emitir saída estruturada para canalizar em outras ferramentas            |
| `--help`          | Abrir a documentação de referência da habilidade no seu navegador        |

---

### Monitoramento

<dl>
<dt>

#### `/cluster-status`

</dt>
<dd>

Um instantâneo denso de saúde do cluster — condições de nós, agregados de pods e uma lista classificada dos problemas que realmente importam.

**O que verifica:** identidade do cluster (contexto, versão do Kubernetes, plataforma), condições `Ready`/`MemoryPressure`/`DiskPressure`/`PIDPressure` dos nós e `SchedulingDisabled`, divisão do plano de controle vs. worker, fase do pod e `Ready` em todos os namespaces, pods com contagens de reinicialização não nulas e uma lista de principais problemas classificados (top 5 por severidade).

**Como funciona:** distribui `kubectl version`, `kubectl get nodes -o json` e `kubectl get pods -A -o json` em paralelo, escrevendo cada um em um cache por contexto (`cluster.json`, `nodes.json`, `pods.json`). A agregação e o ranking de severidade acontecem do lado do cliente. Perguntas de acompanhamento ("listar pods", "pods em <nó>", "quais nós têm taints") são respondidas lendo o cache com `jq` em vez de reinvocar a habilidade.

**Opções:**
- `--refresh` — buscar dados mais recentes, ignorando e atualizando o cache (padrão: `false`)
- `--ttl <duration>` — só atualizar o cache se mais antigo que `<duration>` (padrão: `15m`)

**Referência:** [kstack.sh/reference/skills/cluster-status](https://kstack.sh/reference/skills/cluster-status)

</dd>
<dt>

#### `/events`

</dt>
<dd>

Eventos recentes do cluster, agrupados por motivo e classificados por severidade para que o sinal não se afogue no ruído de `Pulled`/`Created`/`Started`.

**O que verifica:** eventos `Warning` em todos os namespaces, agrupados por `(reason, involvedObject.kind, namespace)`; eventos `Normal` notáveis (`Killing`, `Preempting`, `NodeNotReady`, `Rebooted`, `FailedScheduling`) com motivos tagarelas (`Pulled`, `Created`, `Started`, `Scheduled`, `SuccessfulCreate`) recolhidos em uma linha de cauda. Cada grupo inclui contagem, primeiro/último timestamp, a mensagem mais recente e os objetos envolvidos.

**Como funciona:** uma única chamada `kubectl get events --all-namespaces` (contra `events.k8s.io/v1`, ordenada do lado do servidor por `lastTimestamp`), escrita no cache por contexto como `events.json`. A agregação e o ranking acontecem do lado do cliente. Perguntas de acompanhamento ("apenas payments", "eventos no pod/checkout-7c9", "mostrar suprimidos") são respondidas lendo o cache com `jq` — e percorrem proprietários um nível acima (`Pod` → `ReplicaSet` → `Deployment`) para não perder eventos disparados por controladores.

**Opções:**
- `--refresh` — buscar dados mais recentes, ignorando e atualizando o cache (padrão: `false`)
- `--ttl <duration>` — só atualizar o cache se mais antigo que `<duration>` (padrão: `5m`)

**Referência:** [kstack.sh/reference/skills/events](https://kstack.sh/reference/skills/events)

</dd>

---

### Resolução de problemas

<dl>
<dt>

#### `/investigate`

</dt>
<dd>

Inicia uma investigação de causa raiz em um recurso com falha ou suspeito. Quando a habilidade é invocada, ela executa um script para coletar um pacote de dados inicial e faz um briefing ao agente. A partir daí, você pode fazer perguntas de acompanhamento em linguagem natural e o agente decide se responde do que tem, busca algo novo ou usa outra ferramenta.

**O que coleta:** spec e status dos recursos problemáticos; eventos nesses recursos e seus proprietários (o `ReplicaSet` e `Deployment` de um `Pod`, o `CronJob` de um `Job`, etc.); logs de contêineres atuais e anteriores, truncados às linhas que provavelmente contêm a falha; recursos relacionados óbvios (`Service` de suporte, nomes de `ConfigMap`/`Secret` montados, `PVC`s vinculados, `ServiceAccount` referenciado); e o nó no qual os pods estão agendados quando relevante.

**Como funciona:** a habilidade carrega o pacote da API do Kubernetes e faz um briefing ao agente sobre como lê-lo (códigos de saída, motivos de eventos, combinações de estado comuns), quando as perguntas de acompanhamento devem buscar novamente em vez de raciocinar a partir do pacote obsoleto, e quando transferir para [`/logs`](#logs), [`/exec`](#exec) ou [`/metrics`](#metrics).

**Argumentos:**
- `<target>` — `<kind>/<name>` (p. ex., `pod/checkout-7c9`) ou linguagem natural (`o deployment de api`, `por que o checkout está falhando`). Opcional — a habilidade solicitará se omitido.

**Opções:** nenhuma. Limitar logs, janelas de tempo ou recursos via linguagem natural no prompt ou nas perguntas de acompanhamento.

**Referência:** [kstack.sh/reference/skills/investigate](https://kstack.sh/reference/skills/investigate)

</dd>
<dt>

#### `/logs`

</dt>
<dd>

Um buscador de logs alimentado por IA. Descreva o que você está procurando em linguagem natural e o agente encontra os pods certos, escolhe a janela de tempo e constrói o filtro grep para buscar apenas as linhas que importam. O stream é executado dentro de uma janela **tmux** à qual você e o agente estão ambos conectados.

**Como funciona:** o agente traduz sua descrição em uma consulta do Kubetail, inicia uma sessão tmux desconectada (p. ex., `kstack-logs-api-server`), tenta abrir uma nova janela de terminal conectada a ela e imprime o comando `tmux attach` no chat como alternativa. Você e o agente compartilham o mesmo painel — você pode rolar, pesquisar ou assistir ao tail ao vivo; o agente lê de forma conservadora para economizar tokens.

**Requisitos:** `tmux` no `$PATH` do agente e Kubetail instalado no cluster (a habilidade oferece instalá-lo via Helm se estiver ausente).

**Argumentos:**
- `<target>` — descrição em linguagem natural do que buscar (`api`, `erros da última hora no api`, `checkout por "timeout" nos últimos 15m`). Opcional — a habilidade solicitará se omitido.

**Opções:**
- `--attach` — conectar o agente a uma sessão tmux de kstack existente em vez de iniciar uma nova
- `--detach` — iniciar uma nova sessão desconectada (sem abrir janela de terminal, conectar manualmente)

**Referência:** [kstack.sh/reference/skills/logs](https://kstack.sh/reference/skills/logs)

</dd>
<dt>

#### `/metrics`

</dt>
<dd>

Um buscador de métricas alimentado por IA. Descreva o que você quer ver e o agente resolve o alvo correto, escolhe uma janela de tempo razoável e retorna um resumo compacto. Somente leitura e nunca muta o estado do cluster.

**Como funciona:** o agente traduz sua descrição em uma consulta contra a fonte adequada (`metrics-server` ou Prometheus), relata estatísticas de resumo (p50, p95, máx) em vez de canalizar a série completa pelo modelo, e mostra a consulta resolvida antes de executá-la quando o escopo parece mais amplo que o pretendido. Para o *porquê* de uma métrica ter se movido, transfere para [`/logs`](#logs); para contexto de causa raiz, [`/investigate`](#investigate); para uma varredura completa de dimensionamento correto, [`/audit-cost`](#audit-cost).

**Argumentos:**
- `<target>` — descrição em linguagem natural (`api`, `memória no checkout última 1h`, `pods principais por CPU em payments`). Opcional — a habilidade solicitará se omitido.

**Opções:** nenhuma. Limitar o alvo, métrica e janela de tempo via linguagem natural no prompt ou nas perguntas de acompanhamento.

**Referência:** [kstack.sh/reference/skills/metrics](https://kstack.sh/reference/skills/metrics)

</dd>
<dt>

#### `/exec`

</dt>
<dd>

Uma versão alimentada por IA do `kubectl exec`. Descreva o alvo em linguagem natural e o agente escolhe o mecanismo correto: um `exec` normal em um contêiner em execução, um contêiner de depuração efêmero quando o alvo não tem shell utilizável, ou um shell privilegiado em um nó. A sessão é executada dentro de uma janela **tmux** à qual você e o agente estão ambos conectados — qualquer um pode digitar, ambos veem a saída.

**Como funciona:** o agente inicia uma sessão tmux desconectada (p. ex., `kstack-exec-api-server`), tenta abrir uma nova janela de terminal conectada a ela e imprime o comando `tmux attach` no chat como alternativa. O agente lê do painel de forma conservadora para economizar tokens. Diga a ele para desmontar e ele mata a sessão tmux e deleta qualquer pod que criou.

**Requisitos:** `tmux` no `$PATH` do agente.

**Segurança:** `/exec` vem com `disable-model-invocation: true` — o agente nunca inicia um shell por conta própria. Só é executado quando você digita `/exec`, deliberadamente, dados os modos privilegiados acima.

**Argumentos:**
- `<target>` — descrição em linguagem natural (`api`, `api/sidecar`, `node worker-3`, `debug api`). Opcional — a habilidade solicitará se omitido.

**Opções:**
- `--image <image>` — imagem para usar nos modos de nó e contêiner de depuração (padrão `netshoot`)
- `--attach` — conectar o agente a uma sessão tmux de kstack existente em vez de iniciar uma nova
- `--detach` — iniciar uma nova sessão desconectada (sem abrir janela de terminal, conectar manualmente)

**Referência:** [kstack.sh/reference/skills/exec](https://kstack.sh/reference/skills/exec)

</dd>
</dl>

---

### Auditorias

Todas as habilidades de auditoria produzem uma lista classificada de descobertas (severidade + evidência + correção sugerida).

<dl>
<dt>

#### `/audit-security`

</dt>
<dd>

Revisão de RBAC, postura de segurança de pods e recomendações de redução de privilégios. Procura identidades e workloads com excesso de privilégios — `ServiceAccounts` com mais acesso do que usam, pods sendo executados como root ou com escapes em nível de host, e bindings que concedem poder de todo o cluster onde uma função com escopo de namespace seria suficiente.

**Como funciona:** consulta apenas a API do Kubernetes; sem exec, sem acesso a logs. As descobertas são classificadas por raio de explosão (coringas de escopo de cluster acima dos de namespace, escapes de host acima de seccomp ausente). As verificações de RBAC são **estáticas** — elas encontram o que os `Roles` concedem, não o que os sujeitos realmente usam; detectar permissões verdadeiramente não utilizadas requer análise de log de auditoria, que esta habilidade não faz. Os `Secrets` são referenciados apenas por nome, namespace e tipo — o conteúdo nunca é lido.

**Argumentos:**
- `<scope>` — escopo em linguagem natural (`rbac`, `pods em kube-system`). Opcional — omitir para uma varredura completa.

**Opções:** nenhuma. Limitar o escopo via linguagem natural no prompt ou nas perguntas de acompanhamento.

**Referência:** [kstack.sh/reference/skills/audit-security](https://kstack.sh/reference/skills/audit-security)

</dd>
<dt>

#### `/audit-network`

</dt>
<dd>

Verificações de sanidade de NetworkPolicy, Service, Ingress, Gateway API, DNS e criptografia. Procura peças quebradas ou ausentes na rede do cluster, como instâncias de `NetworkPolicy` que não correspondem a nada, `Services` sem endpoints, rotas `Ingress` e Gateway API que não resolverão, problemas de DNS e workloads que falam em texto simples quando uma malha está disponível.

**Como funciona:** consulta a API do Kubernetes mais métricas do CoreDNS e CRDs de malha quando presentes. As verificações TLS distinguem "conteúdo de Secret não legível devido a RBAC" de "expirado" em vez de relatar falsos positivos. As descobertas são agrupadas por fluxo de trabalho e incluem a evidência (seletores, endpoints, chaves de ConfigMap), não apenas o veredicto.

**Argumentos:**
- `<scope>` — escopo em linguagem natural (`policies`, `ingress em prod`). Opcional — omitir para uma varredura completa.

**Opções:** nenhuma. Limitar o escopo via linguagem natural no prompt ou nas perguntas de acompanhamento.

**Referência:** [kstack.sh/reference/skills/audit-network](https://kstack.sh/reference/skills/audit-network)

</dd>
<dt>

#### `/audit-cost`

</dt>
<dd>

Desperdício de recursos e recomendações de dimensionamento correto. Procura workloads que estão superprovisionados, ociosos ou mantendo armazenamento e balanceadores de carga que ninguém está usando.

**Como funciona:** executa vários fluxos de trabalho em paralelo, unindo leituras do `metrics-server` e Prometheus com a API do Kubernetes para status de `Job`/`CronJob`, vinculação de PV/PVC e endpoints de `LoadBalancer`. As descobertas são classificadas por impacto potencial (grandes lacunas de solicitações vs. uso e workloads ociosos acima de PVCs não montados e PVs `Released`), e apenas lacunas de solicitações vs. uso grandes o suficiente para importar na prática são sinalizadas — pequenos deltas são ruído. O cabeçalho sempre indica a fonte (`metrics-server` para ao vivo, Prometheus para histórico) e o lookback efetivo para que o leitor possa julgar quanto peso dar às recomendações.

**Argumentos:**
- `<scope>` — escopo em linguagem natural (`requests`, `ocioso em staging`). Opcional — omitir para uma varredura completa.

**Opções:** nenhuma. Limitar o escopo via linguagem natural no prompt ou nas perguntas de acompanhamento.

**Referência:** [kstack.sh/reference/skills/audit-cost](https://kstack.sh/reference/skills/audit-cost)

</dd>
<dt>

#### `/audit-outdated`

</dt>
<dd>

Componentes de cluster desatualizados, CVEs conhecidos e atualizações de versão disponíveis. Procura desvio de versão no plano de controle, nós, imagens de contêiner, charts do Helm, CRDs, operadores e a superfície de API que seus manifestos visam.

**Como funciona:** executa os fluxos de trabalho em paralelo contra a API do Kubernetes mais índices externos (cronogramas de lançamento, registros, repos do Helm, DB do Trivy, feeds de CVE). As descobertas são desduplicadas por digest de imagem para que uma imagem desatualizada compartilhada em muitos pods não domine o relatório. As entradas de CVE incluem severidade e status CISA KEV quando disponíveis — os hits de KEV são classificados acima das descobertas CVSS-high sem exploração conhecida. "Desvio dentro da janela suportada" é relatado distintamente de "EOL" — o primeiro é rotineiro, o segundo é urgente. Para registros fora da lista suportada, a habilidade diz isso em vez de pular silenciosamente a imagem.

**Argumentos:**
- `<scope>` — escopo em linguagem natural (`images`, `cves em kube-system`). Opcional — omitir para uma varredura completa.

**Opções:** nenhuma. Limitar o escopo via linguagem natural no prompt ou nas perguntas de acompanhamento.

**Referência:** [kstack.sh/reference/skills/audit-outdated](https://kstack.sh/reference/skills/audit-outdated)

</dd>
</dl>

---

### Diversos

<dl>
<dt>

#### `/cleanup`

</dt>
<dd>

Remove cada recurso que o kstack criou no cluster. O complemento de [`/forget`](#forget), que limpa o estado local.

**O que remove:** qualquer coisa anotada com `kstack.kubetail.com/owned-by=kstack` — contêineres de depuração efêmeros e pods de shell de nó privilegiado do [`/exec`](#exec), pods de caixa de ferramentas de curta duração e qualquer RBAC temporário ou ConfigMaps criados para suportá-los. Recursos sem a anotação nunca são tocados, mesmo que vivam no mesmo namespace.

**Como funciona:** o agente lista tudo o que encontrou, agrupado por namespace e tipo, e pede confirmação antes de excluir. Você pode aprovar o conjunto completo ou dizer em linguagem natural para pular itens específicos. Se uma exclusão falhar — geralmente um finalizador ou um problema de permissão — o agente relata quais recursos permanecem e por quê, em vez de tentar novamente às cegas.

**Segurança:** `/cleanup` vem com `disable-model-invocation: true` — o agente nunca inicia uma limpeza por conta própria. Só é executado quando você digita `/cleanup`, pois exclui recursos do cluster.

**Opções:** nenhuma. Use o flag global `--context <ctx>` para direcionar a um cluster diferente.

**Referência:** [kstack.sh/reference/skills/cleanup](https://kstack.sh/reference/skills/cleanup)

</dd>
<dt>

#### `/forget`

</dt>
<dd>

Limpa o estado local do kstack na sua máquina. Com o tempo, o kstack acumula uma memória de trabalho dos seus clusters — resultados de consultas recentes, integrações detectadas, impressões digitais de recursos e linhas de base que usa para detectar anomalias. Esta habilidade força um começo limpo. Não toca o cluster em si; para isso, veja [`/cleanup`](#cleanup).

**O que limpa:** o estado fica em `~/.config/kstack/`, particionado por contexto do kubeconfig.
- **Cache** (`~/.config/kstack/cache/<context>/`) — resultados de consultas recentes, buffers de log, tabelas de deduplicação, estado de watcher em andamento. Barato de reconstruir; limpo livremente.
- **Estado aprendido** (`~/.config/kstack/state/<context>/`) — integrações detectadas, impressões digitais de recursos, linhas de base, preferências por cluster. Reconstruído no próximo uso, mas pode levar algumas interações para se reformar completamente.

**Como funciona:** por padrão limpa tanto o cache quanto o estado aprendido para o contexto atual do kubeconfig — esquecer `staging` nunca afeta `prod`. Use o flag global `--context <ctx>` para direcionar a um cluster diferente. Execute após um cluster ser reconstruído ou migrado (para que o kstack pare de confiar em impressões digitais obsoletas), quando as linhas de base parecerem obsoletas, quando uma sessão anterior ensinou algo errado, ou quando você está passando a máquina e quer que nenhum estado específico do cluster seja deixado para trás.

**Segurança:** `/forget` vem com `disable-model-invocation: true` — o agente nunca apaga o estado local por conta própria. Só é executado quando você digita `/forget`, para que o contexto em cache não seja perdido inesperadamente.

**Opções:**
- `--all` — Limpar cache e estado aprendido para cada contexto, não apenas o atual.

**Referência:** [kstack.sh/reference/skills/forget](https://kstack.sh/reference/skills/forget)

</dd>
</dl>

## Atualização

Quando você executa uma habilidade do kstack, o agente verifica silenciosamente se uma versão mais nova do kstack está disponível e exibe um aviso de uma linha no topo de sua resposta quando encontra. Basta dizer **"upgrade kstack"** e o agente executará o script de atualização do kstack em seu nome; diga **"dismiss"** para ocultar o aviso até o próximo lançamento. Isso funciona da mesma forma para instalações globais e locais.

Você também pode executar o helper diretamente:

```console
# Instalação global
~/.config/kstack/bin/upgrade

# Instalação local (do diretório do projeto)
./.kstack/bin/upgrade
```

As atualizações são idempotentes e seguras para executar a qualquer momento.

## Desinstalação

Execute o helper de desinstalação incluído com sua instalação:

```console
# Instalação global
~/.config/kstack/bin/uninstall

# Instalação local (do diretório do projeto)
./.kstack/bin/uninstall
```

Ambos os helpers perguntam antes de remover. Eles limpam o diretório raiz de instalação (`~/.config/kstack` ou `<project>/.kstack`) e cada slot de habilidades de propriedade do kstack, deixando as habilidades criadas pelo usuário nos mesmos diretórios de agente intocadas.

## Desenvolvimento

O payload do instalador fica em `src/` (habilidades, helpers, lib, schemas). As ferramentas de desenvolvimento — `Makefile`, `scripts/`, `tests/`, CI — ficam na raiz do repositório. Se você estiver hackeando o kstack, consulte `CONTRIBUTING.md` para o guia completo do colaborador.

Comandos comuns de colaboradores, via `Makefile` raiz:

```console
make install      # instalação em modo dev — renderiza habilidades em <repo>/.<agent>/skills/
make test         # níveis bats rápidos (unidade + integração)
make test-e2e     # nível suportado por cluster (kind + docker)
make test-evals   # harness de avaliação (requer ANTHROPIC_API_KEY ou Claude CLI)
make lint         # shellcheck
make clean        # remover artefatos em modo dev
```

Cada alvo faz shell para um script em `scripts/` que também é executável diretamente.

`make test` requer bats-core (`brew install bats-core` / `apt install bats`). Os testes vivem em `tests/unit/` (testes de função de origem) e `tests/integration/` (testes CLI de ponta a ponta contra `$HOME` isolado e repos git bare locais). O CI executa a suite completa no Ubuntu, macOS e Windows para cada PR — veja `.github/workflows/ci.yml`.

## Participar

Na Kubetail, estamos construindo a plataforma de logging mais **amigável ao usuário**, **econômica** e **segura** para Kubernetes e adoraríamos sua contribuição! Como você pode ajudar:

* Design UI/UX
* Desenvolvimento frontend em React
* Relatar problemas e sugerir recursos

Veja [CONTRIBUTING.md](CONTRIBUTING.md) para configuração de desenvolvimento e diretrizes. Entre em contato em hello@kubetail.com, ou junte-se ao nosso [servidor Discord](https://discord.gg/CmsmWAVkvX) ou [canal Slack](https://join.slack.com/t/kubetail/shared_invite/zt-2cq01cbm8-e1kbLT3EmcLPpHSeoFYm1w).

## Notas

* Inspirado pelo [gstack](https://github.com/garrytan/gstack) de Garry Tan

Feito com 🧿 em Istambul
