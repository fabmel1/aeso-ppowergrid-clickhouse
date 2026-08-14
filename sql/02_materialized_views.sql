USE alberta_energy;

-- 1. Target table for 5-minute pre-aggregated regional statistics
CREATE TABLE IF NOT EXISTS hourly_regional_summary (
    window_start DateTime,
    region_id LowCardinality(String),
    avg_mw Float32,
    max_mw Float32,
    avg_price Float32,
    total_records UInt64
) ENGINE = SummingMergeTree()
ORDER BY (region_id, window_start);

-- 2. Materialized View that calculates aggregates automatically on insert
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_hourly_regional_summary
TO hourly_regional_summary AS
SELECT
    toStartOfHour(recorded_at) AS window_start,
    region_id,
    avg(megawatts) AS avg_mw,
    max(megawatts) AS max_mw,
    avg(pool_price_cad) AS avg_price,
    count() AS total_records
FROM grid_telemetry
GROUP BY window_start, region_id;

-- 3. Materialized View for Minutely Regional Power Statistics
CREATE MATERIALIZED VIEW alberta_energy.mv_regional_power_minutely
ENGINE = SummingMergeTree()
PRIMARY KEY (window_start, region_id)
ORDER BY (window_start, region_id)
AS SELECT
    toStartOfMinute(recorded_at) AS window_start,
    region_id,
    avg(megawatts) AS avg_megawatts,
    count() AS total_samples
FROM alberta_energy.raw_kafka_telemetry
GROUP BY window_start, region_id;