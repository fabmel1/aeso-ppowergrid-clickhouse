# Real-Time Alberta Power Grid Analytics (ClickHouse Engine)

An OLAP real-time streaming and telemetry analytics platform built using **ClickHouse**, simulating sensor feed data from the **AESO (Alberta Electric System Operator)** grid.

## Architecture & Design Decisions

- **Database Engine:** `MergeTree()` chosen for high-throughput appends and columnar compression.
- **Sparse Index Strategy:** `ORDER BY (region_id, asset_type, recorded_at)` aligns low-cardinality metadata first to maximize index skip rates and block-level compression.
- **Real-Time Aggregations:** Uses `Materialized Views` back-ended by `SummingMergeTree()` to eliminate runtime aggregation overhead for hourly monitoring queries.
- **Data Types:** Utilized `LowCardinality(String)` for repeating categories (`region_id`, `asset_type`) and `Float32` precision to optimize memory footprint and disk IO.

## Quickstart

1. Spin up the ClickHouse container:
   ```bash
   docker-compose -f docker/docker-compose.yml up -d

## Tests

   ```bash
   docker exec -it local-clickhouse clickhouse-client --password password

      ```sql
   SELECT region_id, avg(avg_mw) AS overall_avg_mw
    FROM alberta_energy.hourly_regional_summary
    GROUP BY region_id;


