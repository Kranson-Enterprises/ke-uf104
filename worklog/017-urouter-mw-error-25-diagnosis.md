# 017 URD_MW_ERROR -25 — DSP test failed (router/server middleware diagnosis & fix)

**Date:** 2026-06-30
**Sequence:** … → 016 (workspace security review) → **017 (URD_MW_ERROR -25 diagnosis)**.
**Purpose:** First Hello-World DSP test from the IDE failed with
`300 URD_MW_ERROR / Middleware: UV8 / Error# -25`. Diagnose the real cause (the IDE
frame is a downstream symptom) and apply a durable local-dev fix.
Confidence: ✅ verified from the router/server log chain; fix applied to install config.

---

## 1. Symptom (what the IDE showed)

```
300 URD_MW_ERROR
Middleware : UV8
Error#     : -25
Error Text : see UNIFACE message guide
```

Component `HELLO_WORLD` is a **DSP (web)** — `uniface/project/resources/dsp/` exists and
the IDE log shows a clean compile (`errors 0`). So the failure is **runtime, not compile**.

## 2. The 3-tier chain that runs on Test

```
browser → Tomcat:8080 → WRD servlet → urouter:13001 → spawns "wasv" userver → back to router
```

- `urouter` runs as the Windows service **"Rocket Uniface 10 Community Edition URouter"**
  (Automatic, SYSTEM); Tomcat is the **"…Tomcat"** service. Both were up and listening
  (13001, 8080). The front door was open — the break was deeper.

## 3. Root cause (read the server-side logs, not the IDE frame)

The `-25` is the **router giving up**, not the fault. The real fault is one layer down:

- `uniface/log/wasv<pid>.log` — the spawned web server **could not connect back to the
  router**:
  `DNP Logon (TCP:LAPTOP-NMV0UULT.lan+13001|…) failed with status -18, Failed to connect
  to URouter` → `Fatal error: 9024 - Application stopped due to logon error.`
- `uniface/log/urouter<pid>.log` — the router then:
  `Server startup timed out after 64 seconds` → `err=-25: getsrv: handle_wait wait failed`
  → `srvdead: notifying client there is no server`.

So: **server died on DNP logon (-18); router waited 64 s and returned -25 to the client.**

**Why -18:** `urouter.asn` had `$default_net = TCP:+13001|||` — an **empty host**. With no
host, a spawned userver dials the router back via the **machine FQDN
`LAPTOP-NMV0UULT.lan`**. That `.lan` (DHCP search suffix) either doesn't resolve, or
resolves to the LAN IP where **Windows Firewall drops the inbound to `urouter.exe`**.
Loopback is never firewalled and always resolves, so the all-local chain should use it.

## 4. Fix (applied — install config, not the repo)

`C:\ref\common\adm\urouter.asn` line 10:

```
- $default_net = TCP:+13001|||
+ $default_net = TCP:localhost+13001|||
```

- Pins the listen/connect path to `localhost` (127.0.0.1) → bypasses the FQDN-resolution
  **and** firewall failure modes. Correct for an all-on-one-box dev install (Tomcat, IDE,
  userver, router all local; `usys.ini [install] urouter_machine=localhost` already).
- Backup: `C:\ref\common\adm\urouter.asn.bak-20260630` (restore + restart service to revert).
- **Requires service restart** to take effect (elevated):
  `Restart-Service 'Rocket Uniface 10 Community Edition URouter' -Force`
  Verify it then listens on **127.0.0.1:13001** and re-press **Test**.

This is **outside version control by design** (`C:\ref` install dir, not the repo) — nothing
to commit. If a future scenario needs LAN access to the router, revert to the empty-host
form (and open the firewall for `urouter.exe`) rather than keeping localhost.

## 5. Takeaways (for next time / for CI triage)

- **`URD_MW_ERROR -25` is a wait-timeout symptom, not a root cause.** Always open the
  **`wasv*.log` / `userver*.log`** in `uniface/log/` — the server-side log names the real
  fault (here a `-18` DNP logon).
- **Empty-host `$default_net` is fragile on laptops** (changing DNS suffix / firewall).
  Prefer an explicit `localhost` for single-box dev.
- Aligns with the **CLI/build-hygiene** rule (resolve topology/ports from
  `usys.ini [install]`) and **quote-paths** (the asn already quotes spaced `/dir`/`/adm`).
- Ties into the **character/web-endpoint** awareness: this was the **web (DSP)** delivery
  path exercising the full Router→Server tier — the same plumbing a deployed USP/DSP uses.
