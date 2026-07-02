# Plan (DEFERRED): Uniface OpenTelemetry monitoring + simple dashboard (MYPROJECT / ke-uf104)

> **Status:** DEFERRED — saved for later. Pick this up **after** the current WAS WorkArea
> plan is finished. Not yet started; no repo changes made for this effort.
> Authored 2026-07-02.

## Context

**Why:** The project mission (worklog 000/001) includes *monitoring* multiple client-hosted
Uniface apps. Uniface 10.4 gained native **OpenTelemetry ("Observability")** and this
install is patch **10.4.03.042** (feature present since .030) — so we can exercise it now as
a skill-refresh. The user wants to **review/analyze** the capability, **implement** it live
against the running `HELLO_WORLD` DSP, and stand up a **simple dashboard**. There is zero
prior telemetry work in the repo — this is greenfield.

**This plan is sequenced AFTER the current WAS WorkArea plan** (worklog ≤029); it is
independent and does not touch WAS wiring.

**Verified capability envelope (offline Library PDF + this install):**
- Signals: **TRACES** (one span per ProcScript module) + **LOGS** (`putmess`). **No metrics signal.**
- Transport: **OTLP/HTTP only** (`/v1/traces`, `/v1/logs`, port 4318). **No TLS, no gRPC.**
- Config: an **`[OBSERVABILITY]`** section in an assignment (`.asn`) file; disabled by default.
- Emitter for the DSP: the **`wasv` userver** (server role) — confirmed in
  `C:\ref\common\adm\urouter.asn [SERVERS]` (`userver.exe … /asn=wasv.asn`). So config lands
  in **`C:\ref\uniface\adm\wasv.asn`**, not the IDE/client asn.
- **`/nodebug` disables tracing** — observability is a **dev/debug-build** capability; the
  project's production default (`/all /nodebug`) turns it off by design.

**Decisions locked with the user:**
- **Backend = Grafana `otel-lgtm`**, run with **Podman** on a **remote SSH host** on the LAN.
- **Transport = SSH local port-forward** (recommended below) → keeps Uniface endpoints at
  `localhost:4318`, encrypts the otherwise-plaintext OTLP over SSH, and keeps the remote
  host out of VCS.
- **Full live end-to-end** implementation (edit install `wasv.asn`, debuggable rebuild,
  urouter restart, real spans/logs).
- **Deliverable footprint = repo package + a repeatable `/uniface-observability` command.**

---

## Transport design (the remote-Podman-over-SSH shape)

```
[Windows dev box: uniface/userver]  --OTLP/HTTP localhost:4318-->  [ssh -L tunnel]
       |                                                                  |
       +--browser localhost:3000 (Grafana) <---- ssh -L 3000 ------------ |
                                                                          v
                                         [remote LAN host: podman run grafana/otel-lgtm]
                                              :4318 OTLP in  ·  :3000 Grafana UI
```

- **On the remote host** (over SSH): `podman run -d --name lgtm -p 3000:3000 -p 4317:4317 -p 4318:4318 grafana/otel-lgtm`
  (or `podman compose -f compose.yaml up -d`; a Quadlet `.container` unit is a stretch).
- **From the dev box:** `ssh -N -L 4318:localhost:4318 -L 3000:localhost:3000 <user>@<remote-host>`
  → Uniface exports to `localhost:4318` (template default; **no secret host in the asn**),
  Grafana opens at `http://localhost:3000`.
- **Rationale:** Uniface's exporter has **no TLS**; tunneling over SSH gives encryption for
  free, avoids opening 4318/3000 on the LAN firewall, and lets the tracked `observability.asn`
  keep the vendor-default `localhost` endpoints (clean, host-agnostic, secret-free).
- **Documented alternative (no tunnel):** point `TRACE_ENDPOINT`/`LOG_ENDPOINT` directly at
  `http://<remote-host>:4318/...`. Then the LGTM ports must be LAN-exposed and the traffic is
  **plaintext OTLP over the LAN** — the real host/IP must stay OUT of the tracked template
  (use an asn logical resolved per-machine or a gitignored local override).

---

## Arc 1 — Review & analyze  →  `docs/uniface-observability.md`

Author a durable capability analysis (not just prose), source-cited to the offline Library
PDF and this install:
- The signal set (traces + logs, **no metrics**) and its dashboard consequence.
- Transport (OTLP/HTTP only, no TLS/gRPC) → why the SSH tunnel.
- The full `[OBSERVABILITY]` key table: `TRACE`, `LOG`, `SERVICE_NAME`, `SERVICE_ROLE`,
  `TRACE_ENDPOINT`, `LOG_ENDPOINT`, `QUEUE_SIZE`/`BATCH_SIZE`/`SCHEDULE_DELAY`/`FLUSH_TIMEOUT`,
  and enrichment `ADD_PROC_STATUS`/`ADD_PROC_ERROR`/`ADD_PROC_PROFILING`/`ADD_PROC_TRACING`.
