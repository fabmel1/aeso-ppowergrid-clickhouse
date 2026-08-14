{{ config(
    materialized='incremental',
    unique_key=['window_start', 'region_id'],
    engine='MergeTree()',
    order_by=['window_start', 'region_id']
) }}

SELECT
    toStartOfMinute(recorded_at) AS window_start,
    region_id,
    avg(megawatts) AS avg_megawatts,
    max(megawatts) AS max_megawatts,
    avg(pool_price_cad) AS avg_price_cad,
    count() AS total_samples
FROM {{ source('alberta_energy', 'raw_kafka_telemetry') }}

{% if is_incremental() %}
    -- Subtracted 5 minutes to handle late-arriving events cleanly
    WHERE recorded_at >= (SELECT max(window_start) - INTERVAL 5 MINUTE FROM {{ this }})
{% endif %}

GROUP BY
    window_start,
    region_id