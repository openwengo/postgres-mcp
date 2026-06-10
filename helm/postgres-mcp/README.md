# postgres-mcp Helm Chart

Deploys the [PostgreSQL MCP Server](https://github.com/neverinfamous/postgres-mcp) on
Kubernetes over **Streamable HTTP** transport.

The chart is built for production MCP serving:

- **Streamable HTTP** transport (`POST/GET /mcp`), **stateless by default** so the
  Deployment scales horizontally with no sticky sessions.
- **Tool filtering** fully configurable from `values.yaml`
  (`server.toolFilter` → `POSTGRES_TOOL_FILTER`).
- **OAuth 2.1** (RFC 9728 / 8414 / 7591) support, or simple bearer-token auth.
- **PodDisruptionBudget** and **HorizontalPodAutoscaler** (both present, disabled
  by default — opt in).
- **Existing Secret only** — the chart *never* creates a Secret for credentials.
  You reference a Secret you manage via `existingSecret.name` (injected with `envFrom`).
- Hardened by default: non-root (uid 1001), read-only root FS, dropped capabilities,
  `RuntimeDefault` seccomp, `/health` probes.

## Prerequisites

- Kubernetes 1.23+ (uses `autoscaling/v2` and `policy/v1`)
- Helm 3.8+
- A reachable PostgreSQL instance
- A Secret containing your DB credentials (see below)

## Install

### 1. Create your Secret (you own this — the chart does not)

The Secret is injected wholesale via `envFrom`, so its **keys must be the env var
names the app reads**:

```bash
kubectl create secret generic postgres-mcp-secrets \
  --from-literal=POSTGRES_URL='postgres://user:pass@postgres:5432/appdb'
# or individual vars: PGHOST, PGPORT, PGUSER, PGPASSWORD, PGDATABASE
# add MCP_AUTH_TOKEN for bearer auth, or OAuth keys if you prefer them in the Secret
```

### 2. Install the chart

From the published GitHub Pages Helm repository (recommended):

```bash
helm repo add postgres-mcp https://openwengo.github.io/postgres-mcp
helm repo update
helm install postgres-mcp postgres-mcp/postgres-mcp \
  --set existingSecret.name=postgres-mcp-secrets \
  --set server.toolFilter=codemode
```

Or directly from a checkout of this repo:

```bash
helm install postgres-mcp ./helm/postgres-mcp \
  --set existingSecret.name=postgres-mcp-secrets \
  --set server.toolFilter=codemode
```

> The Helm repository is published by the
> [`Publish Helm Chart`](../../.github/workflows/helm-publish.yml) workflow on
> every `vX.Y.Z` tag. The chart `version` is managed manually in `Chart.yaml`;
> the workflow stamps `appVersion` (and thus the pulled image tag) from the tag.

## Common configurations

**Code Mode only, with HA enabled:**

```yaml
existingSecret:
  name: postgres-mcp-secrets
server:
  toolFilter: codemode      # ~90% token savings, all 278 tools via V8 isolate
podDisruptionBudget:
  enabled: true
  minAvailable: 1
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 8
```

**OAuth 2.1 (enterprise):**

```yaml
existingSecret:
  name: postgres-mcp-secrets
oauth:
  enabled: true
  issuer: https://keycloak.example.com/realms/postgres-mcp
  audience: postgres-mcp-client
  # jwksUri auto-discovered from the issuer if omitted
```

> Keycloak: add an **Audience mapper** so tokens carry the correct `aud` claim.

**Custom tool filtering** (groups + add/remove individual tools):

```yaml
server:
  toolFilter: "core,jsonb,transactions,+pg_explain,-pg_drop_table"
```

See the project README's *Tool Filtering* section for the full group list and syntax.

## Key values

| Key | Default | Description |
| --- | --- | --- |
| `replicaCount` | `1` | Replicas when autoscaling is off |
| `image.repository` | `writenotenow/postgres-mcp` | Image repo |
| `image.tag` | `""` | Defaults to chart `appVersion` |
| `server.transport` | `http` | Keep `http` for Kubernetes |
| `server.stateless` | `true` | Stateless HTTP — required for safe scaling |
| `server.toolFilter` | `codemode` | `POSTGRES_TOOL_FILTER` value |
| `server.trustProxy` | `true` | Trust `X-Forwarded-For` (behind Ingress) |
| `existingSecret.name` | `""` | **Pre-existing** Secret injected via `envFrom` |
| `database.host` / `.port` / `.user` / `.name` | `""` | Non-secret connection vars |
| `database.ssl` | `false` | Pass `--ssl` to the DB connection |
| `oauth.enabled` | `false` | Enable OAuth 2.1 |
| `oauth.issuer` / `.audience` / `.jwksUri` / `.clockTolerance` | `""` | OAuth params |
| `audit.enabled` | `false` | JSONL audit trail (`logPath: stderr` for container logs) |
| `podDisruptionBudget.enabled` | `false` | Enable PDB |
| `podDisruptionBudget.minAvailable` | `1` | (or set `maxUnavailable`) |
| `autoscaling.enabled` | `false` | Enable HPA (`autoscaling/v2`) |
| `autoscaling.minReplicas` / `.maxReplicas` | `2` / `5` | HPA bounds |
| `autoscaling.targetCPUUtilizationPercentage` | `80` | CPU target |
| `service.type` / `.port` | `ClusterIP` / `80` | Service |
| `ingress.enabled` | `false` | Ingress for `/mcp` |
| `resources` | 100m/256Mi → 1/512Mi | Requests/limits |
| `extraEnv` / `extraEnvFrom` | `[]` | Additional env / env sources |

Run `helm show values ./helm/postgres-mcp` for the full, commented list.

## Security notes

- With neither `oauth.enabled` nor a bearer token, **all clients have full access**.
  Always configure auth before exposing the server publicly.
- The chart renders only **non-secret** values as plain env vars. Put
  `PGPASSWORD` / `POSTGRES_URL` / `MCP_AUTH_TOKEN` in `existingSecret`.
- `readOnlyRootFilesystem: true` is on by default; an `emptyDir` is mounted at
  `/tmp`. If you enable file-based audit logging, mount a writable volume and point
  `audit.logPath` at it.

## Validate locally

```bash
helm lint ./helm/postgres-mcp
helm lint ./helm/postgres-mcp -f ./helm/postgres-mcp/ci/full-values.yaml
helm template t ./helm/postgres-mcp -f ./helm/postgres-mcp/ci/full-values.yaml
```