- Emitter analysis: client (`uniface`/ide) vs **server (`wasv` userver — the DSP path)**.
- The **`/nodebug` ↔ tracing exclusivity** as a first-class finding.
- **Two live-verify TODOs for Arc 2:** (a) the docs' `ADD_*` **underscore-spelling
  inconsistency** (`ADD_PROC_PROFILING` vs `ADD_PROCPROFILING`) — confirm which the engine
  accepts; (b) that enrichment appears in the debug build and vanishes under `/nodebug`.
- Cross-link `docs/uniface-10-onboarding.md` §3.3 (topology) / §3.4 (logging) and the
  `protect-secrets-and-proprietary` rule (OTLP endpoints/headers are sensitive).

## Arc 2 — Implement (live)

**Config placement — tracked, reproducible, secret-free:**
- Create `monitoring/observability.asn` (VCS-tracked, **secret-free, host-free**):
  `[OBSERVABILITY]` with `TRACE=on`, `LOG=on`, `SERVICE_NAME=MYPROJECT_HELLO_WORLD`
  (SERVICE_ROLE auto-resolves to **server** under userver), endpoints
  `http://localhost:4318/v1/traces` and `/v1/logs` (SSH-tunnel target), plus the `ADD_PROC_*`
  keys (spelling verified live).
- Wire into the install with **one reversible line** appended to `C:\ref\uniface\adm\wasv.asn`:
  `#file <path>\monitoring\observability.asn` — mirroring the existing `ide.asn` `#file`
  pattern. **Back up first** (`wasv.asn.bak-<date>`). Fallback if `#file` rejects an absolute
  path (shipped examples use logicals like `usyscom:`): paste the block inline, keep
  `monitoring/observability.asn` as the canonical tracked copy.
- **Never commit `wasv.asn`** (holds `$server_secret`) — only the secret-free template.

**Resolve the `/nodebug` tension:**
- Recompile **only** `HELLO_WORLD` **debuggable** (omit `/nodebug`) so ProcScript spans
  emit — via `/uniface-compile` overriding its `/nodebug` default; run from the project
  working dir; check exit 0. Overwrites the served `.dsp` in `project\resources\`.
- **Restore** the production `/all /nodebug` build as an explicit final step.

**End-to-end verification sequence (quoted paths throughout):**
1. Remote host: `podman run … grafana/otel-lgtm` (or `podman compose up -d`).
2. Dev box: open the SSH tunnel (`ssh -N -L 4318:… -L 3000:… <user>@<remote>`).
3. Back up + patch `wasv.asn` (add the `#file` include).
4. Debuggable recompile of `HELLO_WORLD`; exit 0.
5. **Restart urouter** so pooled `wasv`/`userver` processes reload the asn (brief HELLO_WORLD
   outage).
6. Exercise the DSP in a browser: `http://localhost:8080/uniface/wrd/HELLO_WORLD` (confirm the
   exact WRD path from the HELLO_WORLD runbook) so `exec`, `preActivate`, `postActivate`,
   `reconnect` fire → one span each.
7. Confirm in Grafana (`http://localhost:3000` → Explore): **Tempo** trace for
   `MYPROJECT_HELLO_WORLD` (span-per-module), **Loki** `putmess` logs, derived RED series.
8. Resolve the two live TODOs (`ADD_*` spelling; enrichment present in debug / absent under
   `/nodebug`).

## Arc 3 — Simple dashboard  →  `monitoring/dashboard.json`

- Do **not** hand-build native metric panels (Uniface feeds none). Use otel-lgtm's Grafana:
  - **Traces** (Tempo) filtered to `service.name = MYPROJECT_HELLO_WORLD`.
  - **Logs** (Loki) `putmess` stream, trace-id-correlated.
  - **Derived RED panels** from Tempo's **span-metrics connector** (duration/rate/error) — this
    is how we get latency/throughput despite no metrics signal; call it out as *derived*.
- Provision as a **single, one-screen Grafana dashboard JSON** checked into `monitoring/`.
  Run layout/color/KPI choices through the **`dataviz`** skill (traces-over-time, error-rate
  tile, p95 latency tile).

---

## Deliverables (tracked, in `monitoring/` unless noted)

