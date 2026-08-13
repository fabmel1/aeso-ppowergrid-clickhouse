CREATE DATABASE IF NOT EXISTS alberta_energy;

USE alberta_energy;

-- Raw append-only telemetry data from AESO grid sensors
CREATE TABLE IF NOT EXISTS grid_telemetry (
    recorded_at DateTime64(3, 'UTC'),
    region_id LowCardinality(String),
    asset_type LowCardinality(String), -- 'WIND', 'SOLAR', 'GAS', 'HYDRO'
    megawatts Float32,
    pool_price_cad Float32,
    grid_frequency_hz Float32 DEFAULT 60.0
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(recorded_at)
ORDER BY (region_id, asset_type, recorded_at);