# Observability Bottleneck Triage — Query planning / locks / metadata contention

Use this when CloudWatch, service dashboards, or DB metrics look mostly healthy but users/jobs experience latency, backlog, or timeout spikes. Inspired by hidden ClickHouse query-planning contention cases.

## Add these checks before declaring infra healthy
- planning wait / compile wait / query planning duration
- metadata lock or catalog lock contention
- schema/table/partition metadata fan-out
- queueing before execution vs time spent scanning/executing
- lock wait by query class, tenant, table, partition, or dashboard
- number of concurrent queries/jobs touching the same metadata path
- recently deployed dashboards, cron jobs, migrations, partition churn, or high-cardinality query generators

## Triage sequence
1. Separate `queued/planning` time from `executing/scanning` time.
2. Compare slow and normal windows for planning duration, lock wait, and metadata fan-out.
3. Check whether I/O, memory, CPU, and scan bytes are normal; if yes, do not stop there.
4. Identify the smallest shared object: table, partition, catalog, query planner, billing/customer dimension, dashboard, or cron.
5. Add one temporary metric or log field that proves/disproves planning/metadata contention.
6. Document the rollback: disable dashboard/cron/query class, reduce concurrency, precompute metadata, or add backoff.

## Output line for monitoring templates
`Normal resource metrics do not rule out bottlenecks: check planning wait, lock contention, metadata contention, and pre-execution queueing before calling DB/CloudWatch healthy.`