- **`monitoring/compose.yaml`** — otel-lgtm, ports 3000/4317/4318, **no secrets**;
  `podman compose`-compatible (also works with docker compose).
- **`monitoring/observability.asn`** — the `[OBSERVABILITY]` template; **localhost endpoints
  only, no host, no headers, no secrets**.
- **`monitoring/dashboard.json`** — the Grafana dashboard (Arc 3).
- **`monitoring/README.md`** — remote-Podman + SSH-tunnel runbook; apply/revert steps.
- **`docs/uniface-observability.md`** — the Arc 1 capability analysis + runbook + live findings.
- **`/uniface-observability`** command/skill (`.claude/commands/` or `.claude/skills/`):
  - **enable:** ensure remote `podman up` + SSH tunnel → back up `wasv.asn` → add include →
    debuggable compile of `HELLO_WORLD` → restart urouter.
  - **disable:** revert asn (restore `.bak` / drop the `#file` line) → recompile `/all /nodebug`
    → (optional) drop tunnel + remote `podman down`.
  - **status:** report asn state, build mode, tunnel/endpoint reachability.
- **`worklog/030`** — session narrative via `/worklog-new` (established format).
- **Rules:** no new standalone rule — add one line each to `protect-secrets-and-proprietary`
  (OTLP endpoints/host are sensitive; keep out of the tracked template) and
  `uniface-cli-and-build-hygiene` (`/nodebug` disables tracing) to avoid rule sprawl.

## Reused tooling / files
- `/uniface-asn-review` (vet the asn change: dev/prod + secrets), `/uniface-compile`
  (debuggable + restore), `/uniface-cli` + `/uniface-launch-ide` (invoke urouter/ports from
  `usys.ini [install]`), `/worklog-new`, the `dataviz` skill.
- `uniface/project/ide.asn` — precedent for the `#file`-include + `.bak` + gitignore pattern.
- `docs/uniface-10-onboarding.md` §3.3–3.4 — topology/logging the new doc builds on.
- Offline Library PDF (`reference-uniface-library-pdf-offline`) — authoritative verification.

## Critical files to modify / create
- **Create:** `monitoring/compose.yaml`, `monitoring/observability.asn`,
  `monitoring/dashboard.json`, `monitoring/README.md`, `docs/uniface-observability.md`,
  `.claude/commands/uniface-observability.md` (or skill), `worklog/030-*.md`.
- **Edit (install, not VCS, backed up):** `C:\ref\uniface\adm\wasv.asn` (add `#file` include).
- **Recompile:** `HELLO_WORLD` (debuggable for demo → restore `/nodebug`).

## Sequencing
Confirm remote host reachable → write `docs/uniface-observability.md` (Arc 1) → create
`monitoring/` (compose + asn template) → remote `podman up` + SSH tunnel → back up + patch
`wasv.asn` → debuggable recompile → restart urouter → exercise DSP → verify in Grafana →
resolve `ADD_*`/`/nodebug` TODOs → build `dashboard.json` → author `/uniface-observability`
command → restore `/nodebug` + revert asn (or leave enabled per preference) → `worklog/030` →
commit **tracked deliverables only** (scan `git diff`; never `wasv.asn`).

## Risks & mitigations
- **Editing install `wasv.asn`** (has `$server_secret`): back up; single reversible `#file`
  line; commit only the secret-free template.
- **urouter restart** bounces the live app: expect a brief HELLO_WORLD outage.
- **Debuggable-build hygiene:** easy to leave `HELLO_WORLD` non-`/nodebug` — the enable/disable
  command makes restore a first-class step.
- **Plaintext OTLP / secret host:** mitigated by the SSH tunnel (encrypted, localhost
  endpoints); if the direct-LAN alternative is used, keep the host out of VCS and note the
  plaintext exposure.
- **Podman vs Docker deltas:** rootless port binding, `podman compose` provider availability —
  README documents the `podman run` fallback if compose isn't wired.
- **`ADD_*` spelling ambiguity** and **no-metrics expectation gap** (RED panels are
  span-*derived*): both verified/stated live, not assumed.

## Verification (done-when)
A browser hit to `HELLO_WORLD` produces, in Grafana at `localhost:3000` (through the tunnel):
a **Tempo trace** named `MYPROJECT_HELLO_WORLD` with one span per exercised ProcScript module,
the corresponding **`putmess` logs in Loki**, and the **derived RED panels** populating on the
`monitoring/dashboard.json` board — with the `/nodebug` build confirmed to suppress the
enrichment. `/uniface-observability disable` cleanly restores the production `/nodebug` build
and reverts `wasv.asn`.
