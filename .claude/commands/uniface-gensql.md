---
description: Generate target-DBMS DDL (tables / referential integrity) from the model via /genSql
argument-hint: "<entity.model> <db: ora|mss|...> [createTable|createScript]"
allowed-tools: Read, PowerShell
---

Generate DBMS-specific SQL for a target database — e.g. develop on SQLite, deploy
on Oracle / SQL Server.

Steps:
1. Resolve exe / adm / project (read `usys.ini [install]`).
2. Run (quote spaced paths):
   ```
   & "<root>\common\bin\ide.exe" "/adm=<root>\uniface\adm" /gensql createTable <entity.model> <db>
   ```
   - `db` = 3-letter connector mnemonic (`ORA`, `MSS`, …). **Not** for SEQ/TXT/ODBC.
   - `/meta` → generate the **Repository** tables; `createScript createRI|dropRI|validateRI`
     → referential-integrity scripts.
3. Before generating, ensure the target connector **and** its `USYS$<drv>_PARAMS`
   are declared in `[DRIVER_SETTINGS]` of the assignment.

Output: a `.sql` file (e.g. `ora_sales_createTable.sql`) for the DBA to run on the
target DBMS to build tables / indexes / RI.

$ARGUMENTS = `<entity.model> <db> [facility]`.
