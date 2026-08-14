USE alberta_energy;

-- 1. Kafka Engine Table (Acts as the stream consumer)
CREATE TABLE IF NOT EXISTS kafka_grid_stream (
    recorded_at String,
    region_id String,
    asset_type String,
    megawatts Float32,
    pool_price_cad Float32
) ENGINE = Kafka
SETTINGS kafka_broker_list = 'redpanda:29092',
         kafka_topic_list = 'aeso-grid-events',
         kafka_group_name = 'clickhouse-aeso-group',
         kafka_format = 'JSONEachRow';

-- 2. Destination Storage Table
CREATE TABLE IF NOT EXISTS raw_kafka_telemetry (
    recorded_at DateTime64(3, 'UTC'),
    region_id LowCardinality(String),
    asset_type LowCardinality(String),
    megawatts Float32,
    pool_price_cad Float32
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(recorded_at)
ORDER BY (region_id, asset_type, recorded_at);

-- 3. Materialized View pushing data continuously from Kafka to Storage
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_kafka_to_raw TO raw_kafka_telemetry AS
SELECT
    parseDateTimeBestEffort(recorded_at) AS recorded_at,
    region_id,
    asset_type,
    megawatts,
    pool_price_cad
FROM kafka_grid_stream;