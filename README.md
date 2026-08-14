Real-Time Alberta Power Grid Analytics (ClickHouse Engine)An end-to-end real-time streaming and telemetry analytics platform built using ClickHouse, Redpanda (Kafka), dbt, and Grafana, simulating real-time sensor feed data from the AESO (Alberta Electric System Operator) grid.This platform demonstrates a Hybrid Data Architecture: leveraging ClickHouse Materialized Views for zero-latency operational monitoring in Grafana alongside dbt for governed batch transformation, data testing, and analytics engineering.🏗️ Architecture┌─────────────────┐      ┌──────────────────┐      ┌───────────────────────┐
│ Python Producer │ ───► │ Redpanda (Kafka) │ ───► │   ClickHouse Engine   │
└─────────────────┘      └──────────────────┘      └───────────┬───────────┘
                                                               │
                                         ┌─────────────────────┴─────────────────────┐
                                         ▼                                           ▼
                            [ Real-Time Operational Path ]            [ Batch Governance Path ]
                                         │                                           │
                             ClickHouse Materialized View                       dbt Core
                                         │                                           │
                                         ▼                                           ▼
                                Grafana Dashboards                       Analytical Gold Layer
                                (5s Auto-Refresh)                           & Quality Tests
🛠️ Architecture & Design DecisionsDatabase Engine: MergeTree() chosen for high-throughput appends, fast primary-key range filtering, and efficient columnar compression (LZ4/ZSTD).Sparse Index Strategy: ORDER BY (region_id, asset_type, recorded_at) aligns low-cardinality metadata first to maximize index skip rates and block-level compression.Real-Time Aggregations: Uses Materialized Views backed by SummingMergeTree() to aggregate data server-side continuously upon ingestion, eliminating runtime aggregation overhead for live dashboard queries.Data Types: Utilized LowCardinality(String) for repeating categories (region_id, asset_type) and Float32 precision to minimize memory footprint and disk IO.Governed Analytics (dbt): Implements dbt incremental models (fct_regional_power_minutely) to enforce data quality assertions (not_null, schema constraints), manage lineage, and maintain production-ready analytics documentation.🛠️ Tech StackStreaming Ingestion: Redpanda (Kafka API-compatible event streaming)Data Engine / Storage: ClickHouse Engine (MergeTree, SummingMergeTree)Real-Time Layer: ClickHouse Materialized ViewsBatch Analytics & Testing: dbt Core (dbt-clickhouse)Visualization: Grafana (ClickHouse Data Source Plugin)Orchestration & Containerization: Docker & Docker ComposeEnvironment / Scripting: Python 3.x & PowerShell📁 Repository Structure├── dbt_aeso/
│   ├── models/
│   │   ├── staging/             # Staging views over raw Kafka telemetry
│   │   └── marts/               # Incremental fact and dimension models
│   ├── dbt_project.yml          # dbt project configuration
│   └── schema.yml               # Source definitions, model documentation, & data tests
├── scripts/
│   ├── 01_raw_tables.sql        # ClickHouse Kafka ingestion engines & DDLs
│   └── 02_materialized_views.sql# ClickHouse Materialized View definitions
├── producer/
│   └── telemetry_producer.py    # Python script generating real-time grid metrics
├── docker-compose.yml           # Redpanda, ClickHouse, and Grafana containers
└── README.md
🚀 Quickstart1. Launch InfrastructureSpin up the ClickHouse, Redpanda, and Grafana containers:docker compose up -d
2. Initialize Database DDLs & Materialized ViewsExecute the ClickHouse initialization scripts:Get-Content scripts\01_raw_tables.sql | docker exec -i local-clickhouse clickhouse-client --password password --multiquery
Get-Content scripts\02_materialized_views.sql | docker exec -i local-clickhouse clickhouse-client --password password --multiquery
3. Start Real-Time Ingestion ProducerRun the Python streaming telemetry generator:python producer/telemetry_producer.py
4. Execute dbt Transformations & Data TestsRun incremental transformations and validate data quality assertions:cd dbt_aeso
dbt run
dbt test
📊 Real-Time Grafana ConfigurationAccess Grafana at http://localhost:3000.Connect the ClickHouse datasource (host: local-clickhouse:8123).Add a time-series panel with the real-time Materialized View query:SELECT
    window_start AS time,
    region_id AS metric,
    avg_megawatts AS value
FROM alberta_energy.mv_regional_power_minutely
WHERE $__timeFilter(window_start)
ORDER BY window_start ASC
Set the dashboard refresh rate to 5s and time range to Last 15 minutes.🧪 Interactive SQL QueriesTo open an interactive ClickHouse terminal and query real-time aggregated metrics:docker exec -it local-clickhouse clickhouse-client --password password
-- Query real-time minute aggregations directly from the Materialized View
SELECT 
    window_start, 
    region_id, 
    avg_megawatts 
FROM alberta_energy.mv_regional_power_minutely 
ORDER BY window_start DESC 
LIMIT 10;
